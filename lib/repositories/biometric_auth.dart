import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

/// 生体認証 (端末ロック含む) への薄い抽象境界 (#79)。テスト時はフェイク化する。
abstract interface class BiometricAuth {
  /// 端末が認証 (生体 or デバイス資格情報) に対応しているか。
  Future<bool> isAvailable();

  /// 認証を要求し、成功したら `true`。
  Future<bool> authenticate(String reason);
}

/// `local_auth` による実装。
class LocalAuthBiometric implements BiometricAuth {
  LocalAuthBiometric([LocalAuthentication? auth])
    : _auth = auth ?? LocalAuthentication();

  final LocalAuthentication _auth;

  @override
  Future<bool> isAvailable() async {
    try {
      return await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        // biometricOnly=false (既定) で、生体が無い端末では PIN/パターン等の
        // デバイス資格情報にフォールバックする。
        persistAcrossBackgrounding: true,
      );
    } catch (_) {
      return false;
    }
  }
}

/// 生体認証プロバイダ。
final biometricAuthProvider = Provider<BiometricAuth>(
  (ref) => LocalAuthBiometric(),
);
