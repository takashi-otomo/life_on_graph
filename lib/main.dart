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

/// アニメーションスプラッシュを表示し、アニメ完了 **かつ** DB 準備完了で本画面へ。
class _SplashGate extends StatefulWidget {
  const _SplashGate({required this.ready});

  final Future<void> ready;

  @override
  State<_SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<_SplashGate> {
  bool _animationDone = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    widget.ready
        .then((_) {
          if (mounted) setState(() => _ready = true);
        })
        .catchError((_) {
          // 初期化失敗時も画面遷移は妨げない (DB 側の回復に委ねる)。
          if (mounted) setState(() => _ready = true);
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_animationDone && _ready) return const AppShell();
    return AnimatedSplash(
      onAnimationEnd: () {
        if (mounted) setState(() => _animationDone = true);
      },
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
