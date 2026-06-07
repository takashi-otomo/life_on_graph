import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../core/app_constants.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/sync_notifier.dart';

/// 初回起動の初期設定ウィザード (#108)。
///
/// ようこそ → 言語 → Health Connect 連携 → 初回同期 の順に案内し、完了で
/// [onboardingCompletedProvider] を記録して [onFinish] を呼ぶ。
class OnboardingWizard extends ConsumerStatefulWidget {
  const OnboardingWizard({super.key, required this.onFinish});

  /// 完了/スキップ時に呼ばれる (ホームへ遷移)。
  final VoidCallback onFinish;

  @override
  ConsumerState<OnboardingWizard> createState() => _OnboardingWizardState();
}

class _OnboardingWizardState extends ConsumerState<OnboardingWizard> {
  final PageController _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int p) {
    _controller.animateToPage(
      p,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _finish() async {
    await ref.read(onboardingCompletedProvider.notifier).complete();
    widget.onFinish();
  }

  Future<void> _connectAndSync() async {
    _goTo(3);
    try {
      await ref.read(syncNotifierProvider.notifier).sync(force: true);
    } catch (_) {
      // 失敗時もウィザードは進める (ホームの状態別UIがフォローする)。
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: PageView(
          controller: _controller,
          physics: const NeverScrollableScrollPhysics(),
          children: <Widget>[
            _WelcomePage(onStart: () => _goTo(1)),
            _LanguagePage(onNext: () => _goTo(2)),
            _PermissionsPage(onConnect: _connectAndSync, onSkip: _finish),
            _DonePage(onFinish: _finish),
          ],
        ),
      ),
    );
  }
}

/// 進捗ドット。
class _Dots extends StatelessWidget {
  const _Dots({required this.active});
  final int active;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < 4; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3.5),
            width: i == active ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == active ? AppColors.accent : AppColors.divider,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// 共通の primary ボタン。
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

/// インディゴのヒーローアイコン (ようこそ/完了)。
class _Hero extends StatelessWidget {
  const _Hero({this.icon = Icons.monitor_heart});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      height: 104,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF4338CA), Color(0xFF6366F1)],
        ),
      ),
      child: Icon(icon, size: 52, color: Colors.white),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const _Hero(),
                const SizedBox(height: 22),
                Text(
                  l.onbWelcomeTitle(AppConstants.appName),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l.onbWelcomeBody,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const _Dots(active: 0),
          const SizedBox(height: 18),
          _PrimaryButton(label: l.onbStart, onTap: onStart),
        ],
      ),
    );
  }
}

class _LanguagePage extends ConsumerWidget {
  const _LanguagePage({required this.onNext});
  final VoidCallback onNext;

  static String _autonym(String code) => switch (code) {
    'ja' => '日本語',
    'en' => 'English',
    'fr' => 'Français',
    'de' => 'Deutsch',
    'pt' => 'Português',
    'es' => 'Español',
    _ => code,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final Locale? current = ref.watch(localeProvider);
    final List<Locale?> options = <Locale?>[
      null,
      ...AppLocalizations.supportedLocales,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l.language,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.onbLangBody,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: <Widget>[
                    for (int i = 0; i < options.length; i++) ...<Widget>[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.divider),
                      _LangRow(
                        label: options[i] == null
                            ? l.languageSystem
                            : _autonym(options[i]!.languageCode),
                        selected:
                            options[i]?.languageCode == current?.languageCode,
                        onTap: () => ref
                            .read(localeProvider.notifier)
                            .setLocale(options[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Column(
              children: <Widget>[
                const _Dots(active: 1),
                const SizedBox(height: 18),
                _PrimaryButton(label: l.onbNext, onTap: onNext),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LangRow extends StatelessWidget {
  const _LangRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check, size: 20, color: AppColors.accent),
          ],
        ),
      ),
    );
  }
}

class _PermissionsPage extends StatelessWidget {
  const _PermissionsPage({required this.onConnect, required this.onSkip});
  final VoidCallback onConnect;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<({IconData icon, Color color, Color bg, String t, String d})>
    items = <({IconData icon, Color color, Color bg, String t, String d})>[
      (
        icon: Icons.bedtime,
        color: AppColors.sleepDeep,
        bg: AppColors.accentSoft,
        t: l.sleep,
        d: l.rationaleSleepDesc,
      ),
      (
        icon: Icons.directions_walk,
        color: AppColors.steps,
        bg: const Color(0xFFECFDF5),
        t: l.steps,
        d: l.rationaleStepsDesc,
      ),
      (
        icon: Icons.favorite,
        color: AppColors.heart,
        bg: const Color(0xFFFFF1F2),
        t: l.heartRate,
        d: l.rationaleHeartDesc,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  l.onbPermTitle,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l.healthConnectLinkSubtitle,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: <Widget>[
                  for (final it in items) ...<Widget>[
                    _DataRow(
                      icon: it.icon,
                      color: it.color,
                      bg: it.bg,
                      title: it.t,
                      desc: it.d,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.lock,
                          size: 18,
                          color: AppColors.positive,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            l.rationaleSecurity,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
            child: Column(
              children: <Widget>[
                const _Dots(active: 2),
                const SizedBox(height: 14),
                _PrimaryButton(label: l.onbConnect, onTap: onConnect),
                const SizedBox(height: 6),
                TextButton(
                  onPressed: onSkip,
                  child: Text(
                    l.onbSkipSetup,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataRow extends StatelessWidget {
  const _DataRow({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.desc,
  });
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonePage extends ConsumerWidget {
  const _DonePage({required this.onFinish});
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l = AppLocalizations.of(context);
    final SyncState sync = ref.watch(syncNotifierProvider);
    final bool syncing = sync is SyncInProgress;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
      child: Column(
        children: <Widget>[
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (syncing) ...<Widget>[
                  const SizedBox(
                    width: 44,
                    height: 44,
                    child: CircularProgressIndicator(strokeWidth: 3),
                  ),
                  const SizedBox(height: 22),
                  Text(
                    l.onbSyncing,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...<Widget>[
                  const _Hero(icon: Icons.check_rounded),
                  const SizedBox(height: 22),
                  Text(
                    l.onbDoneTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    l.onbDoneBody,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const _Dots(active: 3),
          const SizedBox(height: 18),
          _PrimaryButton(label: l.onbFinish, onTap: syncing ? () {} : onFinish),
        ],
      ),
    );
  }
}
