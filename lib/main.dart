import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_colors.dart';
import 'core/app_constants.dart';
import 'core/database_manager.dart';
import 'core/launch_intent.dart';
import 'features/app_shell.dart';
import 'features/rationale/rationale_view.dart';
import 'providers/repository_providers.dart';

/// アプリのエントリポイント。
///
/// 暗号化ローカル DB (Hive) を起動前に初期化し、初期化済みインスタンスを
/// [databaseManagerProvider] へ注入して、ローカルファーストな描画に備える。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final DatabaseManager databaseManager = DatabaseManager();
  await databaseManager.initialize();
  runApp(
    ProviderScope(
      overrides: [databaseManagerProvider.overrideWithValue(databaseManager)],
      child: const LifeOnGraphApp(),
    ),
  );
}

/// Life On Graph (LOG) アプリのルートウィジェット。
class LifeOnGraphApp extends StatelessWidget {
  const LifeOnGraphApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const _RootRouter(),
    );
  }
}

/// 起動インテントに応じて最初の画面を決める (#54)。
///
/// Health Connect の権限根拠/権限使用状況から起動された場合は [RationaleView] を
/// 表示し、それ以外は通常の [AppShell] を表示する。判定中はブロッキングを避けるため
/// 背景色のみを描画する (ローカルファースト)。
class _RootRouter extends StatefulWidget {
  const _RootRouter();

  @override
  State<_RootRouter> createState() => _RootRouterState();
}

class _RootRouterState extends State<_RootRouter> {
  late final Future<String?> _action = LaunchIntent.action();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _action,
      builder: (BuildContext context, AsyncSnapshot<String?> snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const ColoredBox(color: AppColors.background);
        }
        if (LaunchIntent.isRationale(snap.data)) {
          return RationaleView(
            onContinue: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(builder: (_) => const AppShell()),
            ),
          );
        }
        return const AppShell();
      },
    );
  }
}
