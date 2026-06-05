import 'package:life_on_graph/core/secure_key_store.dart';

/// テスト用のインメモリ [SecureKeyStore]。プラグイン非依存で鍵保管を再現する。
class FakeSecureKeyStore implements SecureKeyStore {
  final Map<String, String> _store = {};

  /// 現在保持している値の読み取り回数 (冪等性検証用)。
  int writeCount = 0;

  @override
  Future<String?> read(String key) async => _store[key];

  @override
  Future<void> write(String key, String value) async {
    writeCount++;
    _store[key] = value;
  }
}
