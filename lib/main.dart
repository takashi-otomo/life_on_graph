import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_constants.dart';
import 'core/database_manager.dart';
import 'features/dashboard/dashboard_view.dart';

/// アプリのエントリポイント。
///
/// 暗号化ローカル DB (Hive) を起動前に初期化し、ローカルファーストな描画に備える。
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseManager().initialize();
  runApp(const ProviderScope(child: LifeOnGraphApp()));
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
      home: const DashboardView(),
    );
  }
}
