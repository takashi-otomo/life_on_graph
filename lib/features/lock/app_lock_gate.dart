import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/app_lock_provider.dart';
import '../../repositories/biometric_auth.dart';

/// アプリのロック (生体認証) ゲート (#79)。
///
/// ロック有効時は、起動時およびバックグラウンド復帰時に認証を要求し、成功するまで
/// [child] を覆い隠す。認証成功で解錠する。
class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> {
  late final AppLifecycleListener _lifecycle;
  bool _unlocked = false;
  bool _authInProgress = false;

  @override
  void initState() {
    super.initState();
    final bool enabled = ref.read(appLockEnabledProvider);
    _unlocked = !enabled;
    _lifecycle = AppLifecycleListener(onHide: _onHide, onResume: _onResume);
    if (enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
    }
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  /// バックグラウンドへ移行したら施錠する (復帰時に再認証)。
  void _onHide() {
    if (ref.read(appLockEnabledProvider) && mounted) {
      setState(() => _unlocked = false);
    }
  }

  void _onResume() {
    if (ref.read(appLockEnabledProvider) &&
        !_unlocked &&
        !_authInProgress &&
        mounted) {
      _authenticate();
    }
  }

  Future<void> _authenticate() async {
    if (_authInProgress) return;
    setState(() => _authInProgress = true);
    final String reason = AppLocalizations.of(context).lockReason;
    final bool ok = await ref.read(biometricAuthProvider).authenticate(reason);
    if (!mounted) return;
    setState(() {
      _authInProgress = false;
      if (ok) _unlocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = ref.watch(appLockEnabledProvider);
    if (!enabled || _unlocked) return widget.child;
    return _LockScreen(busy: _authInProgress, onUnlock: _authenticate);
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.busy, required this.onUnlock});

  final bool busy;
  final VoidCallback onUnlock;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF4338CA), Color(0xFF6366F1)],
                ),
              ),
              child: const Icon(Icons.lock, size: 44, color: Colors.white),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 48,
              child: busy
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : FilledButton.icon(
                      onPressed: onUnlock,
                      icon: const Icon(Icons.fingerprint, size: 20),
                      label: Text(l.unlock),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
