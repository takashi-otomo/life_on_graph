import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 暗号鍵などの機密文字列を安全に保管するストアの抽象。
///
/// 本番では [FlutterSecureKeyStore] (Android Keystore 連携) を用いる。
/// テストではフェイク実装に差し替えることで、プラグイン非依存で検証できる。
abstract interface class SecureKeyStore {
  /// [key] に対応する値を取得する。存在しなければ `null`。
  Future<String?> read(String key);

  /// [key] に [value] を保存する。
  Future<void> write(String key, String value);
}

/// `flutter_secure_storage` を用いた [SecureKeyStore] の本番実装。
class FlutterSecureKeyStore implements SecureKeyStore {
  FlutterSecureKeyStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);
}
