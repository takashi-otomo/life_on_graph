import 'package:hive_flutter/hive_flutter.dart';

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
  Future<void> initialize({String? path, SecureKeyStore? keyStore}) async {
    if (_initialized) return;

    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }

    _registerAdapters();

    final provider = EncryptionKeyProvider(keyStore ?? FlutterSecureKeyStore());
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
    _metadataBox = await Hive.openBox<dynamic>(metadataBoxName);

    _initialized = true;
  }

  /// 全ボックスを閉じる (主にテストのクリーンアップ用)。
  Future<void> close() async {
    if (!_initialized) return;
    await Hive.close();
    _initialized = false;
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
