import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
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

  static const List<CapsuleTabItem> _tabs = <CapsuleTabItem>[
    CapsuleTabItem(
      icon: Icons.home_rounded,
      label: 'ホーム',
      identifier: 'tab_home',
    ),
    CapsuleTabItem(
      icon: Icons.bar_chart_rounded,
      label: 'サマリー',
      identifier: 'tab_summary',
    ),
    CapsuleTabItem(
      icon: Icons.settings_rounded,
      label: '設定',
      identifier: 'tab_settings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int index = ref.watch(navTabProvider);
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
        items: _tabs,
        currentIndex: index,
        onTap: (i) => ref.read(navTabProvider.notifier).select(i),
      ),
    );
  }
}
