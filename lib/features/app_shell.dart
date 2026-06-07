import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../providers/nav_provider.dart';
import '../providers/tutorial_provider.dart';
import '../widgets/capsule_tab_bar.dart';
import 'dashboard/dashboard_view.dart';
import 'settings/settings_view.dart';
import 'summary/summary_view.dart';
import 'tutorial/tutorial_keys.dart';
import 'tutorial/tutorial_overlay.dart';

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
    final bool showTutorial = !ref.watch(tutorialCompletedProvider);
    final Widget scaffold = Scaffold(
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
      bottomNavigationBar: KeyedSubtree(
        key: TutorialKeys.tabBar,
        child: CapsuleTabBar(
          items: tabs,
          currentIndex: index,
          onTap: (i) => ref.read(navTabProvider.notifier).select(i),
        ),
      ),
    );
    if (!showTutorial) return scaffold;
    // 初回チュートリアル: ホームタブを前提にスポットライト表示する (#109)。
    return Stack(
      children: <Widget>[
        scaffold,
        Positioned.fill(child: TutorialOverlay(onFinish: () {})),
      ],
    );
  }
}
