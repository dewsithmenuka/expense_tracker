import 'package:flutter/material.dart';

import '../utils/app_style.dart';
import 'app_logo.dart';

/// The intro shown when the app opens. Calls [onFinished] when done.
/// If [animate] is false it just shows the final frame straight away.
class AnimatedSplash extends StatefulWidget {
  final bool animate;
  final VoidCallback? onFinished;

  const AnimatedSplash({super.key, this.animate = true, this.onFinished});

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash>
    with SingleTickerProviderStateMixin {
  static const double _logoSize = 120;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  // Logo: bounce in + one full clockwise spin + fade in
  late final Animation<double> _scale = Tween<double>(begin: 0, end: 1).animate(
    CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.55, curve: Curves.elasticOut),
    ),
  );
  late final Animation<double> _turns =
      Tween<double>(begin: -1, end: 0).animate(
    CurvedAnimation(
      parent: _c,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ),
  );
  late final Animation<double> _logoFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.0, 0.15),
  );

  // Two rings that pulse outward after the logo lands
  late final Animation<double> _ring1 = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.45, 0.90, curve: Curves.easeOut),
  );
  late final Animation<double> _ring2 = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.55, 1.0, curve: Curves.easeOut),
  );

  // Text
  late final Animation<double> _titleFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.55, 0.85),
  );
  late final Animation<Offset> _titleSlide =
      Tween<Offset>(begin: const Offset(0, 0.6), end: Offset.zero).animate(
    CurvedAnimation(
      parent: _c,
      curve: const Interval(0.55, 0.85, curve: Curves.easeOutCubic),
    ),
  );
  late final Animation<double> _taglineFade = CurvedAnimation(
    parent: _c,
    curve: const Interval(0.70, 1.0),
  );

  bool _started = false;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (!widget.animate) {
      _c.value = 1; // show the finished frame, never call onFinished
      return;
    }
    if (MediaQuery.of(context).disableAnimations) {
      // The phone asked for reduced motion: skip the show.
      _c.value = 1;
      _finish(600);
      return;
    }
    _c.forward().whenComplete(() => _finish());
  }

  /// Waits a beat on the final frame, then tells the parent (only once).
  Future<void> _finish([int holdMs = 350]) async {
    if (_done) return;
    await Future.delayed(Duration(milliseconds: holdMs));
    if (!mounted || _done) return;
    _done = true;
    widget.onFinished?.call();
  }

  void _skip() {
    if (!widget.animate || _done) return;
    _c.value = 1;
    _finish(0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Widget _ring(Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final t = animation.value;
        if (t <= 0 || t >= 1) return const SizedBox.shrink();
        final alpha = (170 * (1 - t)).round().clamp(0, 255).toInt();
        final diameter = _logoSize * (1 + 0.85 * t);
        return Container(
          width: diameter,
          height: diameter,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withAlpha(alpha), width: 3),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _skip,
        child: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.brand),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const Positioned(right: -70, top: -70, child: _Bubble(240)),
              const Positioned(left: -60, bottom: -80, child: _Bubble(200)),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 240,
                      height: 240,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          _ring(_ring1),
                          _ring(_ring2),
                          FadeTransition(
                            opacity: _logoFade,
                            child: ScaleTransition(
                              scale: _scale,
                              child: RotationTransition(
                                turns: _turns,
                                child: const AppLogo(
                                  size: _logoSize,
                                  onDark: true,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: _titleFade,
                      child: SlideTransition(
                        position: _titleSlide,
                        child: const Text(
                          'Expense Tracker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FadeTransition(
                      opacity: _taglineFade,
                      child: const Text(
                        'Know where your money goes',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final double size;
  const _Bubble(this.size);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white10),
    );
  }
}