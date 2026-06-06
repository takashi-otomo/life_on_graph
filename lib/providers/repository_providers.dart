import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database_manager.dart';
import '../repositories/health_client.dart';
import '../repositories/health_sync_repository.dart';

/// 初期化済み [DatabaseManager] を供給するプロバイダ (T-501)。
///
/// 未初期化での参照を防ぐため、実体は `main.dart` の `ProviderScope.overrides` で
/// `DatabaseManager.initialize()` 完了後のシングルトンを注入する。テストでは
/// フェイク / 初期化済みインスタンスへ `override` する。
final databaseManagerProvider = Provider<DatabaseManager>((ref) {
  throw UnimplementedError(
    'databaseManagerProvider は ProviderScope.overrides で'
    '初期化済み DatabaseManager を注入してください',
  );
});

/// `health` パッケージをラップする [HealthClient] (テストでフェイク override 可能)。
final healthClientProvider = Provider<HealthClient>(
  (ref) => HealthPackageClient(),
);

/// 同期リポジトリ [HealthSyncRepository] を供給する (T-501)。
///
/// [databaseManagerProvider] と [healthClientProvider] に依存して解決される。
final healthSyncRepositoryProvider = Provider<HealthSyncRepository>((ref) {
  return HealthSyncRepositoryImpl(
    healthClient: ref.watch(healthClientProvider),
    databaseManager: ref.watch(databaseManagerProvider),
  );
});
