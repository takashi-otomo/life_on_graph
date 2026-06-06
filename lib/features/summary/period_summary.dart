// サマリー画面の期間集計 (#67 / #68, 純粋計算)。

/// 集計期間。
enum SummaryPeriod { day, week, month }

/// 1 日分の集計値 (各データ種別の代表値)。
class DaySummary {
  const DaySummary({
    required this.date,
    required this.sleep,
    required this.steps,
    this.hrAvg,
    this.hrResting,
  });

  final DateTime date;
  final Duration sleep;
  final int steps;
  final int? hrAvg;
  final int? hrResting;

  static DaySummary empty(DateTime date) =>
      DaySummary(date: date, sleep: Duration.zero, steps: 0);
}

/// トレンドチャートの 1 本。
class TrendBar {
  const TrendBar({
    required this.label,
    required this.sleepHours,
    required this.steps,
    this.highlighted = false,
  });

  final String label;
  final double sleepHours;
  final int steps;

  /// 「今日」など強調表示するか (日表示の最終バー)。
  final bool highlighted;
}

/// 期間サマリー: KPI(平均) + 前期間比 + トレンドバー。
class PeriodSummary {
  const PeriodSummary({
    required this.period,
    required this.avgSleep,
    required this.avgSteps,
    required this.avgHr,
    required this.restingHr,
    required this.bars,
    required this.sleepDeltaMinutes,
    required this.stepsDeltaPercent,
    required this.hrDelta,
  });

  final SummaryPeriod period;

  /// 平均睡眠時間 (期間内の有効日平均、日表示は当日値)。
  final Duration avgSleep;

  /// 平均歩数 (期間内の有効日平均、日表示は当日値)。
  final int avgSteps;

  /// 平均心拍 (有効日の平均)。
  final int? avgHr;

  /// 安静時心拍 (期間内の最小)。
  final int? restingHr;

  /// トレンドバー列。
  final List<TrendBar> bars;

  /// 前期間比: 睡眠の差 (分)。両期間にデータが無ければ `null` (比較不能)。
  final int? sleepDeltaMinutes;

  /// 前期間比: 歩数の差 (%)。両期間にデータが無ければ `null`。
  final int? stepsDeltaPercent;

  /// 前期間比: 平均心拍の差 (bpm)。両期間にデータが無ければ `null`。
  final int? hrDelta;

  /// 指定 [period] / [anchor] について、各日の集計を [read] で取得して構築する。
  ///
  /// [now] は「今日」判定の基準 (省略時は現在日)。
  factory PeriodSummary.build({
    required SummaryPeriod period,
    required DateTime anchor,
    required DaySummary Function(DateTime day) read,
    DateTime? now,
  }) {
    final DateTime today = now == null
        ? _Range._d(DateTime.now())
        : _Range._d(now);
    final _Range range = _Range.of(period, anchor, today);
    final List<DaySummary> current = range.kpiDays.map(read).toList();
    final List<DaySummary> previous = range.prevDays.map(read).toList();
    final List<TrendBar> bars = range.buildBars(read);

    final _Kpi cur = _Kpi.from(current);
    final _Kpi prev = _Kpi.from(previous);

    // 差分は両期間に有効データがある場合のみ算出する (欠損で偽の比較を作らない)。
    final int? sleepDelta = (cur.hasSleep && prev.hasSleep)
        ? cur.avgSleep.inMinutes - prev.avgSleep.inMinutes
        : null;
    final int? stepsDelta = (cur.hasSteps && prev.hasSteps && prev.avgSteps > 0)
        ? (((cur.avgSteps - prev.avgSteps) / prev.avgSteps) * 100).round()
        : null;
    final int? hrDelta = (cur.avgHr != null && prev.avgHr != null)
        ? cur.avgHr! - prev.avgHr!
        : null;

    return PeriodSummary(
      period: period,
      avgSleep: cur.avgSleep,
      avgSteps: cur.avgSteps,
      avgHr: cur.avgHr,
      restingHr: cur.restingHr,
      bars: bars,
      sleepDeltaMinutes: sleepDelta,
      stepsDeltaPercent: stepsDelta,
      hrDelta: hrDelta,
    );
  }
}

/// 集計の中間値 (平均・安静)。
class _Kpi {
  _Kpi(
    this.avgSleep,
    this.avgSteps,
    this.avgHr,
    this.restingHr, {
    this.hasSleep = false,
    this.hasSteps = false,
  });

  final Duration avgSleep;
  final int avgSteps;
  final int? avgHr;
  final int? restingHr;

  /// 期間内に睡眠データのある日があったか (前期間比の有効性判定用)。
  final bool hasSleep;

  /// 期間内に歩数データのある日があったか。
  final bool hasSteps;

  factory _Kpi.from(List<DaySummary> days) {
    if (days.isEmpty) {
      return _Kpi(Duration.zero, 0, null, null);
    }
    // 睡眠/歩数は「データのある日」で平均する (空日で薄まらないように)。
    final List<DaySummary> sleptDays = days
        .where((d) => d.sleep > Duration.zero)
        .toList();
    final List<DaySummary> stepDays = days.where((d) => d.steps > 0).toList();
    final List<int> hrAvgs = <int>[
      for (final d in days)
        if (d.hrAvg != null) d.hrAvg!,
    ];
    final List<int> restings = <int>[
      for (final d in days)
        if (d.hrResting != null) d.hrResting!,
    ];

    final Duration avgSleep = sleptDays.isEmpty
        ? Duration.zero
        : Duration(
            minutes:
                (sleptDays.fold(0, (a, d) => a + d.sleep.inMinutes) /
                        sleptDays.length)
                    .round(),
          );
    final int avgSteps = stepDays.isEmpty
        ? 0
        : (stepDays.fold(0, (a, d) => a + d.steps) / stepDays.length).round();
    final int? avgHr = hrAvgs.isEmpty
        ? null
        : (hrAvgs.fold(0, (a, b) => a + b) / hrAvgs.length).round();
    final int? resting = restings.isEmpty
        ? null
        : restings.reduce((a, b) => a < b ? a : b);
    return _Kpi(
      avgSleep,
      avgSteps,
      avgHr,
      resting,
      hasSleep: sleptDays.isNotEmpty,
      hasSteps: stepDays.isNotEmpty,
    );
  }
}

/// 期間の日付列・バー構成を決める内部ヘルパ。
class _Range {
  _Range({
    required this.kpiDays,
    required this.prevDays,
    required this.buildBars,
  });

  /// KPI 集計対象日。
  final List<DateTime> kpiDays;

  /// 前期間の集計対象日 (前期間比用)。
  final List<DateTime> prevDays;

  /// トレンドバーを構築する関数。
  final List<TrendBar> Function(DaySummary Function(DateTime)) buildBars;

  static const List<String> _wd = <String>['月', '火', '水', '木', '金', '土', '日'];

  static DateTime _d(DateTime x) => DateTime(x.year, x.month, x.day);

  factory _Range.of(SummaryPeriod period, DateTime anchor, DateTime today) {
    final DateTime a = _d(anchor);
    switch (period) {
      case SummaryPeriod.day:
        return _Range(
          kpiDays: <DateTime>[a],
          prevDays: <DateTime>[a.subtract(const Duration(days: 1))],
          buildBars: (read) {
            // 過去 7 日 (anchor を最終・強調)。anchor が実際の今日のときのみ
            // 「今日」と表示し、過去日を閲覧中は曜日ラベルにする。
            final List<DateTime> days = <DateTime>[
              for (int i = 6; i >= 0; i--) a.subtract(Duration(days: i)),
            ];
            return <TrendBar>[
              for (int i = 0; i < days.length; i++)
                _bar(
                  read(days[i]),
                  label: (i == days.length - 1 && days[i] == today)
                      ? '今日'
                      : _wd[days[i].weekday - 1],
                  highlighted: i == days.length - 1,
                ),
            ];
          },
        );
      case SummaryPeriod.week:
        final DateTime weekStart = a.subtract(
          Duration(days: a.weekday - 1),
        ); // 月曜
        final List<DateTime> week = <DateTime>[
          for (int i = 0; i < 7; i++) weekStart.add(Duration(days: i)),
        ];
        final List<DateTime> prevWeek = <DateTime>[
          for (int i = 0; i < 7; i++) weekStart.subtract(Duration(days: 7 - i)),
        ];
        return _Range(
          kpiDays: week,
          prevDays: prevWeek,
          buildBars: (read) => <TrendBar>[
            for (int i = 0; i < 7; i++) _bar(read(week[i]), label: _wd[i]),
          ],
        );
      case SummaryPeriod.month:
        final DateTime monthStart = DateTime(a.year, a.month, 1);
        final DateTime nextMonth = DateTime(a.year, a.month + 1, 1);
        final int days = nextMonth.difference(monthStart).inDays;
        final List<DateTime> monthDays = <DateTime>[
          for (int i = 0; i < days; i++) monthStart.add(Duration(days: i)),
        ];
        final DateTime prevMonthStart = DateTime(a.year, a.month - 1, 1);
        final int prevDays = monthStart.difference(prevMonthStart).inDays;
        final List<DateTime> prevMonthDays = <DateTime>[
          for (int i = 0; i < prevDays; i++)
            prevMonthStart.add(Duration(days: i)),
        ];
        return _Range(
          kpiDays: monthDays,
          prevDays: prevMonthDays,
          buildBars: (read) {
            // 暦週 (月曜始まり) でロールアップする。月初の部分週を 1 週目とし、
            // 以降は月〜日の暦週で区切る (週表示と境界を揃える)。
            final List<TrendBar> bars = <TrendBar>[];
            final List<List<DaySummary>> weeks = <List<DaySummary>>[];
            DateTime? curWeekStart;
            for (final DateTime day in monthDays) {
              final DateTime ws = day.subtract(Duration(days: day.weekday - 1));
              if (curWeekStart == null || ws != curWeekStart) {
                curWeekStart = ws;
                weeks.add(<DaySummary>[]);
              }
              weeks.last.add(read(day));
            }
            for (int w = 0; w < weeks.length; w++) {
              final List<DaySummary> chunk = weeks[w];
              final List<DaySummary> slept = chunk
                  .where((d) => d.sleep > Duration.zero)
                  .toList();
              final double avgH = slept.isEmpty
                  ? 0
                  : slept.fold(0, (a, d) => a + d.sleep.inMinutes) /
                        slept.length /
                        60;
              final int sumSteps = chunk.fold(0, (a, d) => a + d.steps);
              bars.add(
                TrendBar(label: '${w + 1}週', sleepHours: avgH, steps: sumSteps),
              );
            }
            return bars;
          },
        );
    }
  }

  static TrendBar _bar(
    DaySummary d, {
    required String label,
    bool highlighted = false,
  }) => TrendBar(
    label: label,
    sleepHours: d.sleep.inMinutes / 60,
    steps: d.steps,
    highlighted: highlighted,
  );
}
