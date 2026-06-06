import 'package:permission_handler/permission_handler.dart';

/// ACTIVITY_RECOGNITION ランタイム権限の確認・要求を抽象化する境界 (#58)。
///
/// `permission_handler` (プラットフォームチャネル) を直接参照するとユニットテストで
/// 分岐を検証できないため、本インタフェースを介してフェイクに差し替える。
abstract interface class ActivityRecognitionPermission {
  /// 既に許可済みかを返す。
  Future<bool> isGranted();

  /// 権限を実行時に要求し、許可結果を返す。
  Future<bool> request();
}

/// `permission_handler` に委譲する本番実装。
class PermissionHandlerActivityRecognition
    implements ActivityRecognitionPermission {
  const PermissionHandlerActivityRecognition();

  @override
  Future<bool> isGranted() async =>
      Permission.activityRecognition.status.then((s) => s.isGranted);

  @override
  Future<bool> request() async =>
      Permission.activityRecognition.request().then((s) => s.isGranted);
}
