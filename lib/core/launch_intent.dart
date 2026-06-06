import 'package:flutter/services.dart';

/// 起動インテントの種別判定と取得 (#54)。
///
/// Health Connect の権限根拠リンク (`ACTION_SHOW_PERMISSIONS_RATIONALE`) や
/// 権限使用状況 (`VIEW_PERMISSION_USAGE`) から起動された場合に、アプリ内の
/// 権限根拠/プライバシーポリシー画面へ遷移させるための判定を提供する。
class LaunchIntent {
  LaunchIntent._();

  static const MethodChannel _channel = MethodChannel(
    'dev.otomo.life_on_graph/launch',
  );

  /// Health Connect の権限根拠表示インテント。
  static const String rationaleAction =
      'androidx.health.ACTION_SHOW_PERMISSIONS_RATIONALE';

  /// 権限使用状況表示インテント (Android 14+)。
  static const String permissionUsageAction =
      'android.intent.action.VIEW_PERMISSION_USAGE';

  /// 起動インテントの action を取得する。非対応・エラー時は `null`。
  static Future<String?> action() async {
    try {
      return await _channel.invokeMethod<String>('getLaunchAction');
    } catch (_) {
      return null;
    }
  }

  /// [action] が権限根拠/権限使用状況からの起動か (根拠画面へ遷移すべきか)。
  static bool isRationale(String? action) =>
      action == rationaleAction || action == permissionUsageAction;

  /// 実行中のアプリへ権限根拠インテントが `onNewIntent` で届いた場合の通知を購読する。
  ///
  /// ネイティブが `showRationale` を呼ぶと [onRationale] を実行する (#54)。
  static void setRationaleHandler(void Function() onRationale) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'showRationale') onRationale();
      return null;
    });
  }
}
