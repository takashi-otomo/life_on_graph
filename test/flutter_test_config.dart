import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

/// 全テスト実行前に各ロケールの日付整形 (DateFormat) データを初期化する (#94)。
///
/// 本番では `main()` で `initializeDateFormatting()` を呼ぶが、ウィジェットテストは
/// `main()` を経由しないため、ここで一括初期化する。
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await initializeDateFormatting();
  await testMain();
}
