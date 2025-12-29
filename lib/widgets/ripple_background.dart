import 'package:flutter/material.dart';

class RippleBackground extends StatefulWidget {
  final Widget child;
  final Color rippleColor;

  const RippleBackground({
    Key? key,
    required this.child,
    this.rippleColor = Colors.white,
  }) : super(key: key);

  @override
  RippleBackgroundState createState() => RippleBackgroundState();
}

class RippleBackgroundState extends State<RippleBackground>
    with TickerProviderStateMixin {
  final List<_Ripple> _ripples = [];

  void addRipple(Offset origin) {
    final controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500));

    final ripple = _Ripple(
      controller: controller,
      origin: origin,
      color: widget.rippleColor,
    );

    setState(() {
      _ripples.add(ripple);
    });

    controller.forward().then((_) {
      if (mounted) {
        setState(() {
          _ripples.remove(ripple);
          ripple.controller.dispose();
        });
      }
    });
  }

  @override
  void dispose() {
    for (var ripple in _ripples) {
      ripple.controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background content (passed child)
        widget.child,

        // Ripples overlay
        // IgnorePointer ensures ripples don't block taps on underlying widgets
        IgnorePointer(
          child: Stack(
            children: _ripples.map((ripple) {
              return AnimatedBuilder(
                animation: ripple.controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _RipplePainter(
                      origin: ripple.origin,
                      progress: ripple.controller.value,
                      color: ripple.color,
                    ),
                    size: Size.infinite,
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _Ripple {
  final AnimationController controller;
  final Offset origin;
  final Color color;

  _Ripple({
    required this.controller,
    required this.origin,
    required this.color,
  });
}

class _RipplePainter extends CustomPainter {
  final Offset origin;
  final double progress;
  final Color color;

  _RipplePainter({
    required this.origin,
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Dynamic max radius: cover the entire screen diagonals (1.5x longest side)
    final maxRadius = size.longestSide * 1.5;
    final currentRadius = maxRadius * progress;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    final paint = Paint()
      ..color = color.withOpacity(opacity * 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * (1 - progress);

    canvas.drawCircle(origin, currentRadius, paint);

    // Fill slightly
    final fillPaint = Paint()
      ..color = color.withOpacity(opacity * 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(origin, currentRadius, fillPaint);
  }

  @override
  bool shouldRepaint(_RipplePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.origin != origin ||
        oldDelegate.color != color;
  }
}
