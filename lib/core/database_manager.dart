import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../models/heart_rate_record_model.dart';
import '../models/sleep_record_model.dart';
import '../models/steps_record_model.dart';
import 'encryption_key_provider.dart';
import 'secure_key_store.dart';

/// ローカル永続化層 (Hive) の初期化とボックス管理を担うシングルトン。
///
/// 睡眠・歩数・心拍の各ボックスは AES-256 ([HiveAesCipher]) で暗号化する。
/// 暗号鍵は [EncryptionKeyProvider] 経由で取得し、平文では保持しない。
/// 同期タイムスタンプ等の非機密メタデータは平文ボックスに保存する。
class DatabaseManager {
  DatabaseManager._internal();

  static final DatabaseManager _instance = DatabaseManager._internal();

  /// アプリ全体で共有する唯一のインスタンス。
  factory DatabaseManager() => _instance;

  /// 暗号化された睡眠レコードボックス名。
  static const String sleepBoxName = 'encrypted_sleep_records';

  /// 暗号化された歩数レコードボックス名。
  static const String stepsBoxName = 'encrypted_steps_records';

  /// 暗号化された心拍レコードボックス名。
  static const String heartRateBoxName = 'encrypted_heart_rate_records';

  /// 同期メタデータ (平文) ボックス名。
  static const String metadataBoxName = 'app_sync_metadata';

  late Box<SleepRecordModel> _sleepBox;
  late Box<StepsRecordModel> _stepsBox;
  late Box<HeartRateRecordModel> _heartRateBox;
  late Box<dynamic> _metadataBox;

  bool _initialized = false;
  Future<void>? _initFuture;

  /// 直近の初期化で鍵不整合からの復旧 (鍵再生成 + 暗号化ボックス破棄) を行ったか。
  ///
  /// `true` の場合、暗号化データは破棄されており Health Connect からの再同期が必要。
  bool recoveredFromKeyFailure = false;

  /// 暗号化ボックス名の一覧 (復旧時の一括破棄に用いる)。
  static const List<String> encryptedBoxNames = <String>[
    sleepBoxName,
    stepsBoxName,
    heartRateBoxName,
  ];

  /// 暗号化された睡眠レコードボックス。
  Box<SleepRecordModel> get sleepBox => _sleepBox;

  /// 暗号化された歩数レコードボックス。
  Box<StepsRecordModel> get stepsBox => _stepsBox;

  /// 暗号化された心拍レコードボックス。
  Box<HeartRateRecordModel> get heartRateBox => _heartRateBox;

  /// 同期メタデータ (平文) ボックス。
  Box<dynamic> get metadataBox => _metadataBox;

  /// 初期化済みかどうか。
  bool get isInitialized => _initialized;

  /// Hive とアダプタ・暗号化ボックスを初期化する。
  ///
  /// [path] を指定した場合は `Hive.init(path)` を用いる (テストや非 Flutter 環境向け)。
  /// 省略時は `Hive.initFlutter()` を用いてアプリのドキュメントディレクトリを使う。
  /// [keyStore] を省略すると本番用の [FlutterSecureKeyStore] を使用する。
  ///
  /// 並行して複数回呼び出されても初期化は一度だけ実行される (進行中の Future を
  /// メモ化)。これによりコールドスタート時に異なる暗号鍵が二重生成される競合を防ぐ。
  Future<void> initialize({String? path, SecureKeyStore? keyStore}) {
    if (_initialized) return Future<void>.value();
    return _initFuture ??= _doInitialize(path: path, keyStore: keyStore)
        .whenComplete(() {
          // 失敗時は次回の再初期化を許可するためメモ化をリセットする。
          if (!_initialized) _initFuture = null;
        });
  }

  Future<void> _doInitialize({String? path, SecureKeyStore? keyStore}) async {
    recoveredFromKeyFailure = false;
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }

    _registerAdapters();

    // 平文メタデータは鍵に依存しないため先に開く。
    _metadataBox = await Hive.openBox<dynamic>(metadataBoxName);

    final provider = EncryptionKeyProvider(keyStore ?? FlutterSecureKeyStore());
    try {
      await _openEncryptedBoxes(provider);
    } catch (_) {
      // 鍵不整合 (Auto Backup 復元で Keystore 材料が欠落し復号に失敗する等) で
      // 起動時クラッシュを起こさないよう、鍵を再生成し暗号化ボックスを破棄して
      // 再構築する。破棄したデータは Health Connect から再同期して復旧する。
      await _recoverFromKeyFailure(provider);
    }

    _initialized = true;
  }

  /// 暗号鍵を取得し、3 つの暗号化ボックスを開く。
  Future<void> _openEncryptedBoxes(EncryptionKeyProvider provider) async {
    final encryptionKey = await provider.getOrCreateKey();
    final cipher = HiveAesCipher(encryptionKey);

    _sleepBox = await Hive.openBox<SleepRecordModel>(
      sleepBoxName,
      encryptionCipher: cipher,
    );
    _stepsBox = await Hive.openBox<StepsRecordModel>(
      stepsBoxName,
      encryptionCipher: cipher,
    );
    _heartRateBox = await Hive.openBox<HeartRateRecordModel>(
      heartRateBoxName,
      encryptionCipher: cipher,
    );
  }

  /// 鍵不整合からの復旧: 鍵を再生成し暗号化ボックスを破棄して再構築する。
  ///
  /// 3 ボックスは同一鍵を共有するため、失敗は鍵取得時点 (= ボックス open 前) に
  /// 起きる。よって破棄前に open 済みボックスを閉じる必要はない。
  Future<void> _recoverFromKeyFailure(EncryptionKeyProvider provider) async {
    await provider.resetKey();
    for (final name in encryptedBoxNames) {
      await Hive.deleteBoxFromDisk(name);
    }
    // 同期メタデータをクリアし、次回同期で 30 日バックフィルを走らせる。
    await _metadataBox.clear();

    await _openEncryptedBoxes(provider);
    recoveredFromKeyFailure = true;
  }

  /// 全ボックスを閉じる (主にテストのクリーンアップ用)。
  Future<void> close() async {
    if (!_initialized) return;
    await Hive.close();
    _initialized = false;
    _initFuture = null;
  }

  void _registerAdapters() {
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(SleepRecordModelAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StepsRecordModelAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(HeartRateRecordModelAdapter());
    }
  }
}
