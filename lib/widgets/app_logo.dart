import 'package:flutter/material.dart';

import '../utils/app_style.dart';

/// The app logo: three rising bars with a gold coin on the tallest one.
///
/// [onDark] = true  -> white badge with teal bars (for gradient backgrounds)
/// [onDark] = false -> teal badge with white bars (for light surfaces)
class AppLogo extends StatelessWidget {
  final double size;
  final bool onDark;

  const AppLogo({super.key, this.size = 96, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.26),
        color: onDark ? Colors.white : null,
        gradient: onDark ? null : AppColors.brand,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(onDark ? 60 : 45),
            blurRadius: size * 0.22,
            offset: Offset(0, size * 0.08),
          ),
        ],
      ),
      child: CustomPaint(painter: _LogoPainter(onDark: onDark)),
    );
  }
}

class _LogoPainter extends CustomPainter {
  final bool onDark;
  const _LogoPainter({required this.onDark});

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;

    // Layout, as fractions of the badge size.
    const barWidth = 0.13;
    const gap = 0.07;
    const baseline = 0.78;
    const heights = [0.18, 0.28, 0.40];
    const startX = (1 - (3 * barWidth + 2 * gap)) / 2;

    final barPaint = Paint()
      ..color = onDark ? const Color(0xFF00796B) : Colors.white;

    // Three bars, rounded like pills.
    for (var i = 0; i < heights.length; i++) {
      final x = startX + i * (barWidth + gap);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(
            x * s,
            (baseline - heights[i]) * s,
            (x + barWidth) * s,
            baseline * s,
          ),
          Radius.circular(barWidth * s / 2),
        ),
        barPaint,
      );
    }

    // Gold coin sitting on top of the tallest bar.
    const coinRadius = 0.12;
    final coinCenter = Offset(
      (startX + 2 * (barWidth + gap) + barWidth / 2) * s,
      (baseline - heights.last - coinRadius) * s,
    );
    canvas.drawCircle(
      coinCenter,
      coinRadius * s,
      Paint()..color = const Color(0xFFFFC107),
    );
    // A thin darker ring inside the coin gives it a "minted" look.
    canvas.drawCircle(
      coinCenter,
      coinRadius * s * 0.68,
      Paint()
        ..color = const Color(0xFFFFA000)
        ..style = PaintingStyle.stroke
        ..strokeWidth = coinRadius * s * 0.16,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoPainter old) => old.onDark != onDark;
}