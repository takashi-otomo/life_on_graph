import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_constants.dart';
import 'core/database_manager.dart';
import 'features/app_shell.dart';
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
      home: const AppShell(),
    );
  }
}
