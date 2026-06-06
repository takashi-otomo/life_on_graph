import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_constants.dart';
import '../../providers/data_providers.dart';
import '../../providers/sync_notifier.dart';

/// ダッシュボードのトップ画面 (M5 リアクティブ結線, T-504)。
///
/// 起動直後にローカル DB から即時描画し (ローカルファースト)、背後で差分同期を実行。
/// 同期完了 (done) で派生プロバイダが再評価され、購読ウィジェットが自動再描画される。
/// M6 で各可視化チャート (睡眠 / 歩数 / 心拍) に置き換えていく。
class DashboardView extends ConsumerStatefulWidget {
  const DashboardView({super.key});

  @override
  ConsumerState<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends ConsumerState<DashboardView> {
  @override
  void initState() {
    super.initState();
    // 初期描画 (ローカル DB) の後に、背後で差分同期を開始する。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(syncNotifierProvider.notifier).sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime today = DateTime.now();
    final DateTime dateOnly = DateTime(today.year, today.month, today.day);
    final DateRange range = DateRange(
      dateOnly,
      dateOnly.add(const Duration(days: 1)),
    );

    // ローカル DB から待ち無しで取得 (即時描画)。同期完了で自動再評価される。
    final int sleepCount = ref.watch(sleepSegmentsProvider(dateOnly)).length;
    final int stepsTotal = ref
        .watch(stepsProvider(range))
        .fold(0, (sum, r) => sum + r.count);
    final int heartRateCount = ref.watch(heartRateProvider(range)).length;
    final SyncState sync = ref.watch(syncNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        bottom: sync is SyncInProgress
            ? const PreferredSize(
                preferredSize: Size.fromHeight(4),
                child: LinearProgressIndicator(minHeight: 4),
              )
            : null,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: sync is SyncInProgress
            ? null
            : () => ref.read(syncNotifierProvider.notifier).sync(force: true),
        tooltip: '同期',
        child: const Icon(Icons.sync),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (sync is SyncError) _SyncErrorBanner(error: sync.error),
          _MetricTile(
            icon: Icons.bedtime,
            label: '睡眠セグメント',
            value: '$sleepCount 件',
          ),
          _MetricTile(
            icon: Icons.directions_walk,
            label: '歩数',
            value: '$stepsTotal 歩',
          ),
          _MetricTile(
            icon: Icons.favorite,
            label: '心拍サンプル',
            value: '$heartRateCount 件',
          ),
        ],
      ),
    );
  }
}

/// 同期エラー時のフォールバック表示 (未導入 / 未許可 / クエリ制限の導線, 設計doc 12 章)。
class _SyncErrorBanner extends StatelessWidget {
  const _SyncErrorBanner({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Card(
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
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
