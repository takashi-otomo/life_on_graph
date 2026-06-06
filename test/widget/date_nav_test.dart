import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/sleep/widgets/date_nav_header.dart';
import 'package:life_on_graph/providers/selected_date_provider.dart';

void main() {
  Widget app() => const ProviderScope(
    child: MaterialApp(home: Scaffold(body: DateNavHeader())),
  );

  testWidgets('#41 初期表示は今日 (「今日」ラベル) ', (tester) async {
    await tester.pumpWidget(app());
    final DateTime now = DateTime.now();
    expect(
      find.text(
        DateNavHeader.formatDate(DateTime(now.year, now.month, now.day)),
      ),
      findsOneWidget,
    );
    expect(find.text('今日'), findsOneWidget);
  });

  testWidgets('#41 前日ボタンで前日へ移動し「今日」が消える', (tester) async {
    await tester.pumpWidget(app());

    await tester.tap(find.byIcon(Icons.chevron_left));
    await tester.pumpAndSettle();

    final DateTime y = DateTime.now().subtract(const Duration(days: 1));
    expect(
      find.text(DateNavHeader.formatDate(DateTime(y.year, y.month, y.day))),
      findsOneWidget,
    );
    expect(find.text('今日'), findsNothing);
  });

  testWidgets('#41 翌日ボタンは今日では無効 (未来へ進めない)', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(selectedDateProvider.notifier);

    // 今日では next() は状態を変えない。
    final before = container.read(selectedDateProvider);
    notifier.next();
    expect(container.read(selectedDateProvider), before);

    // 前日に戻ってから next() で今日へ戻れる。
    notifier.previous();
    notifier.next();
    expect(container.read(selectedDateProvider), before);
  });
}
