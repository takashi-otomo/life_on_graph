import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/core/app_colors.dart';
import 'package:life_on_graph/widgets/capsule_tab_bar.dart';
import 'package:life_on_graph/widgets/metric_card.dart';
import 'package:life_on_graph/widgets/segmented_toggle.dart';

Widget wrap(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('#65 AppColors / SleepStageInfo', () {
    test('睡眠ステージ種別が正しい色にマップされる', () {
      expect(AppColors.sleepStage('deep'), AppColors.sleepDeep);
      expect(AppColors.sleepStage('rem'), AppColors.sleepRem);
      expect(AppColors.sleepStage('unknown-xyz'), AppColors.sleepUnknown);
    });

    test('表示ステージ層は 覚醒→レム→浅い→深い の順', () {
      expect(SleepStageInfo.displayLevels.map((s) => s.key).toList(), <String>[
        'awake',
        'rem',
        'light',
        'deep',
      ]);
      expect(SleepStageInfo.of('deep').level, 3);
      expect(SleepStageInfo.of('awake').level, 0);
    });
  });

  group('#65 MetricCard', () {
    testWidgets('ラベル・値・トレンドを表示する', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MetricCard(
            icon: Icons.bedtime,
            iconColor: AppColors.sleepDeep,
            label: '平均睡眠',
            value: '7時間 4分',
            trend: MetricTrend.up,
            trendLabel: '先週比 +12分',
            trendPositive: true,
          ),
        ),
      );

      expect(find.text('平均睡眠'), findsOneWidget);
      expect(find.text('7時間 4分'), findsOneWidget);
      expect(find.text('先週比 +12分'), findsOneWidget);
      expect(find.byIcon(Icons.trending_up), findsOneWidget);
    });

    testWidgets('下向きトレンドでも悪化は danger 色で表示する (方向と色を分離)', (tester) async {
      await tester.pumpWidget(
        wrap(
          const MetricCard(
            icon: Icons.directions_walk,
            iconColor: AppColors.steps,
            label: '歩数',
            value: '8,432 歩',
            trend: MetricTrend.down,
            trendLabel: '前日比 -640',
            trendPositive: false,
          ),
        ),
      );

      // 下向き矢印 + danger 色のテキスト。
      expect(find.byIcon(Icons.trending_down), findsOneWidget);
      final Text trendText = tester.widget<Text>(find.text('前日比 -640'));
      expect(trendText.style?.color, AppColors.danger);
    });
  });

  group('#65 SegmentedToggle', () {
    testWidgets('セグメントタップで onChanged が呼ばれる', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        wrap(
          SegmentedToggle(
            segments: const <String>['日', '週', '月'],
            selectedIndex: 0,
            onChanged: (i) => tapped = i,
          ),
        ),
      );

      await tester.tap(find.text('月'));
      expect(tapped, 2);
    });
  });

  group('#66 CapsuleTabBar', () {
    testWidgets('タブタップで onTap が呼ばれる', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        wrap(
          CapsuleTabBar(
            items: const <CapsuleTabItem>[
              CapsuleTabItem(icon: Icons.home, label: 'ホーム'),
              CapsuleTabItem(icon: Icons.bar_chart, label: 'サマリー'),
              CapsuleTabItem(icon: Icons.settings, label: '設定'),
            ],
            currentIndex: 0,
            onTap: (i) => tapped = i,
          ),
        ),
      );

      await tester.tap(find.text('設定'));
      expect(tapped, 2);
    });
  });
}
