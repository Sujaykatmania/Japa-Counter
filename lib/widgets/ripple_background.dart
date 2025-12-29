import 'package:flutter/material.dart';

class RippleBackground extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color rippleColor;

  const RippleBackground({
    Key? key,
    required this.child,
    this.onTap,
    this.rippleColor = Colors.white,
  }) : super(key: key);

  @override
  State<RippleBackground> createState() => _RippleBackgroundState();
}

class _RippleBackgroundState extends State<RippleBackground>
    with TickerProviderStateMixin {
  final List<_Ripple> _ripples = [];

  void _addRipple(Offset origin) {
    if (widget.onTap != null) {
      widget.onTap!();
    }

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
      setState(() {
        _ripples.remove(ripple);
        ripple.controller.dispose();
      });
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
    return GestureDetector(
      onTapDown: (details) => _addRipple(details.globalPosition),
      behavior: HitTestBehavior
          .translucent, // Allow taps to pass through if needed, but here we catch them
      child: Stack(
        children: [
          // Background content
          widget.child,

          // Ripples overlay
          ..._ripples.map((ripple) {
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
        ],
      ),
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
    final maxRadius = size.longestSide * 0.8;
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
