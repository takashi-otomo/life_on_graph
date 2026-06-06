import 'package:life_on_graph/core/secure_key_store.dart';

/// テスト用のインメモリ [SecureKeyStore]。プラグイン非依存で鍵保管を再現する。
class FakeSecureKeyStore implements SecureKeyStore {
  final Map<String, String> _store = {};

  /// 読み取り時に例外を投げるキー (Auto Backup 復元で Keystore 材料が欠落した状態を再現)。
  ///
  /// 復元された SharedPreferences のエントリは存在するが、対応する Keystore 材料が
  /// 無く unwrap に失敗する状況を模す。`delete` で解消される。
  final Set<String> _corruptKeys = {};

  /// 現在保持している値の書き込み回数 (冪等性検証用)。
  int writeCount = 0;

  /// 削除回数。
  int deleteCount = 0;

  /// [key] を破損エントリとして種付けする (read が例外を投げる)。
  void seedCorrupt(String key, String value) {
    _store[key] = value;
    _corruptKeys.add(key);
  }

  @override
  Future<String?> read(String key) async {
    if (_corruptKeys.contains(key)) {
      throw StateError('InvalidKeyException: Failed to unwrap key (fake)');
    }
    return _store[key];
  }

  @override
  Future<void> write(String key, String value) async {
    writeCount++;
    _store[key] = value;
    // 新規書き込みは健全なエントリ。
    _corruptKeys.remove(key);
  }

  @override
  Future<void> delete(String key) async {
    deleteCount++;
    _store.remove(key);
    _corruptKeys.remove(key);
  }
}
