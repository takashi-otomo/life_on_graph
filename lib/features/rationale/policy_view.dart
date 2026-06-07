import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// プライバシーポリシー全文をアプリ内で表示する画面 (#54)。
///
/// Health Connect のポリシーリンクから起動された場合、ガイドラインに従い
/// アプリ内で同一のプライバシーポリシーを表示する必要があるため、公開版と同じ本文を
/// バンドルアセット (`assets/privacy_policy.md`) から読み込んで提示する。
class PolicyView extends StatelessWidget {
  const PolicyView({super.key});

  static Future<String> _load() =>
      rootBundle.loadString('assets/privacy_policy.md');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).privacyPolicy),
        backgroundColor: AppColors.background,
      ),
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _load(),
          builder: (BuildContext context, AsyncSnapshot<String> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError || (snap.data ?? '').isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'プライバシーポリシーを読み込めませんでした。',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                snap.data!,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.textPrimary,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
