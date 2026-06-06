import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_constants.dart';
import 'core/database_manager.dart';
import 'core/launch_intent.dart';
import 'features/app_shell.dart';
import 'features/rationale/rationale_view.dart';
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

  final String? action = await LaunchIntent.action();
  if (LaunchIntent.isRationale(action)) {
    runApp(const RationaleApp());
    return;
  }

  final DatabaseManager databaseManager = DatabaseManager();
  await databaseManager.initialize();
  runApp(
    ProviderScope(
      overrides: [databaseManagerProvider.overrideWithValue(databaseManager)],
      child: const LifeOnGraphApp(),
    ),
  );
}

/// Life On Graph (LOG) アプリのルートウィジェット(通常起動)。
class LifeOnGraphApp extends StatefulWidget {
  const LifeOnGraphApp({super.key});

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
      home: const AppShell(),
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
