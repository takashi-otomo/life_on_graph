import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_on_graph/core/app_constants.dart';
import 'package:life_on_graph/features/dashboard/dashboard_view.dart';
import 'package:life_on_graph/main.dart';
import 'package:life_on_graph/providers/locale_provider.dart';
import 'package:life_on_graph/providers/repository_providers.dart';

import '../helpers/fake_health_sync_repository.dart';

/// テストで日本語 UI に固定するための locale ノーティファイア。
class _JaLocaleNotifier extends LocaleNotifier {
  @override
  Locale? build() => const Locale('ja');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 起動インテント取得 (#54) の MethodChannel をモックし、通常起動 (null) を返す。
  setUp(() {
    // 端末ロケールを日本語に固定 (日本語 UI 文言を検証するため)。
    TestWidgetsFlutterBinding.instance.platformDispatcher.localeTestValue =
        const Locale('ja');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dev.otomo.life_on_graph/launch'),
          (MethodCall call) async => null,
        );
  });
  tearDown(() {
    TestWidgetsFlutterBinding.instance.platformDispatcher
        .clearLocaleTestValue();
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
        localeProvider.overrideWith(_JaLocaleNotifier.new),
      ],
      child: LifeOnGraphApp(ready: Future<void>.value()),
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

    testWidgets('DB初期化失敗時はエラー画面を表示し本画面へ遷移しない', (tester) async {
      // await 接続後にエラー完了させ、未処理エラー扱いを避ける。
      final Completer<void> ready = Completer<void>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            healthSyncRepositoryProvider.overrideWithValue(
              FakeHealthSyncRepository(),
            ),
          ],
          child: LifeOnGraphApp(ready: ready.future),
        ),
      );
      await tester.pump(); // initState → _boot が ready を await。
      ready.completeError(StateError('boot fail'));
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.textContaining('起動に失敗'), findsOneWidget);
      expect(find.byType(DashboardView), findsNothing);
    });
  });
}
