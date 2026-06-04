import 'package:flutter/material.dart';

import '../../core/app_constants.dart';

/// ダッシュボードのトップ画面。
///
/// M0 時点ではプレースホルダであり、後続フェーズ (M6) で睡眠・歩数・脈拍の
/// 各可視化ビューを束ねるダッシュボードへ拡張する。
class DashboardView extends StatelessWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.show_chart, size: 64),
              SizedBox(height: 16),
              Text(
                'Life On Graph (LOG)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('睡眠・歩数・脈拍を可視化するヘルスケアアプリ', textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
