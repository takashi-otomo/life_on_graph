import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_on_graph/core/database_manager.dart';

import '../helpers/fake_secure_key_store.dart';

/// DatabaseManager は全体で共有されるシングルトンのため、初期化競合の検証は
/// 事前初期化を行わない独立したテストファイル (別アイソレート) で実施する。
void main() {
  test('initialize() の並行呼び出しでも鍵生成は 1 回だけ (競合しない)', () async {
    final tempDir = await Directory.systemTemp.createTemp('log_db_init_test');
    final keyStore = FakeSecureKeyStore();
    final db = DatabaseManager();

    // 初期化完了前に複数回呼び出す。
    await Future.wait([
      db.initialize(path: tempDir.path, keyStore: keyStore),
      db.initialize(path: tempDir.path, keyStore: keyStore),
      db.initialize(path: tempDir.path, keyStore: keyStore),
    ]);

    expect(db.isInitialized, isTrue);
    // 暗号鍵の生成・書き込みは初回の 1 回のみ (異なる鍵の二重生成が起きない)。
    expect(keyStore.writeCount, 1);

    await db.close();
    await tempDir.delete(recursive: true);
  });
}
