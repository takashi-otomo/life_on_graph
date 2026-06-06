import '../core/app_constants.dart';
import '../models/sleep_segment.dart';

/// 睡眠セグメントのクレンジングパイプライン (純粋関数群, 設計doc 9 章)。
///
/// 読み出し時に以下の順で適用する:
/// 1. [allocateBySourcePriority] — ソース優先順位で単一ソース化
/// 2. [clipSegmentsToDay] — 表示枠への境界クリッピング
/// 3. [mergeOverlaps] — オーバーラップ解消 (長いセグメント優先)
/// 4. [mergeAdjacentSameStage] — 隣接同一ステージ結合
///
/// すべて外部 I/O を持たず、同一入力に対し決定的な出力を返す (TDD 容易性)。

/// 第1段: ソース優先順位によるアロケーション (T-401)。
///
/// [trustedSources] の優先順位 (先頭ほど高優先) に従い、入力に含まれるソースのうち
/// 最上位のもの **だけ** を残して単一ソース化する。リストに無いソースは最下位扱いと
/// し、信頼ソースが 1 つでも存在すればそれらは除外される。逆に信頼外ソースしか無い
/// 場合は、唯一存在するソースを採用してデータ消失を避ける (フェイルオープン)。
List<SleepSegment> allocateBySourcePriority(
  List<SleepSegment> segments, {
  List<String> trustedSources = AppConstants.trustedSleepSources,
}) {
  if (segments.isEmpty) return const <SleepSegment>[];

  int rank(String src) {
    final int i = trustedSources.indexOf(src);
    return i >= 0 ? i : trustedSources.length;
  }

  // 入力に存在するソースのうち最上位を決定的に選ぶ (同順位は名前昇順で一意化)。
  final Set<String> sources = segments.map((s) => s.sourcePackage).toSet();
  final String best = sources.reduce((a, b) {
    final int ra = rank(a);
    final int rb = rank(b);
    if (ra != rb) return ra < rb ? a : b;
    return a.compareTo(b) <= 0 ? a : b;
  });

  return segments.where((s) => s.sourcePackage == best).toList();
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
