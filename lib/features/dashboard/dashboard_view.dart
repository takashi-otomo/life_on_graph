import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../models/heart_rate_record_model.dart';
import '../../models/sleep_segment.dart';
import '../../models/steps_record_model.dart';
import '../../providers/data_providers.dart';
import '../../providers/selected_date_provider.dart';
import '../../providers/sync_notifier.dart';
import '../../widgets/health_status_banner.dart';
import '../heart_rate/widgets/heart_rate_chart.dart';
import '../sleep/sleep_summary.dart';
import '../sleep/widgets/date_nav_header.dart';
import '../sleep/widgets/sleep_stage_timeline.dart';
import '../sleep/widgets/sleep_summary_card.dart';
import '../steps/steps_hourly.dart';
import '../steps/widgets/steps_bar_chart.dart';

/// ホーム (ダッシュボード): 選択日の詳細を表示する (#34 / #35 / #41)。
///
/// 起動直後にローカル DB から即時描画し (ローカルファースト)、背後で差分同期を実行。
/// 同期完了で派生プロバイダが再評価され自動再描画される。歩数・心拍は #36-#38 で追加。
class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncNotifierProvider.notifier).sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime date = ref.watch(selectedDateProvider);
    final List<SleepSegment> segments = ref.watch(sleepSegmentsProvider(date));
    final DateTime dayEnd = date.add(const Duration(days: 1));
    final DateRange dayRange = DateRange(date, dayEnd);
    final List<StepsRecordModel> stepsRecords = ref.watch(
      stepsProvider(dayRange),
    );
    // 心拍は睡眠が暦日をまたぐ (noon〜翌noon) ため、翌正午までを取得して
    // 「睡眠中」フィルタで翌朝分が欠落しないようにする (#38)。
    final List<HeartRateRecordModel> hrPoints = ref.watch(
      heartRateProvider(DateRange(date, date.add(const Duration(hours: 36)))),
    );
    final SyncState sync = ref.watch(syncNotifierProvider);
    final SleepSummary summary = SleepSummary.fromSegments(segments);
    final StepsHourly steps = StepsHourly.forDay(stepsRecords, date);

    // 睡眠中心拍フィルタ (#38) 用の睡眠期間。
    DateTime? sleepStart;
    DateTime? sleepEnd;
    if (segments.isNotEmpty) {
      sleepStart = segments
          .map((s) => s.startTime)
          .reduce((a, b) => a.isBefore(b) ? a : b);
      sleepEnd = segments
          .map((s) => s.endTime)
          .reduce((a, b) => a.isAfter(b) ? a : b);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            if (sync is SyncInProgress)
              const LinearProgressIndicator(minHeight: 3),
            const DateNavHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                children: <Widget>[
                  const HealthStatusBanner(),
                  SleepSummaryCard(summary: summary),
                  const SizedBox(height: 16),
                  SleepStageTimeline(segments: segments),
                  const SizedBox(height: 16),
                  StepsBarChart(steps: steps),
                  const SizedBox(height: 16),
                  HeartRateChart(
                    points: hrPoints,
                    dayStart: date,
                    dayEnd: dayEnd,
                    sleepStart: sleepStart,
                    sleepEnd: sleepEnd,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
