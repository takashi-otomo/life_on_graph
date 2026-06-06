import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/rationale/policy_view.dart';
import 'package:life_on_graph/features/rationale/rationale_view.dart';

void main() {
  testWidgets('#54 データ種別(履歴含む)と用途・ポリシー導線を表示する', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RationaleView()));
    await tester.pumpAndSettle();

    expect(find.text('ヘルスデータの利用について'), findsOneWidget);
    expect(find.text('睡眠'), findsOneWidget);
    expect(find.text('歩数'), findsOneWidget);
    expect(find.text('心拍'), findsOneWidget);
    // 履歴権限の説明 (#54 codex P1)。
    expect(find.text('過去データ(履歴)'), findsOneWidget);
    expect(find.text('プライバシーポリシーを読む'), findsOneWidget);
    // onContinue 未指定なら「アプリを開く」は出さない。
    expect(find.text('アプリを開く'), findsNothing);
  });

  testWidgets('#54 ポリシーをアプリ内 (PolicyView) で表示する', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RationaleView()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('プライバシーポリシーを読む'));
    await tester.pumpAndSettle();

    expect(find.byType(PolicyView), findsOneWidget);
    // バンドルした本文の見出しが表示される。
    expect(find.textContaining('プライバシーポリシー'), findsWidgets);
  });

  testWidgets('#54 onContinue 指定時は「アプリを開く」でコールバックする', (tester) async {
    int tapped = 0;
    // 全要素が収まる高めのビューポートにして末尾ボタンを可視にする。
    tester.view.physicalSize = const Size(1200, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
