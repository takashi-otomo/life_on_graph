import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../models/sleep_segment.dart';
import '../../providers/data_providers.dart';
import '../../providers/selected_date_provider.dart';
import '../../providers/sync_notifier.dart';
import '../sleep/sleep_summary.dart';
import '../sleep/widgets/date_nav_header.dart';
import '../sleep/widgets/sleep_stage_timeline.dart';
import '../sleep/widgets/sleep_summary_card.dart';

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
    final SyncState sync = ref.watch(syncNotifierProvider);
    final SleepSummary summary = SleepSummary.fromSegments(segments);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: <Widget>[
          const SafeArea(bottom: false, child: SizedBox.shrink()),
          if (sync is SyncInProgress)
            const LinearProgressIndicator(minHeight: 3),
          const DateNavHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
              children: <Widget>[
                if (sync is SyncError || sync is SyncPartial)
                  const _SyncErrorBanner(),
                SleepSummaryCard(summary: summary),
                const SizedBox(height: 16),
                SleepStageTimeline(segments: segments),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 同期エラー・部分失敗時のフォールバック表示 (設計doc 12 章)。
class _SyncErrorBanner extends StatelessWidget {
  const _SyncErrorBanner();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Card(
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: <Widget>[
              Icon(Icons.error_outline),
              SizedBox(width: 12),
              Expanded(child: Text('同期に失敗しました。表示中のデータはローカル保存分です。')),
            ],
          ),
        ),
      ),
    );
  }
}
