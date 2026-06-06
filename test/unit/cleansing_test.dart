import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/core/app_constants.dart';
import 'package:life_on_graph/models/sleep_segment.dart';
import 'package:life_on_graph/repositories/cleansing.dart';

/// テスト基準日 (正午〜翌正午枠の起点)。
final DateTime _noon = DateTime(2026, 6, 5, 12);

SleepSegment seg(
  int startMin,
  int endMin, {
  String stage = 'light',
  String source = 'com.sec.android.app.shealth',
}) => SleepSegment(
  startTime: _noon.add(Duration(minutes: startMin)),
  endTime: _noon.add(Duration(minutes: endMin)),
  stageType: stage,
  sourcePackage: source,
);

void main() {
  const String shealth = 'com.sec.android.app.shealth'; // 上位
  const String fitbit = 'com.fitbit.FitbitMobile'; // 下位
  const String unknown = 'com.unknown.app';

  group('T-401 allocateBySourcePriority', () {
    test('同一時間帯に複数ソースがある場合、優先ソースのみ残る', () {
      final result = allocateBySourcePriority([
        seg(0, 60, source: shealth),
        seg(0, 60, source: fitbit),
      ]);
      expect(result.length, 1);
      expect(result.single.sourcePackage, shealth);
    });

    test('信頼リストに含まれないソースは、信頼ソースが存在すれば除外される', () {
      final result = allocateBySourcePriority([
        seg(0, 60, source: shealth),
        seg(60, 120, source: unknown),
      ]);
      expect(result.map((s) => s.sourcePackage).toSet(), {shealth});
    });

    test('単一ソースのみの場合は何も除外されない', () {
      final input = [seg(0, 60, source: fitbit), seg(60, 120, source: fitbit)];
      expect(allocateBySourcePriority(input).length, 2);
    });

    test('信頼外ソースしか無い場合は唯一のソースを採用する (フェイルオープン)', () {
      final input = [
        seg(0, 60, source: unknown),
        seg(60, 120, source: unknown),
      ];
      expect(allocateBySourcePriority(input).length, 2);
    });

    test('同一入力に対し決定的な出力を返す', () {
      final input = [seg(0, 60, source: fitbit), seg(0, 60, source: shealth)];
      expect(allocateBySourcePriority(input), allocateBySourcePriority(input));
    });
  });

  group('T-402 clipSegmentsToDay', () {
    final DateTime start = _noon;
    final DateTime end = _noon.add(const Duration(days: 1));

    test('枠を前方にまたぐセグメントが start でクリップされる (ミリ秒精度)', () {
      final before = SleepSegment(
        startTime: _noon.subtract(const Duration(minutes: 30, milliseconds: 0)),
        endTime: _noon.add(const Duration(minutes: 30)),
        stageType: 'deep',
        sourcePackage: shealth,
      );
      final result = clipSegmentsToDay([before], start, end);
      expect(result.single.startTime, start);
      expect(result.single.endTime, _noon.add(const Duration(minutes: 30)));
    });

    test('枠を後方にまたぐセグメントが end でクリップされる', () {
      final crossing = SleepSegment(
        startTime: end.subtract(const Duration(minutes: 20)),
        endTime: end.add(const Duration(minutes: 40)),
        stageType: 'rem',
        sourcePackage: shealth,
      );
      final result = clipSegmentsToDay([crossing], start, end);
      expect(result.single.endTime, end);
    });

    test('枠と重ならないセグメントは除外される', () {
      final outside = SleepSegment(
        startTime: end.add(const Duration(hours: 1)),
        endTime: end.add(const Duration(hours: 2)),
        stageType: 'light',
        sourcePackage: shealth,
      );
      expect(clipSegmentsToDay([outside], start, end), isEmpty);
    });

    test('枠内に完全に収まるセグメントは変更されない', () {
      final inside = seg(60, 120, stage: 'deep');
      final result = clipSegmentsToDay([inside], start, end);
      expect(result.single, inside);
    });

    test('元の入力セグメントは破壊的変更を受けない', () {
      final original = SleepSegment(
        startTime: _noon.subtract(const Duration(minutes: 30)),
        endTime: _noon.add(const Duration(minutes: 30)),
        stageType: 'deep',
        sourcePackage: shealth,
      );
      final snapshotStart = original.startTime;
      clipSegmentsToDay([original], start, end);
      expect(original.startTime, snapshotStart);
    });
  });

  group('T-403 mergeOverlaps', () {
    test('部分重複は長いセグメントが優先され重複が解消される', () {
      // long: 0-60 (deep), short: 40-70 (rem) → 重複 40-60 は long が優先
      final result = mergeOverlaps([
        seg(0, 60, stage: 'deep'),
        seg(40, 70, stage: 'rem'),
      ]);
      // 時間順・重複なし
      for (int i = 0; i < result.length - 1; i++) {
        expect(
          result[i].endTime.isAfter(result[i + 1].startTime),
          isFalse,
          reason: '出力に重複がある',
        );
      }
      final deep = result.firstWhere((s) => s.stageType == 'deep');
      expect(deep.startTime, _noon);
      expect(deep.endTime, _noon.add(const Duration(minutes: 60)));
      // 短い rem は重ならない 60-70 のみ残る
      final rem = result.firstWhere((s) => s.stageType == 'rem');
      expect(rem.startTime, _noon.add(const Duration(minutes: 60)));
      expect(rem.endTime, _noon.add(const Duration(minutes: 70)));
    });

    test('短い区間が長い区間に完全包含される場合は除外される', () {
      final result = mergeOverlaps([
        seg(0, 120, stage: 'deep'),
        seg(30, 60, stage: 'rem'),
      ]);
      expect(result.length, 1);
      expect(result.single.stageType, 'deep');
    });

    test('重複のない入力は順序整列のみで返る', () {
      final result = mergeOverlaps([
        seg(60, 90, stage: 'rem'),
        seg(0, 30, stage: 'deep'),
      ]);
      expect(result.map((s) => s.stageType).toList(), ['deep', 'rem']);
      expect(result.length, 2);
    });

    test('出力セグメント間に時間的重複が存在しない', () {
      final result = mergeOverlaps([
        seg(0, 50, stage: 'deep'),
        seg(30, 80, stage: 'light'),
        seg(70, 90, stage: 'rem'),
      ]);
      for (int i = 0; i < result.length - 1; i++) {
        expect(result[i].endTime.isAfter(result[i + 1].startTime), isFalse);
      }
    });
  });

  group('T-404 mergeAdjacentSameStage', () {
    test('同一ステージでギャップ30秒未満の隣接区間が結合される', () {
      final a = SleepSegment(
        startTime: _noon,
        endTime: _noon.add(const Duration(minutes: 10)),
        stageType: 'deep',
        sourcePackage: shealth,
      );
      final b = SleepSegment(
        startTime: _noon.add(const Duration(minutes: 10, seconds: 29)),
        endTime: _noon.add(const Duration(minutes: 20)),
        stageType: 'deep',
        sourcePackage: shealth,
      );
      final result = mergeAdjacentSameStage([a, b]);
      expect(result.length, 1);
      expect(result.single.startTime, a.startTime);
      expect(result.single.endTime, b.endTime);
    });

    test('ギャップが tolerance 以上の場合は結合されない', () {
      final a = SleepSegment(
        startTime: _noon,
        endTime: _noon.add(const Duration(minutes: 10)),
        stageType: 'deep',
        sourcePackage: shealth,
      );
      final b = SleepSegment(
        startTime: _noon.add(const Duration(minutes: 10, seconds: 30)),
        endTime: _noon.add(const Duration(minutes: 20)),
        stageType: 'deep',
        sourcePackage: shealth,
      );
      // 境界 30 秒ちょうど → 結合しない
      expect(mergeAdjacentSameStage([a, b]).length, 2);
    });

    test('ステージが異なる隣接区間は結合されない', () {
      final result = mergeAdjacentSameStage([
        seg(0, 10, stage: 'deep'),
        seg(10, 20, stage: 'rem'),
      ]);
      expect(result.length, 2);
    });

    test('結合後の start/end が前後区間を正しく包含する', () {
      final result = mergeAdjacentSameStage([
        seg(0, 10, stage: 'light'),
        seg(10, 25, stage: 'light'),
      ]);
      expect(result.single.startTime, _noon);
      expect(result.single.endTime, _noon.add(const Duration(minutes: 25)));
    });

    test('tolerance を引数で変更でき、既定値が 30 秒である', () {
      expect(AppConstants.adjacentMergeTolerance, const Duration(seconds: 30));
      final a = seg(0, 10, stage: 'deep');
      final b = SleepSegment(
        startTime: _noon.add(const Duration(minutes: 11)),
        endTime: _noon.add(const Duration(minutes: 20)),
        stageType: 'deep',
        sourcePackage: shealth,
      );
      // 既定では結合しない (ギャップ60秒)
      expect(mergeAdjacentSameStage([a, b]).length, 2);
      // tolerance を 2 分に広げると結合する
      expect(
        mergeAdjacentSameStage([a, b], tolerance: const Duration(minutes: 2)),
        hasLength(1),
      );
    });
  });

  group('T-405 パイプライン一括 (①→②→③→④)', () {
    final DateTime start = _noon;
    final DateTime end = _noon.add(const Duration(days: 1));

    test('ソース選別→境界クリップ→重複解消→隣接結合が順に適用される', () {
      final segments = <SleepSegment>[
        // 信頼上位 shealth: 枠を前方にまたぐ deep (-30〜+40分)
        SleepSegment(
          startTime: _noon.subtract(const Duration(minutes: 30)),
          endTime: _noon.add(const Duration(minutes: 40)),
          stageType: 'deep',
          sourcePackage: shealth,
        ),
        // shealth: 隣接 deep (+40分〜+50分, ギャップ0) → 結合対象
        seg(40, 50, stage: 'deep', source: shealth),
        // 低優先 fitbit の重複データ → 第1段で除外される
        seg(0, 120, stage: 'rem', source: fitbit),
      ];

      final result = runSleepCleansingPipeline(
        segments,
        start: start,
        end: end,
      );

      // fitbit は除外され shealth のみ。境界クリップで開始は正午。隣接 deep は結合。
      expect(result.every((s) => s.sourcePackage == shealth), isTrue);
      expect(result.length, 1);
      expect(result.single.stageType, 'deep');
      expect(result.single.startTime, start); // 前方クリップ
      expect(result.single.endTime, _noon.add(const Duration(minutes: 50)));
    });

    test('外部 I/O 非依存で決定的に再現する', () {
      final segments = [
        seg(0, 60, stage: 'deep', source: shealth),
        seg(50, 90, stage: 'rem', source: fitbit),
      ];
      final a = runSleepCleansingPipeline(segments, start: start, end: end);
      final b = runSleepCleansingPipeline(segments, start: start, end: end);
      expect(a, b);
    });
  });
}
