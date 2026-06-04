import 'dart:convert';
import 'dart:typed_data';

import 'package:hive/hive.dart';

import 'secure_key_store.dart';

/// Hive データベース暗号化用の AES-256 鍵を生成・取得するプロバイダ。
///
/// 鍵は [SecureKeyStore] に base64Url エンコードして保管する。初回呼び出し時のみ
/// `Hive.generateSecureKey()` で 256bit 鍵を生成し、以降は保存済みの鍵を再利用する
/// (冪等)。これにより端末ごとに安定した暗号鍵を維持する。
class EncryptionKeyProvider {
  EncryptionKeyProvider(this._keyStore);

  final SecureKeyStore _keyStore;

  /// セキュアストレージ上の鍵エントリのエイリアス。
  static const String keyAlias = 'hive_encryption_secure_key';

  /// 保存済みの暗号鍵を返す。未生成の場合は生成して保存したうえで返す。
  Future<Uint8List> getOrCreateKey() async {
    final stored = await _keyStore.read(keyAlias);
    if (stored != null) {
      return base64Url.decode(stored);
    }

    final generated = Hive.generateSecureKey();
    await _keyStore.write(keyAlias, base64UrlEncode(generated));
    return Uint8List.fromList(generated);
  }
}
