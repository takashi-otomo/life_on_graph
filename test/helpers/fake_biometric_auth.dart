import 'package:life_on_graph/repositories/biometric_auth.dart';

/// テスト用の [BiometricAuth] フェイク。
class FakeBiometricAuth implements BiometricAuth {
  FakeBiometricAuth({this.available = true, this.authResult = true});

  bool available;
  bool authResult;
  int authCalls = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    authCalls++;
    return authResult;
  }
}
