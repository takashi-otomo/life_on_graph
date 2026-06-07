import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';
import 'sync_notifier.dart';

/// 指定月 ([monthStart] の年月) にデータがある日 (日付のみ) の集合 (#104)。
///
/// カレンダーのデータ有無インジケータ用。同期/削除で再評価される
/// ([dataRevisionProvider] を watch)。表示中の月の範囲のみ走査する。
final calendarDataDaysProvider = Provider.family<Set<DateTime>, DateTime>((
  ref,
  monthStart,
) {
  ref.watch(dataRevisionProvider);
  final repo = ref.watch(healthSyncRepositoryProvider);
  final DateTime start = DateTime(monthStart.year, monthStart.month);
  final DateTime end = DateTime(monthStart.year, monthStart.month + 1);
  return repo.daysWithData(start, end);
});
