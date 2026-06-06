import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 画面が表示対象とする選択日 (日付のみ, #41)。
///
/// 派生プロバイダ (睡眠/歩数/心拍) はこの日付を用いて当日のデータを取得する。
/// 日付ナビゲーション (前日/翌日/今日) で更新される。
class SelectedDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => _today();

  static DateTime _today() {
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  /// 前日へ移動する。
  void previous() => state = DateTime(state.year, state.month, state.day - 1);

  /// 翌日へ移動する (未来日には進めない)。
  void next() {
    final DateTime candidate = DateTime(state.year, state.month, state.day + 1);
    if (!candidate.isAfter(_today())) state = candidate;
  }

  /// 任意の日付に設定する (時刻は切り捨て)。
  void select(DateTime date) =>
      state = DateTime(date.year, date.month, date.day);

  /// 今日へ移動する。
  void today() => state = _today();

  /// 選択日が今日かどうか。
  bool get isToday => state == _today();
}

/// 選択日プロバイダ。
final selectedDateProvider = NotifierProvider<SelectedDateNotifier, DateTime>(
  SelectedDateNotifier.new,
);
