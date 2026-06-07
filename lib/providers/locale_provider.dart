import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

/// アプリの表示言語 (ロケール) の状態 (#94)。
///
/// `null` は「端末の言語設定に従う」を意味する。ユーザーが設定画面で明示的に選んだ
/// 場合はその言語を `app_sync_metadata` に永続化し、次回起動時も維持する。
class LocaleNotifier extends Notifier<Locale?> {
  /// メタデータボックス上の言語コードキー。
  static const String localeKey = 'locale_code';

  @override
  Locale? build() {
    try {
      final Object? code = ref
          .read(databaseManagerProvider)
          .metadataBox
          .get(localeKey);
      return (code is String && code.isNotEmpty) ? Locale(code) : null;
    } catch (_) {
      // DB 未初期化 (テスト等) では端末設定に従う。
      return null;
    }
  }

  /// 表示言語を変更する。`null` で端末設定に追従する。
  Future<void> setLocale(Locale? locale) async {
    final box = ref.read(databaseManagerProvider).metadataBox;
    if (locale == null) {
      await box.delete(localeKey);
    } else {
      await box.put(localeKey, locale.languageCode);
    }
    state = locale;
  }
}

/// 表示言語プロバイダ。`null` = 端末設定に従う。
final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);
