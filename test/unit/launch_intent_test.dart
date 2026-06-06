import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/core/launch_intent.dart';

void main() {
  group('#54 LaunchIntent.isRationale', () {
    test('権限根拠インテントは true', () {
      expect(LaunchIntent.isRationale(LaunchIntent.rationaleAction), isTrue);
    });

    test('権限使用状況インテントは true', () {
      expect(
        LaunchIntent.isRationale(LaunchIntent.permissionUsageAction),
        isTrue,
      );
    });

    test('通常起動 (MAIN) や null は false', () {
      expect(LaunchIntent.isRationale('android.intent.action.MAIN'), isFalse);
      expect(LaunchIntent.isRationale(null), isFalse);
    });
  });
}
