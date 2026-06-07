import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// カレンダーピッカーの選択単位 (#101)。
enum CalendarMode { day, week, month }

/// アプリのテイストを踏襲した独自カレンダーをボトムシートで表示し、選択日を返す。
///
/// [initial] は初期選択、[last] は選択可能な最終日 (通常は今日。未来は選択不可)。
/// 返値は day/week では選択日、month では選択月の 1 日。キャンセル時は `null`。
Future<DateTime?> showCalendarPicker(
  BuildContext context, {
  required CalendarMode mode,
  required DateTime initial,
  required DateTime last,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _CalendarSheet(mode: mode, initial: initial, last: last),
  );
}

DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

class _CalendarSheet extends StatefulWidget {
  const _CalendarSheet({
    required this.mode,
    required this.initial,
    required this.last,
  });

  final CalendarMode mode;
  final DateTime initial;
  final DateTime last;

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  /// 表示中の基準 (day/week は月、month は年)。
  late DateTime _visible = DateTime(widget.initial.year, widget.initial.month);

  bool get _isMonth => widget.mode == CalendarMode.month;

  void _shiftMonth(int d) =>
      setState(() => _visible = DateTime(_visible.year, _visible.month + d));
  void _shiftYear(int d) =>
      setState(() => _visible = DateTime(_visible.year + d, _visible.month));

  /// 翌(月/年)へ進めるか (最終日を超えない範囲)。
  bool get _canNext {
    if (_isMonth) return _visible.year < widget.last.year;
    final DateTime nextMonth = DateTime(_visible.year, _visible.month + 1);
    return !nextMonth.isAfter(DateTime(widget.last.year, widget.last.month));
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final String locale = Localizations.localeOf(context).toString();
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _nav(locale),
          const SizedBox(height: 14),
          if (_isMonth) _monthGrid(locale) else _dayCalendar(locale),
          const SizedBox(height: 14),
          _jumpButton(l),
        ],
      ),
    );
  }

  Widget _nav(String locale) {
    final String label = _isMonth
        ? DateFormat.y(locale).format(_visible)
        : DateFormat.yMMMM(locale).format(_visible);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _circleBtn(Icons.chevron_left, () {
          _isMonth ? _shiftYear(-1) : _shiftMonth(-1);
        }, enabled: true),
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        _circleBtn(Icons.chevron_right, () {
          _isMonth ? _shiftYear(1) : _shiftMonth(1);
        }, enabled: _canNext),
      ],
    );
  }

  Widget _circleBtn(
    IconData icon,
    VoidCallback onTap, {
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: Color(0xFFF1F5F9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? const Color(0xFF475569) : AppColors.divider,
        ),
      ),
    );
  }

  Widget _dayCalendar(String locale) {
    // 月曜始まりの曜日ヘッダ。
    final DateTime mondayRef = DateTime(2024, 1); // 2024-01-01 は月曜。
    final List<String> weekdays = <String>[
      for (int i = 0; i < 7; i++)
        DateFormat.E(locale).format(mondayRef.add(Duration(days: i))),
    ];
    final DateTime first = DateTime(_visible.year, _visible.month);
    final int lead = first.weekday - 1; // Mon=0..Sun=6
    final int daysInMonth = DateTime(_visible.year, _visible.month + 1, 0).day;
    final DateTime selWeekStart = _d(
      widget.initial,
    ).subtract(Duration(days: widget.initial.weekday - 1));

    final List<Widget> cells = <Widget>[];
    for (int i = 0; i < lead; i++) {
      cells.add(const Expanded(child: SizedBox(height: 40)));
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final DateTime date = DateTime(_visible.year, _visible.month, day);
      final bool future = date.isAfter(_d(widget.last));
      final bool selectedDay =
          widget.mode == CalendarMode.day && date == _d(widget.initial);
      final bool inSelWeek =
          widget.mode == CalendarMode.week &&
          !date.isBefore(selWeekStart) &&
          date.isBefore(selWeekStart.add(const Duration(days: 7)));
      cells.add(
        Expanded(
          child: _DayCell(
            day: day,
            selected: selectedDay,
            inWeek: inSelWeek,
            future: future,
            onTap: future ? null : () => Navigator.pop(context, date),
          ),
        ),
      );
    }
    while (cells.length % 7 != 0) {
      cells.add(const Expanded(child: SizedBox(height: 40)));
    }

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final String w in weekdays)
              Expanded(
                child: Center(
                  child: Text(
                    w,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        for (int r = 0; r * 7 < cells.length; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(children: cells.sublist(r * 7, r * 7 + 7)),
          ),
      ],
    );
  }

  Widget _monthGrid(String locale) {
    final DateTime lastMonth = DateTime(widget.last.year, widget.last.month);
    return Column(
      children: <Widget>[
        for (int r = 0; r < 4; r++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: <Widget>[
                for (int c = 0; c < 3; c++) ...<Widget>[
                  if (c > 0) const SizedBox(width: 10),
                  Expanded(
                    child: Builder(
                      builder: (_) {
                        final int m = r * 3 + c + 1;
                        final DateTime month = DateTime(_visible.year, m);
                        final bool future = month.isAfter(lastMonth);
                        final bool selected =
                            _visible.year == widget.initial.year &&
                            m == widget.initial.month;
                        return _MonthCell(
                          label: DateFormat.MMM(
                            locale,
                          ).format(DateTime(_visible.year, m)),
                          selected: selected,
                          future: future,
                          onTap: future
                              ? null
                              : () => Navigator.pop(context, month),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _jumpButton(AppLocalizations l) {
    return GestureDetector(
      onTap: () {
        final DateTime now = DateTime.now();
        // last より後 (日跨ぎ等で now が last を超えた場合) は last にクランプする。
        if (_isMonth) {
          final DateTime nowM = DateTime(now.year, now.month);
          final DateTime lastM = DateTime(widget.last.year, widget.last.month);
          Navigator.pop(context, nowM.isAfter(lastM) ? lastM : nowM);
        } else {
          final DateTime nowD = _d(now);
          final DateTime lastD = _d(widget.last);
          Navigator.pop(context, nowD.isAfter(lastD) ? lastD : nowD);
        }
      },
      child: Container(
        height: 44,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.accentSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Text(
          _isMonth ? l.jumpThisMonth : l.jumpToday,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.inWeek,
    required this.future,
    required this.onTap,
  });

  final int day;
  final bool selected;
  final bool inWeek;
  final bool future;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 40,
        child: Center(
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accent
                  : (inWeek ? AppColors.accentSoft : Colors.transparent),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 14,
                fontWeight: (selected || inWeek)
                    ? FontWeight.w700
                    : FontWeight.w500,
                color: selected
                    ? Colors.white
                    : future
                    ? AppColors.divider
                    : (inWeek ? AppColors.accent : AppColors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.label,
    required this.selected,
    required this.future,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool future;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected
                ? Colors.white
                : future
                ? AppColors.divider
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
