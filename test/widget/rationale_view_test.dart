import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/rationale/rationale_view.dart';

void main() {
  testWidgets('#54 データ種別と用途・ポリシー導線を表示する', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RationaleView()));
    await tester.pumpAndSettle();

    expect(find.text('ヘルスデータの利用について'), findsOneWidget);
    expect(find.text('睡眠'), findsOneWidget);
    expect(find.text('歩数'), findsOneWidget);
    expect(find.text('心拍'), findsOneWidget);
    expect(find.text('プライバシーポリシーを開く'), findsOneWidget);
    // onContinue 未指定なら「アプリを開く」は出さない。
    expect(find.text('アプリを開く'), findsNothing);
  });

  testWidgets('#54 onContinue 指定時は「アプリを開く」でコールバックする', (tester) async {
    int tapped = 0;
    await tester.pumpWidget(
      MaterialApp(home: RationaleView(onContinue: () => tapped++)),
    );
    await tester.pumpAndSettle();

    expect(find.text('アプリを開く'), findsOneWidget);
    await tester.tap(find.text('アプリを開く'));
    await tester.pump();
    expect(tapped, 1);
  });
}
