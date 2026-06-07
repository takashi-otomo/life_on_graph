import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_constants.dart';
import 'core/database_manager.dart';
import 'core/launch_intent.dart';
import 'features/app_shell.dart';
import 'features/rationale/rationale_view.dart';
import 'features/splash/animated_splash.dart';
import 'providers/repository_providers.dart';
import 'providers/sync_notifier.dart';

/// アプリ全体の Navigator キー(実行中の根拠インテント通知から遷移するため)。
final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

/// 共有テーマ。
final ThemeData _appTheme = ThemeData(
  colorSchemeSeed: Colors.indigo,
  useMaterial3: true,
);

/// アプリのエントリポイント。
///
/// Health Connect の権限根拠/権限使用状況から起動された場合は、暗号化 DB の
/// 初期化を待たず(依存させず)に権限根拠/ポリシー画面を表示する (#54)。通常起動時のみ
/// ローカル DB (Hive) を初期化し、ローカルファーストな描画に備える。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // E2E (Maestro, #75) でセマンティクスを露出させるため debug/profile で常時有効化。
  // release は Flutter が a11y サービス接続時にオンデマンドで有効化するため、
  // 非 a11y ユーザーへの常時計算コストを避けてここでは強制しない。
  if (!kReleaseMode) {
    SemanticsBinding.instance.ensureSemantics();
  }

  final String? action = await LaunchIntent.action();
  if (LaunchIntent.isRationale(action)) {
    runApp(const RationaleApp());
    return;
  }

  // DB 初期化はアニメーションスプラッシュと並行実行し、両者完了で本画面へ遷移する。
  final DatabaseManager databaseManager = DatabaseManager();
  final Future<void> ready = databaseManager.initialize();
  runApp(
    ProviderScope(
      overrides: [databaseManagerProvider.overrideWithValue(databaseManager)],
      child: LifeOnGraphApp(ready: ready),
    ),
  );
}

/// Life On Graph (LOG) アプリのルートウィジェット(通常起動)。
class LifeOnGraphApp extends StatefulWidget {
  const LifeOnGraphApp({super.key, required this.ready});

  /// ローカル DB 初期化の完了 Future。
  final Future<void> ready;

  @override
  State<LifeOnGraphApp> createState() => _LifeOnGraphAppState();
}

class _LifeOnGraphAppState extends State<LifeOnGraphApp> {
  @override
  void initState() {
    super.initState();
    // 実行中に Health Connect の権限根拠インテントが onNewIntent で届いた場合に
    // 根拠画面を前面表示する (#54)。
    LaunchIntent.setRationaleHandler(() {
      _navigatorKey.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => const RationaleView()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: _navigatorKey,
      theme: _appTheme,
      home: _SplashGate(ready: widget.ready),
    );
  }
}

/// アニメーションスプラッシュを表示し、**DB 初期化 → 初回同期(差分更新)** の完了
/// かつアニメ完了で本画面へ遷移する。同期完了まで待つため、スプラッシュは同期時間
/// だけ表示され続ける (ユーザー要望)。DB 初期化失敗時はエラー画面を表示する。
class _SplashGate extends ConsumerStatefulWidget {
  const _SplashGate({required this.ready});

  final Future<void> ready;

  @override
  ConsumerState<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends ConsumerState<_SplashGate> {
  bool _animationDone = false;
  bool _bootDone = false;
  bool _bootFailed = false;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      await widget.ready; // 暗号化 DB の初期化。
    } catch (_) {
      if (mounted) setState(() => _bootFailed = true);
      return; // 初期化失敗時は本画面へ遷移しない (codex P1)。
    }
    // 初回同期 (差分更新) を完了させてからホームへ進む。失敗は表示を妨げない。
    try {
      await ref.read(syncNotifierProvider.notifier).sync();
    } catch (_) {
      // 同期失敗時も保存済みローカルデータで描画する (状態別UI がフォールバック表示)。
    }
    if (mounted) setState(() => _bootDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (_bootFailed) return const _BootErrorView();
    if (_animationDone && _bootDone) return const AppShell();
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        AnimatedSplash(
          onAnimationEnd: () {
            if (mounted) setState(() => _animationDone = true);
          },
        ),
        // アニメ完了後も同期待ちの間は進捗を示す。
        if (_animationDone && !_bootDone)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 72,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
      ],
    );
  }
}

/// DB 初期化失敗時の最小エラー画面。
class _BootErrorView extends StatelessWidget {
  const _BootErrorView();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'アプリの起動に失敗しました。\nお手数ですがアプリを再起動してください。',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// 権限根拠/ポリシー専用のルートアプリ (#54)。
///
/// Health Connect のリンクからの起動時に、DB を初期化せず根拠/ポリシーを表示する。
/// 「アプリを開く」を選んだ時点で初めて DB を初期化し通常アプリへ遷移する。
class RationaleApp extends StatefulWidget {
  const RationaleApp({super.key});

  @override
  State<RationaleApp> createState() => _RationaleAppState();
}

class _RationaleAppState extends State<RationaleApp> {
  DatabaseManager? _db;
  bool _loading = false;

  Future<void> _openApp() async {
    setState(() => _loading = true);
    final DatabaseManager db = DatabaseManager();
    await db.initialize();
    if (mounted) setState(() => _db = db);
  }

  @override
  Widget build(BuildContext context) {
    final DatabaseManager? db = _db;
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _appTheme,
      home: db != null
          ? ProviderScope(
              overrides: [databaseManagerProvider.overrideWithValue(db)],
              child: const AppShell(),
            )
          : RationaleView(onContinue: _loading ? null : () => _openApp()),
    );
  }
}
