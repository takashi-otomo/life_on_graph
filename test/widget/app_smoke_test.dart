import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_on_graph/core/app_constants.dart';
import 'package:life_on_graph/features/dashboard/dashboard_view.dart';
import 'package:life_on_graph/main.dart';
import 'package:life_on_graph/providers/repository_providers.dart';

import '../helpers/fake_health_sync_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 起動インテント取得 (#54) の MethodChannel をモックし、通常起動 (null) を返す。
  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.otomo.life_on_graph/launch'),
          (MethodCall call) async => null,
        );
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.otomo.life_on_graph/launch'),
          null,
        );
  });

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

    testWidgets('共通ボトムタブ [ホーム/サマリー/設定] が表示される', (tester) async {
      await tester.pumpWidget(app());
      await tester.pumpAndSettle();

      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('サマリー'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
      expect(AppConstants.appName, 'Life On Graph');
    });
  });
}
