import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/heart_rate_record_model.dart';
import '../models/sleep_segment.dart';
import '../models/steps_record_model.dart';
import 'repository_providers.dart';
import 'sync_notifier.dart';

/// 期間指定の値オブジェクト (family 引数)。
///
/// 値等価により同一期間のプロバイダキャッシュを共有する。
class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// 指定日のクレンジング済み睡眠セグメント (T-503)。
///
/// ローカル DB から待ち無しで取得する (ローカルファースト即時描画)。
/// [syncNotifierProvider] を `watch` するため、同期完了 (done) で自動再評価される。
final sleepSegmentsProvider = Provider.family<List<SleepSegment>, DateTime>((
  ref,
  date,
) {
  ref.watch(syncNotifierProvider);
  return ref
      .watch(healthSyncRepositoryProvider)
      .getCleanedSleepSegmentsForDay(date);
});

/// 指定期間の歩数レコード (T-503)。同期完了で再評価される。
final stepsProvider = Provider.family<List<StepsRecordModel>, DateRange>((
  ref,
  range,
) {
  ref.watch(syncNotifierProvider);
  return ref
      .watch(healthSyncRepositoryProvider)
      .getStepsForRange(range.start, range.end);
});

/// 指定期間の心拍時系列 (T-503)。クロスデータ統合の時間境界フィルタにも用いる。
final heartRateProvider =
    Provider.family<List<HeartRateRecordModel>, DateRange>((ref, range) {
      ref.watch(syncNotifierProvider);
      return ref
          .watch(healthSyncRepositoryProvider)
          .getHeartRateForRange(range.start, range.end);
    });
