import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../providers/nav_provider.dart';
import '../../providers/selected_date_provider.dart';
import '../../providers/summary_providers.dart';
import '../../widgets/health_status_banner.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/segmented_toggle.dart';
import '../sleep/sleep_summary.dart';
import '../sleep/widgets/date_nav_header.dart';
import 'period_summary.dart';
import 'widgets/trend_bar_chart.dart';

/// サマリー画面 (日/週/月トレンド) (#67 / #68)。
class SummaryView extends ConsumerStatefulWidget {
  const SummaryView({super.key});

  @override
  ConsumerState<SummaryView> createState() => _SummaryViewState();
}

class _SummaryViewState extends ConsumerState<SummaryView> {
  SummaryPeriod _period = SummaryPeriod.week;
  DateTime _anchor = _today();

  static DateTime _today() {
    final DateTime n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  bool get _atLatest {
    switch (_period) {
      case SummaryPeriod.day:
        return !_anchor.isBefore(_today());
      case SummaryPeriod.week:
        return !_anchor.isBefore(
          _today().subtract(Duration(days: _today().weekday - 1)),
        );
      case SummaryPeriod.month:
        return _anchor.year == _today().year && _anchor.month == _today().month;
    }
  }

  void _shift(int dir) {
    setState(() {
      switch (_period) {
        case SummaryPeriod.day:
          _anchor = DateTime(_anchor.year, _anchor.month, _anchor.day + dir);
        case SummaryPeriod.week:
          _anchor = DateTime(
            _anchor.year,
            _anchor.month,
            _anchor.day + dir * 7,
          );
        case SummaryPeriod.month:
          _anchor = DateTime(_anchor.year, _anchor.month + dir, 1);
      }
    });
  }

  String _periodLabel() {
    switch (_period) {
      case SummaryPeriod.day:
        return DateNavHeader.formatDate(_anchor);
      case SummaryPeriod.week:
        final DateTime start = _anchor.subtract(
          Duration(days: _anchor.weekday - 1),
        );
        final DateTime end = start.add(const Duration(days: 6));
        return '${start.month}月${start.day}日 - ${end.month}月${end.day}日';
      case SummaryPeriod.month:
        return '${_anchor.year}年 ${_anchor.month}月';
    }
  }

  String _deltaLabelPrefix() => switch (_period) {
    SummaryPeriod.day => '前日比',
    SummaryPeriod.week => '先週比',
    SummaryPeriod.month => '先月比',
  };

  @override
  Widget build(BuildContext context) {
    final PeriodSummary s = ref.watch(
      periodSummaryProvider(SummaryQuery(_period, _anchor)),
    );
    final String dp = _deltaLabelPrefix();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          children: <Widget>[
            const Text(
              'サマリー',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),
            SegmentedToggle(
              segments: const <String>['日', '週', '月'],
              selectedIndex: _period.index,
              expand: true,
              onChanged: (i) => setState(() {
                _period = SummaryPeriod.values[i];
                _anchor = _today();
              }),
            ),
            const SizedBox(height: 14),
            _PeriodNav(
              label: _periodLabel(),
              onPrev: () => _shift(-1),
              onNext: _atLatest ? null : () => _shift(1),
            ),
            const SizedBox(height: 16),
            const HealthStatusBanner(),
            _MetricGrid(summary: s, deltaPrefix: dp),
            const SizedBox(height: 12),
            if (_period == SummaryPeriod.day) ...<Widget>[
              _DetailCta(
                onTap: () {
                  ref.read(selectedDateProvider.notifier).select(_anchor);
                  ref.read(navTabProvider.notifier).select(0);
                },
              ),
              const SizedBox(height: 12),
            ],
            TrendBarChart(
              title: '睡眠時間',
              icon: Icons.bedtime,
              color: AppColors.sleepLight,
              bars: s.bars,
              value: (b) => b.sleepHours,
            ),
            const SizedBox(height: 12),
            TrendBarChart(
              title: '歩数',
              icon: Icons.directions_walk,
              color: AppColors.steps,
              bars: s.bars,
              value: (b) => b.steps.toDouble(),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.summary, required this.deltaPrefix});

  final PeriodSummary summary;
  final String deltaPrefix;

  @override
  Widget build(BuildContext context) {
    final int? sleepD = summary.sleepDeltaMinutes;
    final int? stepD = summary.stepsDeltaPercent;
    final int? hrD = summary.hrDelta;

    final List<Widget> cards = <Widget>[
      MetricCard(
        icon: Icons.bedtime,
        iconColor: AppColors.sleepDeep,
        label: '平均睡眠',
        value: summary.avgSleep == Duration.zero
            ? '—'
            : formatHm(summary.avgSleep),
        trend: _trend(sleepD),
        trendLabel: sleepD == null
            ? null
            : '$deltaPrefix ${sleepD >= 0 ? '+' : ''}$sleepD分',
        trendPositive: (sleepD == null || sleepD == 0) ? null : sleepD > 0,
      ),
      MetricCard(
        icon: Icons.directions_walk,
        iconColor: AppColors.steps,
        label: '平均歩数',
        value: summary.avgSteps == 0 ? '—' : '${_fmt(summary.avgSteps)} 歩',
        trend: _trend(stepD),
        trendLabel: stepD == null
            ? null
            : '$deltaPrefix ${stepD >= 0 ? '+' : ''}$stepD%',
        trendPositive: (stepD == null || stepD == 0) ? null : stepD > 0,
      ),
      MetricCard(
        icon: Icons.favorite,
        iconColor: AppColors.heart,
        label: '平均心拍',
        value: summary.avgHr == null ? '—' : '${summary.avgHr} bpm',
        trend: _trend(hrD),
        trendLabel: hrD == null
            ? null
            : '$deltaPrefix ${hrD >= 0 ? '+' : ''}$hrD',
        // 心拍は低下が良い傾向なので down を positive とみなす。
        trendPositive: (hrD == null || hrD == 0) ? null : hrD < 0,
      ),
      MetricCard(
        icon: Icons.monitor_heart,
        iconColor: AppColors.heart,
        label: '安静時心拍',
        value: summary.restingHr == null ? '—' : '${summary.restingHr} bpm',
      ),
    ];

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }

  static MetricTrend _trend(int? d) => (d == null || d == 0)
      ? MetricTrend.flat
      : (d > 0 ? MetricTrend.up : MetricTrend.down);

  static String _fmt(int n) {
    final String s = n.toString();
    final StringBuffer b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
      b.write(s[i]);
    }
    return b.toString();
  }
}

class _PeriodNav extends StatelessWidget {
  const _PeriodNav({required this.label, this.onPrev, this.onNext});

  final String label;
  final VoidCallback? onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        IconButton(
          onPressed: onPrev,
          icon: const Icon(Icons.chevron_left),
          color: AppColors.textSecondary,
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textSecondary,
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          color: onNext == null ? AppColors.divider : AppColors.textSecondary,
        ),
      ],
    );
  }
}

class _DetailCta extends StatelessWidget {
  const _DetailCta({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.dashboard, size: 18, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  '今日の詳細を見る',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            Icon(Icons.chevron_right, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
