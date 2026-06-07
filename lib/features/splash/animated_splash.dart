import 'package:flutter/material.dart';

import '../../core/app_colors.dart';

/// 起動時のアニメーションスプラッシュ。
///
/// ロゴ(心拍ラインが描かれる)→ 略称「LOG」→ 正式名称「Life On Graph」の順に
/// アニメーション表示し、完了時に [onAnimationEnd] を呼ぶ。総時間は約 0.7 秒。
class AnimatedSplash extends StatefulWidget {
  const AnimatedSplash({
    super.key,
    required this.onAnimationEnd,
    this.duration = const Duration(milliseconds: 700),
  });

  /// アニメーション完了時に呼ばれる。
  final VoidCallback onAnimationEnd;
  final Duration duration;

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _pulse;
  late final Animation<double> _abbr;
  late final Animation<double> _name;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener((AnimationStatus status) {
        if (status == AnimationStatus.completed) widget.onAnimationEnd();
      });
    _logoScale = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
      ),
    );
    _logoOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.4),
    );
    _pulse = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 0.65, curve: Curves.easeInOut),
    );
    _abbr = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.35, 0.75, curve: Curves.easeOut),
    );
    _name = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (BuildContext context, Widget? child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Opacity(
                  opacity: _logoOpacity.value.clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: _logoScale.value,
                    child: SizedBox(
                      width: 96,
                      height: 96,
                      child: CustomPaint(
                        painter: _SplashLogoPainter(_pulse.value),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Opacity(
                  opacity: _abbr.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - _abbr.value)),
                    child: const Text(
                      'LOG',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 6,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Opacity(
                  opacity: _name.value.clamp(0.0, 1.0),
                  child: const Text(
                    'Life On Graph',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// インディゴ角丸 + 進捗 [progress] (0..1) に応じて描かれる心拍ライン。
class _SplashLogoPainter extends CustomPainter {
  _SplashLogoPainter(this.progress);

  final double progress;

  // ユニット座標 (0..1) の心拍ライン頂点。
  static const List<Offset> _pts = <Offset>[
    Offset(0.12, 0.55),
    Offset(0.30, 0.55),
    Offset(0.37, 0.55),
    Offset(0.44, 0.40),
    Offset(0.52, 0.72),
    Offset(0.62, 0.28),
    Offset(0.70, 0.55),
    Offset(0.80, 0.55),
    Offset(0.86, 0.47),
    Offset(0.92, 0.47),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    // 背景の角丸スクエア (インディゴグラデ)。
    final RRect bg = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(w * 0.28),
    );
    canvas.drawRRect(
      bg,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFF4338CA), Color(0xFF6366F1)],
        ).createShader(Offset.zero & size),
    );

    // 心拍ライン (進捗まで描画)。
    final Path full = Path()
      ..moveTo(_pts.first.dx * w, _pts.first.dy * size.height);
    for (final Offset p in _pts.skip(1)) {
      full.lineTo(p.dx * w, p.dy * size.height);
    }
    final Path drawn = Path();
    for (final m in full.computeMetrics()) {
      drawn.addPath(
        m.extractPath(0, m.length * progress.clamp(0.0, 1.0)),
        Offset.zero,
      );
    }
    canvas.drawPath(
      drawn,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.06
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // 末端の赤ドット (描画完了間際で出現)。
    if (progress > 0.8) {
      final double dotOpacity = ((progress - 0.8) / 0.2).clamp(0.0, 1.0);
      canvas.drawCircle(
        Offset(_pts.last.dx * w, _pts.last.dy * size.height),
        w * 0.05,
        Paint()..color = AppColors.heart.withValues(alpha: dotOpacity),
      );
    }
  }

  @override
  bool shouldRepaint(_SplashLogoPainter old) => old.progress != progress;
}
