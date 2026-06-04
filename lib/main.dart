import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_constants.dart';
import 'features/dashboard/dashboard_view.dart';

/// アプリのエントリポイント。
///
/// 現時点 (M0) ではローカル DB 初期化前のスケルトンであり、後続のフェーズ
/// (M2 で `DatabaseManager().initialize()` を追加) で初期化処理を組み込む。
void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
