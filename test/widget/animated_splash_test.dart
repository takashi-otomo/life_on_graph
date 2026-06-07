import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/splash/animated_splash.dart';

void main() {
  testWidgets('ロゴ・略称・名称を表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: AnimatedSplash(onAnimationEnd: () {})),
    );
    // 開始直後の最初のフレーム。
    await tester.pump();
    expect(find.text('LOG'), findsOneWidget);
    expect(find.text('Life On Graph'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);

    // アニメーション完了まで進める。
    await tester.pump(const Duration(milliseconds: 800));
  });

  testWidgets('アニメーション完了で onAnimationEnd を呼ぶ', (tester) async {
    int done = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AnimatedSplash(
          onAnimationEnd: () => done++,
          duration: const Duration(milliseconds: 300),
        ),
      ),
    );
    await tester.pump();
    expect(done, 0);
    await tester.pump(const Duration(milliseconds: 350));
    expect(done, 1);
  });
}
