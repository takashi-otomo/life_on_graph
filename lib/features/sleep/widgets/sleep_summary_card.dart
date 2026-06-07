import 'package:flutter/material.dart';

import '../../../core/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../widgets/app_card.dart';
import '../sleep_summary.dart';

/// 睡眠サマリーカード: 合計時間 + ステージ比率バー + 凡例 (#35)。
class SleepSummaryCard extends StatelessWidget {
  const SleepSummaryCard({super.key, required this.summary});

  final SleepSummary summary;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<({String key, String label})> stages =
        <({String key, String label})>[
          (key: 'deep', label: l.stageDeep),
          (key: 'light', label: l.stageLight),
          (key: 'rem', label: l.stageRem),
          (key: 'awake', label: l.stageAwake),
          (key: 'unknown', label: l.stageUnknown),
        ];
    final List<({String key, String label})> present = stages
        .where((s) => summary.stage(s.key) > Duration.zero)
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.bedtime,
                    size: 20,
                    color: AppColors.sleepDeep,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l.sleep,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              Text(
                summary.isEmpty ? '—' : formatHm(summary.total, l),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (present.isEmpty)
            Text(
              l.noSleepDataForDay,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            )
          else ...<Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: SizedBox(
                height: 14,
                child: Row(
                  children: <Widget>[
                    for (final s in present)
                      Expanded(
                        flex: (summary.ratio(s.key) * 1000).round().clamp(
                          1,
                          1000,
                        ),
                        child: ColoredBox(color: AppColors.sleepStage(s.key)),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                for (final s in present)
                  _LegendItem(
                    color: AppColors.sleepStage(s.key),
                    label: s.label,
                    duration: formatHm(summary.stage(s.key), l),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.duration,
  });

  final Color color;
  final String label;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          duration,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
