import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_on_graph/core/app_constants.dart';
import 'package:life_on_graph/features/dashboard/dashboard_view.dart';
import 'package:life_on_graph/main.dart';
import 'package:life_on_graph/providers/repository_providers.dart';

import '../helpers/fake_health_sync_repository.dart';

void main() {
  group('LifeOnGraphApp スモークテスト', () {
    Widget app() => ProviderScope(
      overrides: [
        healthSyncRepositoryProvider.overrideWithValue(
          FakeHealthSyncRepository(),
        ),
      ],
      child: const LifeOnGraphApp(),
    );

    testWidgets('ProviderScope 配下でアプリが例外なく起動する', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(DashboardView), findsOneWidget);
    });

    testWidgets('アプリ名 "Life On Graph" が AppBar に表示される', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text(AppConstants.appName), findsWidgets);
      expect(AppConstants.appName, 'Life On Graph');
    });
  });
}
