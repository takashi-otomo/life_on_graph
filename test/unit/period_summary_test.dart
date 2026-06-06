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
      );

      expect(s.avgSleep, const Duration(minutes: 426)); // 420 + 6
      expect(s.avgSteps, 8060);
      expect(s.bars.length, 7);
      expect(s.bars.last.label, '今日');
      expect(s.bars.last.highlighted, isTrue);
      // 前日比 (当日426 - 前日425 = +1分)
      expect(s.sleepDeltaMinutes, 1);
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
      // 週平均睡眠 > 0、歩数平均 > 0。
      expect(s.avgSleep.inMinutes, greaterThan(0));
      expect(s.avgSteps, greaterThan(0));
    });
  });

  group('#67 PeriodSummary (月)', () {
    test('月: 週次ロールアップのバー (5本前後)、KPIは月平均', () {
      final s = PeriodSummary.build(
        period: SummaryPeriod.month,
        anchor: anchor,
        read: reader,
      );
      // 6月=30日 → 5週 (1〜7,8〜14,15〜21,22〜28,29〜30)
      expect(s.bars.length, 5);
      expect(s.bars.first.label, '1週');
      expect(s.bars.last.label, '5週');
      expect(s.avgSteps, greaterThan(0));
    });
  });

  group('#67 空データ', () {
    test('全日空なら平均0・心拍null', () {
      final s = PeriodSummary.build(
        period: SummaryPeriod.week,
        anchor: anchor,
        read: DaySummary.empty,
      );
      expect(s.avgSleep, Duration.zero);
      expect(s.avgSteps, 0);
      expect(s.avgHr, isNull);
      expect(s.restingHr, isNull);
    });
  });
}
