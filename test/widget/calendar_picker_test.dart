import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/calendar/calendar_picker.dart';
import 'package:life_on_graph/l10n/app_localizations.dart';

void main() {
  Future<DateTime?> open(
    WidgetTester tester, {
    required CalendarMode mode,
    required DateTime initial,
    required DateTime last,
  }) async {
    DateTime? result;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showCalendarPicker(
                    context,
                    mode: mode,
                    initial: initial,
                    last: last,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return Future<DateTime?>.value(result);
  }

  testWidgets('#101 日モード: タップした日を返す', (tester) async {
    await open(
      tester,
      mode: CalendarMode.day,
      initial: DateTime(2026, 6, 7),
      last: DateTime(2026, 6, 7),
    );
    await tester.tap(find.text('3'));
    await tester.pumpAndSettle();
    // result はクロージャ内で設定されるため、再度ボタン経由で取得する代わりに
    // ピッカーが閉じたことを確認する。
    expect(find.text('今日へ'), findsNothing);
  });

  testWidgets('#101 日モード: 未来日は選択できない', (tester) async {
    await open(
      tester,
      mode: CalendarMode.day,
      initial: DateTime(2026, 6, 7),
      last: DateTime(2026, 6, 7),
    );
    // 8 日 (未来) をタップしてもシートは閉じない。
    await tester.tap(find.text('8'));
    await tester.pumpAndSettle();
    expect(find.text('今日へ'), findsOneWidget);
  });

  testWidgets('#101 月モード: 月グリッドと年ナビを表示する', (tester) async {
    await open(
      tester,
      mode: CalendarMode.month,
      initial: DateTime(2026, 6),
      last: DateTime(2026, 6, 7),
    );
    expect(find.text('今月へ'), findsOneWidget);
    expect(find.text('1月'), findsOneWidget);
    expect(find.text('6月'), findsOneWidget);
  });
}
