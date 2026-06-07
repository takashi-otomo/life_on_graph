import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/health_sync_repository.dart';
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
      final metadata = ref.read(databaseManagerProvider).metadataBox;
      if (metadata.get(onboardingKey) == true) return true;
      // 本機能導入前に利用済みの既存インストール (同期履歴あり) はウィザード対象外
      // とする (アップデート後に初回扱いしない) (codex P1)。
      if (metadata.get(HealthSyncRepositoryImpl.lastSyncTimeKey) != null) {
        return true;
      }
      return false;
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

/// ホームの初回自動同期を一度だけ抑止するフラグの状態。
class SuppressInitialSyncNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}

/// ウィザードを「あとで設定する」でスキップした直後、ホームの初回自動同期を一度だけ
/// 抑止するフラグ (権限ダイアログの即時表示を避ける) (#108 / codex P1)。
final suppressInitialSyncProvider =
    NotifierProvider<SuppressInitialSyncNotifier, bool>(
      SuppressInitialSyncNotifier.new,
    );
