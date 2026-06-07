import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repositories/health_sync_repository.dart';
import 'onboarding_provider.dart';
import 'repository_providers.dart';

/// 初回チュートリアルを完了/スキップ済みか (#109)。
///
/// `app_sync_metadata` に永続化。既存インストール (本機能導入前に同期済み) は表示しない。
class TutorialCompletedNotifier extends Notifier<bool> {
  static const String tutorialKey = 'tutorial_completed';

  @override
  bool build() {
    try {
      final metadata = ref.read(databaseManagerProvider).metadataBox;
      if (metadata.get(tutorialKey) == true) return true;
      // 既存インストール (本機能導入前から利用 = 同期履歴あり かつ オンボーディング
      // 未完了フラグ無し) はチュートリアルを出さない。オンボーディングを完了した
      // 新規ユーザー (同期で last_sync が立っていても) には出す。
      final bool onboarded =
          metadata.get(OnboardingNotifier.onboardingKey) == true;
      final bool hasSync =
          metadata.get(HealthSyncRepositoryImpl.lastSyncTimeKey) != null;
      if (hasSync && !onboarded) return true;
      return false;
    } catch (_) {
      return false;
    }
  }

  /// チュートリアル完了/スキップを記録する。
  Future<void> complete() async {
    try {
      await ref
          .read(databaseManagerProvider)
          .metadataBox
          .put(tutorialKey, true);
    } catch (_) {
      // 永続化失敗時も表示状態は更新する。
    }
    state = true;
  }
}

/// 初回チュートリアル完了フラグ。
final tutorialCompletedProvider =
    NotifierProvider<TutorialCompletedNotifier, bool>(
      TutorialCompletedNotifier.new,
    );
