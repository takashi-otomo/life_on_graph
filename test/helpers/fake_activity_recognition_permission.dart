import 'package:life_on_graph/repositories/activity_recognition_permission.dart';

/// テスト用の [ActivityRecognitionPermission] フェイク。
class FakeActivityRecognitionPermission
    implements ActivityRecognitionPermission {
  FakeActivityRecognitionPermission({
    this.alreadyGranted = false,
    this.requestResult = true,
    this.throwOnAccess = false,
  });

  /// 既に許可済みか ([isGranted] の戻り値)。
  bool alreadyGranted;

  /// [request] が返す許可結果。
  bool requestResult;

  /// 権限 API で例外を投げるか。
  bool throwOnAccess;

  int requestCount = 0;
  bool isGrantedCalled = false;

  @override
  Future<bool> isGranted() async {
    isGrantedCalled = true;
    if (throwOnAccess) throw StateError('fake permission failure');
    return alreadyGranted;
  }

  @override
  Future<bool> request() async {
    requestCount++;
    if (throwOnAccess) throw StateError('fake permission request failure');
    return requestResult;
  }
}
