import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/sleep/sleep_summary.dart';
import '../features/steps/steps_hourly.dart';
import '../features/summary/period_summary.dart';
import '../models/heart_rate_record_model.dart';
import 'repository_providers.dart';
import 'sync_notifier.dart';

/// サマリー画面の対象 (期間 + 基準日)。family 引数。
class SummaryQuery {
  const SummaryQuery(this.period, this.anchor);

  final SummaryPeriod period;
  final DateTime anchor;

  @override
  bool operator ==(Object other) =>
      other is SummaryQuery && other.period == period && other.anchor == anchor;

  @override
  int get hashCode => Object.hash(period, anchor);
}

/// 指定期間の集計サマリー (#67 / #68)。
///
/// ローカル DB から各日の集計を読み、[PeriodSummary] を構築する。同期完了で
/// 再評価される ([dataRevisionProvider] を watch)。
final periodSummaryProvider = Provider.family<PeriodSummary, SummaryQuery>((
  ref,
  q,
) {
  ref.watch(dataRevisionProvider);
  final repo = ref.watch(healthSyncRepositoryProvider);

  DaySummary read(DateTime day) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));
    final Duration sleep = SleepSummary.fromSegments(
      repo.getCleanedSleepSegmentsForDay(day),
    ).total;
    final int steps = StepsHourly.forDay(
      repo.getStepsForRange(start, end),
      day,
    ).total;
    final List<HeartRateRecordModel> hr = repo.getHeartRateForRange(start, end);
    int? hrAvg;
    int? hrResting;
    if (hr.isNotEmpty) {
      hrAvg = (hr.fold(0, (a, p) => a + p.beatsPerMinute) / hr.length).round();
      hrResting = hr
          .map((p) => p.beatsPerMinute)
          .reduce((a, b) => a < b ? a : b);
    }
    return DaySummary(
      date: day,
      sleep: sleep,
      steps: steps,
      hrAvg: hrAvg,
      hrResting: hrResting,
    );
  }

  return PeriodSummary.build(period: q.period, anchor: q.anchor, read: read);
});
