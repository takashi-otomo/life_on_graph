import 'package:flutter/material.dart';

import '../core/app_colors.dart';

/// カプセル型ボトムタブの 1 項目。
class CapsuleTabItem {
  const CapsuleTabItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

/// フローティングのカプセル型ボトムナビゲーション (#66, デザイン準拠)。
class CapsuleTabBar extends StatelessWidget {
  const CapsuleTabBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<CapsuleTabItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 60,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(30),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x1F0F172A),
              blurRadius: 20,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            for (int i = 0; i < items.length; i++)
              Expanded(
                child: _TabButton(
                  item: items[i],
                  selected: i == currentIndex,
                  onTap: () => onTap(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CapsuleTabItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? AppColors.accent : AppColors.textMuted;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? AppColors.accentSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(item.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
