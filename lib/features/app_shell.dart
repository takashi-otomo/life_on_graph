import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/nav_provider.dart';
import '../widgets/capsule_tab_bar.dart';
import 'dashboard/dashboard_view.dart';
import 'settings/settings_view.dart';
import 'summary/summary_view.dart';

/// アプリのルートスキャフォールド (#66)。
///
/// 共通ボトムタブ [ホーム / サマリー / 設定] で 3 画面を切り替える。タブ状態は
/// [navTabProvider] で保持し、画面横断のドリルダウン遷移に対応する。
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int index = ref.watch(navTabProvider);
    final AppLocalizations l = AppLocalizations.of(context);
    final List<CapsuleTabItem> tabs = <CapsuleTabItem>[
      CapsuleTabItem(
        icon: Icons.home_rounded,
        label: l.tabHome,
        identifier: 'tab_home',
      ),
      CapsuleTabItem(
        icon: Icons.bar_chart_rounded,
        label: l.tabSummary,
        identifier: 'tab_summary',
      ),
      CapsuleTabItem(
        icon: Icons.settings_rounded,
        label: l.tabSettings,
        identifier: 'tab_settings',
      ),
    ];
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: index,
        children: const <Widget>[
          DashboardView(),
          SummaryView(),
          SettingsView(),
        ],
      ),
      bottomNavigationBar: CapsuleTabBar(
        items: tabs,
        currentIndex: index,
        onTap: (i) => ref.read(navTabProvider.notifier).select(i),
      ),
    );
  }
}
