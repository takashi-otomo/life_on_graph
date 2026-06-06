import '../core/app_constants.dart';
import '../models/sleep_segment.dart';

/// 睡眠セグメントのクレンジングパイプライン (純粋関数群, 設計doc 9 章)。
///
/// 読み出し時に以下の順で適用する:
/// 1. [allocateBySourcePriority] — ソース優先順位で重複区間のみ解決
/// 2. [clipSegmentsToDay] — 表示枠への境界クリッピング
/// 3. [mergeOverlaps] — オーバーラップ解消 (長いセグメント優先)
/// 4. [mergeAdjacentSameStage] — 隣接同一ステージ結合
///
/// すべて外部 I/O を持たず、同一入力に対し決定的な出力を返す (TDD 容易性)。

/// 第1段: ソース優先順位によるアロケーション (T-401)。
///
/// ソース衝突は **同一時間帯のみ** で解決する。信頼ソースが 1 つでも存在する場合は
/// 信頼外ソースを除外し (設計doc 9 章 / DoD)、残った信頼ソース間では重複した区間に
/// ついてのみ上位ソースを優先する。非重複の下位ソース区間は保持し、データ消失を防ぐ。
/// 信頼外ソースしか無い場合は全件を採用し (フェイルオープン)、重複区間のみ名前昇順で
/// 決定的に解決する。同一ソース内の重複は本段では解消せず第3段 [mergeOverlaps] に委ねる。
List<SleepSegment> allocateBySourcePriority(
  List<SleepSegment> segments, {
  List<String> trustedSources = AppConstants.trustedSleepSources,
}) {
  if (segments.isEmpty) return const <SleepSegment>[];

  int rank(String src) {
    final int i = trustedSources.indexOf(src);
    return i >= 0 ? i : trustedSources.length;
  }

  // 信頼ソースが存在すれば信頼外を除外。無ければ全件採用 (フェイルオープン)。
  final bool hasTrusted = segments.any(
    (s) => trustedSources.contains(s.sourcePackage),
  );
  final List<SleepSegment> candidates = hasTrusted
      ? segments.where((s) => trustedSources.contains(s.sourcePackage)).toList()
      : List<SleepSegment>.of(segments);

  // ソース単位に束ね、優先順位 (rank → 名前昇順) で処理する。
  final Map<String, List<SleepSegment>> bySource =
      <String, List<SleepSegment>>{};
  for (final SleepSegment s in candidates) {
    (bySource[s.sourcePackage] ??= <SleepSegment>[]).add(s);
  }
  final List<String> sources = bySource.keys.toList()
    ..sort((a, b) {
      final int r = rank(a) - rank(b);
      return r != 0 ? r : a.compareTo(b);
    });

  final List<SleepSegment> result = <SleepSegment>[];
  // 上位ソースが確定した区間 (これに重なる下位ソース区間のみを譲らせる)。
  final List<_Interval> claimed = <_Interval>[];
  for (final String src in sources) {
    final List<SleepSegment> kept = <SleepSegment>[];
    for (final SleepSegment seg in bySource[src]!) {
      List<_Interval> pieces = <_Interval>[
        _Interval(seg.startTime, seg.endTime),
      ];
      for (final _Interval c in claimed) {
        pieces = pieces.expand((p) => p.subtract(c.start, c.end)).toList();
      }
      for (final _Interval p in pieces) {
        kept.add(seg.copyWith(startTime: p.start, endTime: p.end));
      }
    }
    result.addAll(kept);
    // 同一ソース内の重複は第3段に委ねるため、ソース処理後に一括で claimed へ加える。
    claimed.addAll(kept.map((s) => _Interval(s.startTime, s.endTime)));
  }

  result.sort((a, b) => a.startTime.compareTo(b.startTime));
  return result;
}

/// 第2段: 表示枠 `[start, end]` への境界クリッピング (T-402)。
///
/// 枠をまたぐセグメントをミリ秒精度で切り出し、枠と重ならない区間・ゼロ幅区間は
/// 除外する。元のセグメントは破壊せず新インスタンスを返す。
List<SleepSegment> clipSegmentsToDay(
  List<SleepSegment> segments,
  DateTime start,
  DateTime end,
) {
  final List<SleepSegment> out = <SleepSegment>[];
  for (final SleepSegment s in segments) {
    final DateTime cs = s.startTime.isBefore(start) ? start : s.startTime;
    final DateTime ce = s.endTime.isAfter(end) ? end : s.endTime;
    // 重なり無し・ゼロ幅 (ce <= cs) は除外。
    if (!ce.isAfter(cs)) continue;
    out.add(s.copyWith(startTime: cs, endTime: ce));
  }
  return out;
}

/// 第3段: オーバーラップ解消 (T-403)。
///
/// 時間的に重複する区間は **長いセグメントを優先** し、重複のない区間列に整形する。
/// 長い区間を先に確定させ、短い区間は未確定の残余 (重ならない部分) のみを保持する。
/// 完全包含される短い区間は除外され、部分重複は重ならない側だけが残る。
List<SleepSegment> mergeOverlaps(List<SleepSegment> segments) {
  if (segments.length <= 1) return List<SleepSegment>.of(segments);

  // 長い順 → 開始昇順 → ソース名昇順で優先度を決定的に確定する。
  final List<SleepSegment> byPriority = <SleepSegment>[...segments]
    ..sort((a, b) {
      final int d = b.duration.compareTo(a.duration);
      if (d != 0) return d;
      final int s = a.startTime.compareTo(b.startTime);
      if (s != 0) return s;
      return a.sourcePackage.compareTo(b.sourcePackage);
    });

  final List<SleepSegment> placed = <SleepSegment>[];
  for (final SleepSegment seg in byPriority) {
    // seg の区間から、既に確定済み (より高優先) の区間を差し引いた残余を求める。
    List<_Interval> pieces = <_Interval>[_Interval(seg.startTime, seg.endTime)];
    for (final SleepSegment p in placed) {
      pieces = pieces
          .expand((piece) => piece.subtract(p.startTime, p.endTime))
          .toList();
    }
    for (final _Interval piece in pieces) {
      placed.add(seg.copyWith(startTime: piece.start, endTime: piece.end));
    }
  }

  placed.sort((a, b) => a.startTime.compareTo(b.startTime));
  return placed;
}

/// 第4段: 隣接同一ステージ結合 (T-404)。
///
/// 開始昇順に走査し、同一 [SleepSegment.stageType] かつギャップ (前区間の終了と
/// 次区間の開始の差) が [tolerance] 未満の隣接区間を 1 区間へ結合する。結合区間の
/// `sourcePackage` は前区間の代表値を採用する。
List<SleepSegment> mergeAdjacentSameStage(
  List<SleepSegment> segments, {
  Duration tolerance = AppConstants.adjacentMergeTolerance,
}) {
  if (segments.isEmpty) return const <SleepSegment>[];

  final List<SleepSegment> sorted = <SleepSegment>[...segments]
    ..sort((a, b) => a.startTime.compareTo(b.startTime));

  final List<SleepSegment> out = <SleepSegment>[];
  SleepSegment current = sorted.first;
  for (final SleepSegment next in sorted.skip(1)) {
    final Duration gap = next.startTime.difference(current.endTime);
    if (next.stageType == current.stageType && gap < tolerance) {
      final DateTime end = next.endTime.isAfter(current.endTime)
          ? next.endTime
          : current.endTime;
      current = current.copyWith(endTime: end);
    } else {
      out.add(current);
      current = next;
    }
  }
  out.add(current);
  return out;
}

/// ①→②→③→④ を順に適用するクレンジングパイプライン一括実行 (設計doc 9 章)。
List<SleepSegment> runSleepCleansingPipeline(
  List<SleepSegment> segments, {
  required DateTime start,
  required DateTime end,
  List<String> trustedSources = AppConstants.trustedSleepSources,
  Duration tolerance = AppConstants.adjacentMergeTolerance,
}) {
  final List<SleepSegment> allocated = allocateBySourcePriority(
    segments,
    trustedSources: trustedSources,
  );
  final List<SleepSegment> clipped = clipSegmentsToDay(allocated, start, end);
  final List<SleepSegment> merged = mergeOverlaps(clipped);
  return mergeAdjacentSameStage(merged, tolerance: tolerance);
}

/// 区間差分計算用の内部ヘルパ。
class _Interval {
  _Interval(this.start, this.end);

  final DateTime start;
  final DateTime end;

  /// 自区間から `[os, oe]` を差し引いた残余 (0〜2 個) を返す。
  List<_Interval> subtract(DateTime os, DateTime oe) {
    // 重なり無し。
    if (!oe.isAfter(start) || !end.isAfter(os)) return <_Interval>[this];
    final List<_Interval> res = <_Interval>[];
    if (start.isBefore(os)) {
      final DateTime e = os.isBefore(end) ? os : end;
      if (e.isAfter(start)) res.add(_Interval(start, e));
    }
    if (oe.isBefore(end)) {
      final DateTime s = oe.isAfter(start) ? oe : start;
      if (end.isAfter(s)) res.add(_Interval(s, end));
    }
    return res;
  }
}
