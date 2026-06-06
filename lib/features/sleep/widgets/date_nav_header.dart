import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/app_colors.dart';
import '../../../providers/selected_date_provider.dart';

/// 日付ナビゲーション (前日 / 翌日 / 今日表示) (#41)。
class DateNavHeader extends ConsumerWidget {
  const DateNavHeader({super.key});

  static const List<String> _weekdays = <String>[
    '月',
    '火',
    '水',
    '木',
    '金',
    '土',
    '日',
  ];

  static String formatDate(DateTime d) =>
      '${d.month}月${d.day}日 (${_weekdays[d.weekday - 1]})';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime date = ref.watch(selectedDateProvider);
    final SelectedDateNotifier nav = ref.read(selectedDateProvider.notifier);
    final bool isToday = nav.isToday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _CircleButton(
            icon: Icons.chevron_left,
            onTap: nav.previous,
            tooltip: '前日',
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                formatDate(date),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isToday)
                const Text(
                  '今日',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.accentText,
                  ),
                ),
            ],
          ),
          _CircleButton(
            icon: Icons.chevron_right,
            onTap: isToday ? null : nav.next,
            tooltip: '翌日',
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Tooltip(
      message: tooltip ?? '',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: const BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 22,
            color: enabled ? AppColors.textSecondary : AppColors.divider,
          ),
        ),
      ),
    );
  }
}
