import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/summary/period_summary.dart';

void main() {
  final DateTime anchor = DateTime(2026, 6, 6); // 土曜

  // 各日に決定的な値を返すフェイク reader。
  DaySummary reader(DateTime d) => DaySummary(
    date: d,
    sleep: Duration(minutes: 420 + d.day), // 7時間+日
    steps: 8000 + d.day * 10,
    hrAvg: 60 + d.day % 5,
    hrResting: 50 + d.day % 3,
  );

  group('#67 PeriodSummary (日)', () {
    test('日: KPI は当日値、バーは過去7日で最終が今日強調', () {
      final s = PeriodSummary.build(
        period: SummaryPeriod.day,
        anchor: anchor,
        read: reader,
        now: anchor, // anchor が実際の今日
      );

      expect(s.avgSleep, const Duration(minutes: 426)); // 420 + 6
      expect(s.avgSteps, 8060);
      expect(s.bars.length, 7);
      expect(s.bars.last.label, '今日');
      expect(s.bars.last.highlighted, isTrue);
      expect(s.sleepDeltaMinutes, 1); // 当日426 - 前日425
    });

    test('日: 過去日を閲覧中は最終バーを「今日」にしない (P1)', () {
      final s = PeriodSummary.build(
        period: SummaryPeriod.day,
        anchor: DateTime(2026, 6, 1),
        read: reader,
        now: anchor, // 今日は 6/6
      );
      expect(s.bars.last.highlighted, isTrue);
      expect(s.bars.last.label, isNot('今日'));
    });
  });

  group('#67 PeriodSummary (週)', () {
    test('週: 月〜日の7バー、KPIは週平均', () {
      final s = PeriodSummary.build(
        period: SummaryPeriod.week,
        anchor: anchor,
        read: reader,
      );
      expect(s.bars.length, 7);
      expect(s.bars.first.label, '月');
      expect(s.bars.last.label, '日');
      expect(s.avgSleep.inMinutes, greaterThan(0));
      expect(s.avgSteps, greaterThan(0));
    });
  });

  group('#67 PeriodSummary (月)', () {
    test('月(6月,月曜始まり): 5週ロールアップ', () {
      final s = PeriodSummary.build(
        period: SummaryPeriod.month,
        anchor: anchor,
        read: reader,
      );
      expect(s.bars.length, 5);
      expect(s.bars.first.label, '1週');
      expect(s.bars.last.label, '5週');
    });

    test('月(5月,金曜始まり): 暦週境界に整列し1週目は部分週 (P1)', () {
      // 各日 steps=1 とし、1週目の合計で日数を確認する。
      DaySummary one(DateTime d) =>
          DaySummary(date: d, sleep: const Duration(minutes: 60), steps: 1);
      final s = PeriodSummary.build(
        period: SummaryPeriod.month,
        anchor: DateTime(2026, 5, 15),
        read: one,
      );
      // 2026-05-01 は金曜 → 1週目は 5/1〜5/3 (金土日) の 3 日。
      expect(s.bars.first.steps, 3);
    });
  });

  group('#67 前期間比 (欠損時は null)', () {
    test('全日空なら平均0・心拍null・差分null', () {
      final s = PeriodSummary.build(
        period: SummaryPeriod.week,
        anchor: anchor,
        read: DaySummary.empty,
      );
      expect(s.avgSleep, Duration.zero);
      expect(s.avgSteps, 0);
      expect(s.avgHr, isNull);
      expect(s.restingHr, isNull);
      expect(s.sleepDeltaMinutes, isNull);
      expect(s.stepsDeltaPercent, isNull);
      expect(s.hrDelta, isNull);
    });

    test('前期間にデータが無ければ差分は null (偽の比較を作らない) (P1)', () {
      // 6月のみデータあり、前週(5月末)は空。
      DaySummary juneOnly(DateTime d) =>
          d.month == 6 ? reader(d) : DaySummary.empty(d);
      final s = PeriodSummary.build(
        period: SummaryPeriod.week,
        anchor: anchor, // 週=6/1〜6/7、前週=5/25〜5/31
        read: juneOnly,
      );
      expect(s.avgSleep.inMinutes, greaterThan(0)); // 当週は値あり
      expect(s.sleepDeltaMinutes, isNull);
      expect(s.stepsDeltaPercent, isNull);
      expect(s.hrDelta, isNull);
    });
  });
}
