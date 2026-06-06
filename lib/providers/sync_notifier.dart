import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/health_sync_repository.dart';
import 'repository_providers.dart';

/// 健康データ READ 権限が許可されなかったことを表す例外。
class SyncPermissionDeniedException implements Exception {
  const SyncPermissionDeniedException();

  @override
  String toString() => '健康データの READ 権限が許可されていません';
}

/// 差分同期の進行状態 (T-502)。
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

/// 全種別の同期成功。結果 [outcome] を保持する。
class SyncDone extends SyncState {
  const SyncDone(this.outcome);

  final SyncOutcome outcome;
}

/// 一部種別の同期失敗 (設計doc 12 章)。成功分は保存済みだが失敗要因を保持する。
///
/// `last_sync_time` は前進していないため次回同期で再取得される。UI はフォールバック
/// 表示へ分岐し、成功扱いで古いデータを見せない (P1-a)。
class SyncPartial extends SyncState {
  const SyncPartial(this.outcome);

  final SyncOutcome outcome;

  /// 失敗した種別キー集合 (`'sleep'` / `'steps'` / `'heart_rate'`)。
  Set<String> get failedTypes => outcome.failedTypes;
}

/// 同期失敗 (例外・権限拒否など)。要因 [error] を保持する。
class SyncError extends SyncState {
  const SyncError(this.error);

  final Object error;
}

/// 同期完了世代カウンタ (T-503 再評価トリガ)。
///
/// 同期が **終了した時のみ** インクリメントされる。派生プロバイダはこれを watch する
/// ことで、syncing 開始時の不要なローカル再走査を避ける (P1-c)。
class DataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

/// 同期完了世代プロバイダ。
final dataRevisionProvider = NotifierProvider<DataRevision, int>(
  DataRevision.new,
);

/// 同期を駆動し状態遷移を公開する [Notifier] (T-502)。
class SyncNotifier extends Notifier<SyncState> {
  @override
  SyncState build() => const SyncIdle();

  /// 権限確立 → 差分同期を実行する (T-502 / T-504)。
  ///
  /// 起動時・手動同期のいずれもこの単一経路を通る。`configure` → `requestPermissions`
  /// → `ensureHistoryPermission` を前置し (P1-b)、その後 `sync` を実行する。結果は
  /// 全成功で [SyncDone]、一部失敗で [SyncPartial]、例外・権限拒否で [SyncError]。
  /// 終了時に [dataRevisionProvider] をインクリメントし派生プロバイダを再評価させる。
  Future<void> sync({bool force = false}) async {
    state = const SyncInProgress();
    final HealthSyncRepository repo = ref.read(healthSyncRepositoryProvider);
    try {
      await repo.configure();
      final bool granted = await repo.requestPermissions();
      if (!granted) {
        state = const SyncError(SyncPermissionDeniedException());
        return;
      }
      await repo.ensureHistoryPermission();
      final SyncOutcome outcome = await repo.sync(force: force);
      state = outcome.isFullSuccess ? SyncDone(outcome) : SyncPartial(outcome);
    } catch (e) {
      // ヘルスコネクト未導入・クエリ制限等 (設計doc 12 章) は捕捉し次回同期へ委譲。
      state = SyncError(e);
    } finally {
      // 同期完了 (成功/部分/失敗) 後に一度だけ再評価させる。
      ref.read(dataRevisionProvider.notifier).bump();
    }
  }
}

/// 同期状態プロバイダ。UI がこれを `watch` してフォールバック分岐する。
final syncNotifierProvider = NotifierProvider<SyncNotifier, SyncState>(
  SyncNotifier.new,
);
