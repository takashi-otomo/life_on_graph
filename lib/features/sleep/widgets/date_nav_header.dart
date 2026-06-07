import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/app_colors.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/selected_date_provider.dart';

/// 日付ナビゲーション (前日 / 翌日 / 今日表示) (#41)。
class DateNavHeader extends ConsumerWidget {
  const DateNavHeader({super.key});

  /// ロケールに応じた日付表記 (年込み: "2026年6月7日(土)" / "Sat, Jun 7, 2026" 等)。
  static String formatDate(DateTime d, String localeName) =>
      DateFormat.yMMMEd(localeName).format(d);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DateTime date = ref.watch(selectedDateProvider);
    final SelectedDateNotifier nav = ref.read(selectedDateProvider.notifier);
    final bool isToday = nav.isToday;
    final AppLocalizations l = AppLocalizations.of(context);
    final String localeName = Localizations.localeOf(context).toString();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _CircleButton(
            icon: Icons.chevron_left,
            onTap: nav.previous,
            tooltip: l.prevDay,
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                formatDate(date, localeName),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              if (isToday)
                Text(
                  l.today,
                  style: const TextStyle(
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
            tooltip: l.nextDay,
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
