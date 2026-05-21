import 'dart:math';

import 'package:flutter/material.dart';

import '../../../transaction/domain/entities/transaction.dart';

class SpendingLineChartPainter extends CustomPainter {
  final List<Offset> dataPoints;
  final double progress;

  SpendingLineChartPainter({
    required this.dataPoints,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (dataPoints.isEmpty) return;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = Colors.blue
      ..strokeCap = StrokeCap.round;

    final fullPath = Path();
    fullPath.moveTo(dataPoints[0].dx, dataPoints[0].dy);
    for (int i = 1; i < dataPoints.length; i++) {
      fullPath.lineTo(dataPoints[i].dx, dataPoints[i].dy);
    }

    final metrics = fullPath.computeMetrics();
    for (final metric in metrics) {
      final extracted =
          metric.extractPath(0, metric.length * progress);
      canvas.drawPath(extracted, linePaint);
    }

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.blue;

    for (int i = 0; i < dataPoints.length; i++) {
      if ((i / max(dataPoints.length - 1, 1)) <= progress) {
        canvas.drawCircle(dataPoints[i], 3, dotPaint);
      }
    }

    // Draw axes
    final axisPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.grey.shade300;

    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axisPaint);
    canvas.drawLine(Offset(0, 0), Offset(0, size.height), axisPaint);
  }

  @override
  bool shouldRepaint(SpendingLineChartPainter old) =>
      old.progress != progress || old.dataPoints != dataPoints;
}

class SpendingLineChart extends StatefulWidget {
  final List<Transaction> transactions;

  const SpendingLineChart({super.key, required this.transactions});

  @override
  State<SpendingLineChart> createState() => _SpendingLineChartState();
}

class _SpendingLineChartState extends State<SpendingLineChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _controller.forward();
  }

  @override
  void didUpdateWidget(SpendingLineChart old) {
    super.didUpdateWidget(old);
    if (old.transactions != widget.transactions) {
      _controller.forward(from: 0);
    }
  }

  List<Offset> _computeDataPoints(double width, double height) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final dailyTotals = List.filled(daysInMonth, 0.0);

    for (final t in widget.transactions) {
      if (t.date.month == now.month && t.date.year == now.year) {
        dailyTotals[t.date.day - 1] += t.amount;
      }
    }

    final maxAmount = dailyTotals.reduce(max);
    if (maxAmount == 0) return [];

    final padding = 4.0;
    final chartWidth = width - padding * 2;
    final chartHeight = height - padding * 2;

    return List.generate(daysInMonth, (i) {
      final x = padding + (i / max(daysInMonth - 1, 1)) * chartWidth;
      final y = padding + chartHeight - (dailyTotals[i] / maxAmount) * chartHeight;
      return Offset(x, y);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, _) => LayoutBuilder(
        builder: (context, constraints) {
          final dataPoints =
              _computeDataPoints(constraints.maxWidth, constraints.maxHeight);
          return CustomPaint(
            painter: SpendingLineChartPainter(
              dataPoints: dataPoints,
              progress: _animation.value,
            ),
            size: Size(constraints.maxWidth, constraints.maxHeight),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
