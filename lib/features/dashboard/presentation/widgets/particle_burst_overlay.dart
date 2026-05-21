import 'dart:math';

import 'package:flutter/material.dart';

class _Particle {
  Offset position;
  Offset velocity;
  Color color;
  double opacity;

  _Particle({
    required this.position,
    required this.velocity,
    required this.color,
    required this.opacity,
  });
}

class ParticleBurstOverlay extends StatefulWidget {
  final int burstKey;
  final Widget child;

  const ParticleBurstOverlay({
    super.key,
    this.burstKey = 0,
    required this.child,
  });

  @override
  State<ParticleBurstOverlay> createState() => _ParticleBurstOverlayState();
}

class _ParticleBurstOverlayState extends State<ParticleBurstOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  bool _hasLaunched = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.addListener(_updateParticles);
  }

  void _launch() {
    final rng = Random();
    _particles.clear();
    for (int i = 0; i < 40; i++) {
      final angle = rng.nextDouble() * 2 * pi;
      final speed = 100 + rng.nextDouble() * 200;
      _particles.add(_Particle(
        position: Offset.zero,
        velocity: Offset(cos(angle) * speed, sin(angle) * speed),
        color: Colors.primaries[rng.nextInt(Colors.primaries.length)],
        opacity: 1.0,
      ));
    }
    _hasLaunched = true;
    _controller.forward(from: 0);
  }

  void _updateParticles() {
    final t = _controller.value;
    setState(() {
      for (final p in _particles) {
        p.position += p.velocity * 0.016;
        p.opacity = (1 - t).clamp(0.0, 1.0);
      }
    });
  }

  @override
  void didUpdateWidget(ParticleBurstOverlay old) {
    super.didUpdateWidget(old);
    if (widget.burstKey > old.burstKey) _launch();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasLaunched) return widget.child;
    return CustomPaint(
      painter: _ParticlePainter(_particles, _hasLaunched),
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final bool hasLaunched;

  _ParticlePainter(this.particles, this.hasLaunched);

  @override
  void paint(Canvas canvas, Size size) {
    if (!hasLaunched) return;
    for (final p in particles) {
      if (p.opacity <= 0) continue;
      final paint = Paint()
        ..color = p.color.withValues(alpha: p.opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(
          size.width / 2 + p.position.dx,
          size.height / 2 + p.position.dy,
        ),
        4.0,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
