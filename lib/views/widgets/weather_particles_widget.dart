import 'dart:math' as math;
import 'package:flutter/material.dart';

enum WeatherEffectType { rain, snow, thunder, sun, stars, clouds }

class WeatherParticlesWidget extends StatefulWidget {
  final int weatherCode;
  final bool isDay;
  final double windSpeed;
  final int windDirection;
  final Widget child;

  const WeatherParticlesWidget({
    super.key,
    required this.weatherCode,
    required this.isDay,
    this.windSpeed = 12.0,
    this.windDirection = 45,
    required this.child,
  });

  @override
  State<WeatherParticlesWidget> createState() => _WeatherParticlesWidgetState();
}

class _WeatherParticlesWidgetState extends State<WeatherParticlesWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final math.Random _random = math.Random();
  WeatherEffectType _effectType = WeatherEffectType.sun;

  @override
  void initState() {
    super.initState();
    _determineEffect();
    _initParticles();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void didUpdateWidget(covariant WeatherParticlesWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weatherCode != widget.weatherCode || oldWidget.isDay != widget.isDay) {
      _determineEffect();
      _initParticles();
    }
  }

  void _determineEffect() {
    final code = widget.weatherCode;
    if (code >= 95) {
      _effectType = WeatherEffectType.thunder;
    } else if ((code >= 51 && code <= 65) || (code >= 80 && code <= 82)) {
      _effectType = WeatherEffectType.rain;
    } else if (code >= 71 && code <= 77) {
      _effectType = WeatherEffectType.snow;
    } else if (!widget.isDay) {
      _effectType = WeatherEffectType.stars;
    } else if (code <= 1) {
      _effectType = WeatherEffectType.sun;
    } else {
      _effectType = WeatherEffectType.clouds;
    }
  }

  void _initParticles() {
    _particles.clear();
    final count = _effectType == WeatherEffectType.rain
        ? 45
        : _effectType == WeatherEffectType.snow
            ? 35
            : _effectType == WeatherEffectType.stars
                ? 40
                : 20;

    for (int i = 0; i < count; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2.5 + 1.0,
        speed: _random.nextDouble() * 0.5 + 0.5,
        opacity: _random.nextDouble() * 0.5 + 0.3,
        phase: _random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return CustomPaint(
                  painter: _ParticlePainter(
                    particles: _particles,
                    effectType: _effectType,
                    animationValue: _controller.value,
                    windSpeed: widget.windSpeed,
                    windDirection: widget.windDirection,
                  ),
                );
              },
            ),
          ),
        ),
        widget.child,
      ],
    );
  }
}

class _Particle {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double phase;

  _Particle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final WeatherEffectType effectType;
  final double animationValue;
  final double windSpeed;
  final int windDirection;

  _ParticlePainter({
    required this.particles,
    required this.effectType,
    required this.animationValue,
    required this.windSpeed,
    required this.windDirection,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..isAntiAlias = true;

    switch (effectType) {
      case WeatherEffectType.rain:
      case WeatherEffectType.thunder:
        paint.color = Colors.white.withValues(alpha: 0.35);
        paint.strokeWidth = 1.4;
        paint.strokeCap = StrokeCap.round;

        final slant = (windSpeed / 8.0).clamp(0.5, 6.0) * (windDirection > 180 ? -1.0 : 1.0);
        for (final p in particles) {
          final currentY = ((p.y + animationValue * 8 * p.speed) % 1.0) * size.height;
          final currentX = ((p.x + animationValue * 1.5 * p.speed) % 1.0) * size.width;
          const dropLength = 16.0;
          canvas.drawLine(
            Offset(currentX, currentY),
            Offset(currentX + slant * 2.0, currentY + dropLength),
            paint,
          );
        }

        // Thunder flash effect
        if (effectType == WeatherEffectType.thunder) {
          final flashSeed = (animationValue * 30).floor() % 12;
          if (flashSeed == 0) {
            canvas.drawRect(
              Rect.fromLTWH(0, 0, size.width, size.height),
              Paint()..color = Colors.white.withValues(alpha: 0.15),
            );
          }
        }
        break;

      case WeatherEffectType.snow:
        paint.style = PaintingStyle.fill;
        for (final p in particles) {
          final currentY = ((p.y + animationValue * 2.0 * p.speed) % 1.0) * size.height;
          final drift = math.sin(animationValue * 4 * math.pi + p.phase) * 15;
          final currentX = ((p.x * size.width + drift) % size.width);
          paint.color = Colors.white.withValues(alpha: p.opacity);
          canvas.drawCircle(Offset(currentX, currentY), p.size, paint);
        }
        break;

      case WeatherEffectType.stars:
        paint.style = PaintingStyle.fill;
        for (final p in particles) {
          final twinkle = (math.sin(animationValue * 10 * math.pi + p.phase) + 1) / 2;
          paint.color = Colors.white.withValues(alpha: (p.opacity * twinkle).clamp(0.1, 0.7));
          canvas.drawCircle(Offset(p.x * size.width, p.y * size.height * 0.7), p.size * 0.8, paint);
        }
        break;

      case WeatherEffectType.sun:
        // Subtle rotating sun flare
        final center = Offset(size.width * 0.85, size.height * 0.08);
        final glowPaint = Paint()
          ..shader = RadialGradient(
            colors: [
              Colors.amberAccent.withValues(alpha: 0.18),
              Colors.amber.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ).createShader(Rect.fromCircle(center: center, radius: 140));
        canvas.drawCircle(center, 140, glowPaint);
        break;

      case WeatherEffectType.clouds:
        // Subtle floating light clouds
        paint.color = Colors.white.withValues(alpha: 0.04);
        for (int i = 0; i < 3; i++) {
          final cx = ((animationValue * 0.2 + i * 0.35) % 1.2 - 0.1) * size.width;
          final cy = size.height * (0.08 + i * 0.08);
          canvas.drawOval(
            Rect.fromCenter(center: Offset(cx, cy), width: 180, height: 70),
            paint,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
