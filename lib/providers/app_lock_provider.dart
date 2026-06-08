import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

/// アプリのロック (生体認証) が有効か (#79)。`app_lock_enabled` に永続化。
class AppLockEnabledNotifier extends Notifier<bool> {
  static const String lockKey = 'app_lock_enabled';

  @override
  bool build() {
    try {
      return ref.read(databaseManagerProvider).metadataBox.get(lockKey) == true;
    } catch (_) {
      return false;
    }
  }

  /// ロックの有効/無効を設定する。
  Future<void> set(bool value) async {
    try {
      await ref.read(databaseManagerProvider).metadataBox.put(lockKey, value);
    } catch (_) {
      // 永続化失敗時も状態は更新する。
    }
    state = value;
  }
}

/// アプリロック有効フラグ。
final appLockEnabledProvider = NotifierProvider<AppLockEnabledNotifier, bool>(
  AppLockEnabledNotifier.new,
);
