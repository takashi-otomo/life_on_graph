import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

/// Health Connect の導入状態 (#42)。
///
/// 解決前 (loading) は「利用可能」とみなしてローカルファースト描画をブロック
/// しない。`false` のときのみ未導入導線を表示する。
final healthConnectAvailableProvider = FutureProvider<bool>((ref) async {
  return ref.watch(healthSyncRepositoryProvider).isHealthConnectAvailable();
});
