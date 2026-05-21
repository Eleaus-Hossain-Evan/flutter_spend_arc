import 'dart:math';

import 'package:flutter/material.dart';

class ArcMeterPainter extends CustomPainter {
  final double percentage;
  final Color fillColor;
  final Color trackColor;

  ArcMeterPainter({
    required this.percentage,
    required this.fillColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) * 0.35;
    const strokeWidth = 20.0;
    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    paint.color = trackColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );

    paint.color = fillColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle * percentage,
      false,
      paint,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${(percentage * 100).toInt()}%',
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(ArcMeterPainter oldDelegate) =>
      oldDelegate.percentage != percentage;
}

class ArcMeterWidget extends StatefulWidget {
  final double percentage;

  const ArcMeterWidget({super.key, required this.percentage});

  @override
  State<ArcMeterWidget> createState() => _ArcMeterWidgetState();
}

class _ArcMeterWidgetState extends State<ArcMeterWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: widget.percentage)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(ArcMeterWidget old) {
    super.didUpdateWidget(old);
    if (old.percentage != widget.percentage) {
      _animation =
          Tween<double>(begin: old.percentage, end: widget.percentage)
              .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
      _controller.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _) => CustomPaint(
        painter: ArcMeterPainter(
          percentage: _animation.value,
          fillColor: _animation.value > 0.8 ? Colors.red : Colors.green,
          trackColor: theme.colorScheme.surfaceContainerHighest,
        ),
        size: const Size(240, 240),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
