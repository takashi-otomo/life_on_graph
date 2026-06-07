import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/features/sleep/sleep_summary.dart';
import 'package:life_on_graph/l10n/app_localizations_en.dart';
import 'package:life_on_graph/l10n/app_localizations_ja.dart';
import 'package:life_on_graph/models/sleep_segment.dart';

SleepSegment seg(int startMin, int endMin, String stage) => SleepSegment(
  startTime: DateTime(2026, 6, 6, 0).add(Duration(minutes: startMin)),
  endTime: DateTime(2026, 6, 6, 0).add(Duration(minutes: endMin)),
  stageType: stage,
  sourcePackage: 'pkg',
);

void main() {
  group('#35 SleepSummary', () {
    test('合計時間とステージ別内訳を集計する', () {
      final summary = SleepSummary.fromSegments([
        seg(0, 60, 'deep'),
        seg(60, 180, 'light'),
        seg(180, 210, 'rem'),
        seg(210, 220, 'awake'),
      ]);

      expect(summary.total, const Duration(minutes: 220));
      expect(summary.stage('deep'), const Duration(minutes: 60));
      expect(summary.stage('light'), const Duration(minutes: 120));
      expect(summary.stage('rem'), const Duration(minutes: 30));
      expect(summary.stage('awake'), const Duration(minutes: 10));
    });

    test('同一ステージの複数セグメントは合算される', () {
      final summary = SleepSummary.fromSegments([
        seg(0, 30, 'deep'),
        seg(60, 90, 'deep'),
      ]);
      expect(summary.stage('deep'), const Duration(minutes: 60));
    });

    test('ステージ比率は合計に対する割合を返す', () {
      final summary = SleepSummary.fromSegments([
        seg(0, 60, 'deep'),
        seg(60, 180, 'light'),
      ]);
      expect(summary.ratio('deep'), closeTo(1 / 3, 1e-9));
      expect(summary.ratio('light'), closeTo(2 / 3, 1e-9));
    });

    test('覚醒エイリアス(awake_in_bed/out_of_bed)は awake に畳み込まれ合計と整合する', () {
      final summary = SleepSummary.fromSegments([
        seg(0, 420, 'light'),
        seg(420, 450, 'awake_in_bed'),
        seg(450, 480, 'out_of_bed'),
      ]);

      // 合計 = 全セグメント、覚醒 = エイリアス合算。
      expect(summary.total, const Duration(minutes: 480));
      expect(summary.stage('awake'), const Duration(minutes: 60));
      // 比率の合計が 1.0 (表示内訳が合計を網羅)。
      expect(
        summary.ratio('light') + summary.ratio('awake'),
        closeTo(1.0, 1e-9),
      );
    });

    test('空入力は isEmpty かつ比率 0', () {
      final summary = SleepSummary.fromSegments(const []);
      expect(summary.isEmpty, isTrue);
      expect(summary.ratio('deep'), 0);
    });
  });

  group('#35 / #94 formatHm', () {
    final ja = AppLocalizationsJa();
    final en = AppLocalizationsEn();
    test('日本語: 時間と分を整形する', () {
      expect(formatHm(const Duration(minutes: 432), ja), '7時間 12分');
      expect(formatHm(const Duration(minutes: 45), ja), '45分');
      expect(formatHm(const Duration(hours: 8), ja), '8時間 0分');
    });
    test('英語: 時間と分を整形する', () {
      expect(formatHm(const Duration(minutes: 432), en), '7h 12m');
      expect(formatHm(const Duration(minutes: 45), en), '45m');
    });
  });
}
