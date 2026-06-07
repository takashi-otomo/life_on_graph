import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

/// 初期設定ウィザードを完了済みか (#108)。
///
/// `app_sync_metadata` に永続化し、初回起動の判定に用いる。DB 未初期化時 (テスト等)
/// は `false` (= 未完了) を返す。
class OnboardingNotifier extends Notifier<bool> {
  /// メタデータボックス上の完了フラグキー。
  static const String onboardingKey = 'onboarding_completed';

  @override
  bool build() {
    try {
      return ref.read(databaseManagerProvider).metadataBox.get(onboardingKey) ==
          true;
    } catch (_) {
      return false;
    }
  }

  /// ウィザード完了を記録する。
  Future<void> complete() async {
    try {
      await ref
          .read(databaseManagerProvider)
          .metadataBox
          .put(onboardingKey, true);
    } catch (_) {
      // 永続化に失敗しても遷移は妨げない。
    }
    state = true;
  }
}

/// 初期設定ウィザード完了フラグ。
final onboardingCompletedProvider = NotifierProvider<OnboardingNotifier, bool>(
  OnboardingNotifier.new,
);
