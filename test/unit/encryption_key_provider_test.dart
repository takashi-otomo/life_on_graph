import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/core/encryption_key_provider.dart';

import '../helpers/fake_secure_key_store.dart';

void main() {
  group('EncryptionKeyProvider', () {
    test('鍵が未保存のときは生成して保存する', () async {
      final store = FakeSecureKeyStore();
      final provider = EncryptionKeyProvider(store);

      final key = await provider.getOrCreateKey();

      // AES-256 鍵は 32 バイト。
      expect(key.length, 32);
      // セキュアストレージへ base64Url で保存されている。
      final saved = await store.read(EncryptionKeyProvider.keyAlias);
      expect(saved, isNotNull);
      expect(base64Url.decode(saved!), key);
      expect(store.writeCount, 1);
    });

    test('2回目以降は保存済みの同じ鍵を返す (冪等・再生成しない)', () async {
      final store = FakeSecureKeyStore();
      final provider = EncryptionKeyProvider(store);

      final first = await provider.getOrCreateKey();
      final second = await provider.getOrCreateKey();

      expect(second, first);
      // 書き込みは初回の 1 回のみ。
      expect(store.writeCount, 1);
    });
  });
}
