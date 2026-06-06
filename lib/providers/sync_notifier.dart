import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/health_sync_repository.dart';
import 'repository_providers.dart';

/// 差分同期の進行状態 (T-502)。idle / syncing / done / error の 4 状態。
sealed class SyncState {
  const SyncState();
}

/// 未同期 (初期状態)。
class SyncIdle extends SyncState {
  const SyncIdle();
}

/// 同期実行中。ローカルファーストのため UI 描画はブロックしない。
class SyncInProgress extends SyncState {
  const SyncInProgress();
}

/// 同期成功。結果 [outcome] を保持し、派生プロバイダの再評価トリガとなる。
class SyncDone extends SyncState {
  const SyncDone(this.outcome);

  final SyncOutcome outcome;
}

/// 同期失敗。要因 [error] を保持し、UI 側でフォールバック分岐に用いる。
class SyncError extends SyncState {
  const SyncError(this.error);

  final Object error;
}

/// 同期を駆動し状態遷移を公開する [Notifier] (T-502)。
class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncIdle();

  /// 差分同期を実行する。syncing → done / error と遷移する。
  ///
  /// 例外 (ヘルスコネクト未導入・権限未許可・クエリ制限等, 設計doc 12 章) は捕捉して
  /// [SyncError] に保持し、リトライ / 次回同期へ委譲する。
  Future<void> sync({bool force = false}) async {
    state = const SyncInProgress();
    try {
      final SyncOutcome outcome = await ref
          .read(healthSyncRepositoryProvider)
          .sync(force: force);
      state = SyncDone(outcome);
    } catch (e) {
      state = SyncError(e);
    }
  }
}

/// 同期状態プロバイダ。UI と派生プロバイダがこれを `watch` する。
final syncNotifierProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);
