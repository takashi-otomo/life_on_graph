import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_colors.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/tutorial_provider.dart';
import 'tutorial_keys.dart';

typedef _Step = ({GlobalKey key, String title, String body, double radius});

/// 初回チュートリアル (#109): 主要機能をスポットライトで順に説明する。
///
/// 各ステップで対象ウィジェット ([TutorialKeys]) の矩形を測り、周囲を暗転して
/// ハイライトし、近傍に説明カードを表示する。スキップ/完了で
/// [tutorialCompletedProvider] を記録し [onFinish] を呼ぶ。
class TutorialOverlay extends ConsumerStatefulWidget {
  const TutorialOverlay({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  ConsumerState<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends ConsumerState<TutorialOverlay> {
  int _step = 0;

  @override
  void initState() {
    super.initState();
    // 対象ウィジェットのレイアウト確定後に矩形を取り直す。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  Rect? _rectFor(GlobalKey key) {
    final BuildContext? ctx = key.currentContext;
    if (ctx == null) return null;
    final RenderObject? ro = ctx.findRenderObject();
    if (ro is! RenderBox || !ro.attached) return null;
    return ro.localToGlobal(Offset.zero) & ro.size;
  }

  Future<void> _finish() async {
    await ref.read(tutorialCompletedProvider.notifier).complete();
    widget.onFinish();
  }

  void _next(int total) {
    if (_step >= total - 1) {
      _finish();
    } else {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l = AppLocalizations.of(context);
    final List<_Step> steps = <_Step>[
      (
        key: TutorialKeys.dateNav,
        title: l.tutDateTitle,
        body: l.tutDateBody,
        radius: 14,
      ),
      (
        key: TutorialKeys.cards,
        title: l.tutCardsTitle,
        body: l.tutCardsBody,
        radius: 18,
      ),
      (
        key: TutorialKeys.tabBar,
        title: l.tutTabsTitle,
        body: l.tutTabsBody,
        radius: 30,
      ),
    ];
    final _Step step = steps[_step];
    final Rect? target = _rectFor(step.key);
    final Size screen = MediaQuery.of(context).size;
    final bool isLast = _step == steps.length - 1;

    // 対象が上半分なら下に、下半分なら上にカードを置く。target 未取得時は中央寄せ。
    final bool below = target != null && target.center.dy < screen.height / 2;
    final double? cardTop = target == null
        ? screen.height * 0.4
        : (below ? target.bottom + 14 : null);
    final double? cardBottom = (target != null && !below)
        ? screen.height - target.top + 14
        : null;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: <Widget>[
          // 暗転 + スポットライト。タップは吸収する。
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: CustomPaint(
                painter: _SpotlightPainter(target: target, radius: step.radius),
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            top: cardTop,
            bottom: cardBottom,
            child: _TipCard(
              title: step.title,
              body: step.body,
              stepIndex: _step,
              stepCount: steps.length,
              isLast: isLast,
              skipLabel: l.tutSkip,
              nextLabel: isLast ? l.tutDone : l.onbNext,
              onSkip: _finish,
              onNext: () => _next(steps.length),
            ),
          ),
        ],
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  _SpotlightPainter({required this.target, required this.radius});

  final Rect? target;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect full = Offset.zero & size;
    final Paint dim = Paint()..color = const Color(0xCC0F172A);
    if (target == null) {
      canvas.drawRect(full, dim);
      return;
    }
    final RRect hole = RRect.fromRectAndRadius(
      target!.inflate(6),
      Radius.circular(radius),
    );
    final Path path = Path.combine(
      PathOperation.difference,
      Path()..addRect(full),
      Path()..addRRect(hole),
    );
    canvas.drawPath(path, dim);
    canvas.drawRRect(
      hole,
      Paint()
        ..color = AppColors.accentText
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.target != target || old.radius != radius;
}

class _TipCard extends StatelessWidget {
  const _TipCard({
    required this.title,
    required this.body,
    required this.stepIndex,
    required this.stepCount,
    required this.isLast,
    required this.skipLabel,
    required this.nextLabel,
    required this.onSkip,
    required this.onNext,
  });

  final String title;
  final String body;
  final int stepIndex;
  final int stepCount;
  final bool isLast;
  final String skipLabel;
  final String nextLabel;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onSkip,
                child: Text(
                  skipLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
              Row(
                children: <Widget>[
                  for (int i = 0; i < stepCount; i++)
                    Container(
                      margin: const EdgeInsets.only(right: 5),
                      width: i == stepIndex ? 16 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i == stepIndex
                            ? AppColors.accent
                            : AppColors.divider,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        nextLabel,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
