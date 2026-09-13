import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather_model.dart';
import '../../theme/weather_colors.dart';

class SunMoonWidget extends StatelessWidget {
  final DateTime? sunrise;
  final DateTime? sunset;

  const SunMoonWidget({
    super.key,
    this.sunrise,
    this.sunset,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todaySunrise = sunrise ?? DateTime(now.year, now.month, now.day, 5, 45);
    final todaySunset = sunset ?? DateTime(now.year, now.month, now.day, 18, 15);

    // Calculate progress (0.0 to 1.0)
    double progress = 0.0;
    String statusText = '';
    final isSunUp = now.isAfter(todaySunrise) && now.isBefore(todaySunset);

    if (isSunUp) {
      final totalDaylight = todaySunset.difference(todaySunrise).inMinutes;
      final elapsed = now.difference(todaySunrise).inMinutes;
      progress = (elapsed / totalDaylight).clamp(0.0, 1.0);

      final remaining = todaySunset.difference(now);
      final h = remaining.inHours;
      final m = remaining.inMinutes % 60;
      statusText = 'متبقي على الغروب: ${h > 0 ? '$h س و ' : ''}$m دقيقة';
    } else {
      progress = now.isBefore(todaySunrise) ? 0.0 : 1.0;
      statusText = 'الشمس غاربة حالياً';
    }

    final sunriseStr = DateFormat('hh:mm a').format(todaySunrise).replaceAll('AM', 'ص').replaceAll('PM', 'م');
    final sunsetStr = DateFormat('hh:mm a').format(todaySunset).replaceAll('AM', 'ص').replaceAll('PM', 'م');

    // Moon Data
    final moonPhaseName = MoonPhaseHelper.getPhaseName(now);
    final moonIllumination = MoonPhaseHelper.getIllumination(now);
    final moonIcon = MoonPhaseHelper.getPhaseIcon(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.wb_twilight_rounded, color: Colors.amberAccent, size: 18),
              SizedBox(width: 6),
              Text(
                'مسار الشمس وأطوار القمر',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sun Arc Card
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: WeatherColors.glassDecoration(borderRadius: 20, opacity: 0.15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'حركة الشمس',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSunUp ? Colors.amberAccent.withValues(alpha: 0.2) : Colors.white10,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isSunUp ? 'نهار' : 'ليل',
                            style: TextStyle(
                              color: isSunUp ? Colors.amberAccent : Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Custom Painted Arc
                    SizedBox(
                      height: 80,
                      width: double.infinity,
                      child: CustomPaint(
                        painter: _SunArcPainter(progress: progress, isSunUp: isSunUp),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Sunrise & Sunset Labels
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.arrow_upward_rounded, color: Colors.amberAccent, size: 12),
                                SizedBox(width: 2),
                                Text('الشروق', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                            Text(
                              sunriseStr,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.arrow_downward_rounded, color: Colors.orangeAccent, size: 12),
                                SizedBox(width: 2),
                                Text('الغروب', style: TextStyle(color: Colors.white54, fontSize: 11)),
                              ],
                            ),
                            Text(
                              sunsetStr,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      statusText,
                      style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.w500),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.camera_alt_outlined, color: Colors.amberAccent, size: 11),
                          const SizedBox(width: 4),
                          Text(
                            'الساعة الذهبية: ${DateFormat('hh:mm').format(todaySunset.subtract(const Duration(minutes: 45)))} م',
                            style: const TextStyle(color: Colors.amberAccent, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Moon Card
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: WeatherColors.glassDecoration(borderRadius: 20, opacity: 0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'طور القمر',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.indigo.withValues(alpha: 0.3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.2),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Icon(moonIcon, color: Colors.amberAccent, size: 36),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Center(
                      child: Text(
                        moonPhaseName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Center(
                      child: Text(
                        'إضاءة $moonIllumination%',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          MoonPhaseHelper.getDaysUntilFullMoon(now) == 0
                              ? 'الليلة بدر مكتمل! 🌕'
                              : 'متبقي ${MoonPhaseHelper.getDaysUntilFullMoon(now)} أيام للبدر',
                          style: const TextStyle(color: Colors.white70, fontSize: 9),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SunArcPainter extends CustomPainter {
  final double progress;
  final bool isSunUp;

  _SunArcPainter({required this.progress, required this.isSunUp});

  @override
  void paint(Canvas canvas, Size size) {
    final arcPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final baseLinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;

    // Draw baseline
    final baselineY = size.height - 10;
    canvas.drawLine(Offset(0, baselineY), Offset(size.width, baselineY), baseLinePaint);

    // Draw Arc
    final rect = Rect.fromLTWH(10, 10, size.width - 20, (size.height - 20) * 2);
    canvas.drawArc(rect, math.pi, math.pi, false, arcPaint);

    // Sun position on arc: angle from pi to 2*pi
    final angle = math.pi + (progress * math.pi);
    final rx = (size.width - 20) / 2;
    final ry = (size.height - 20);
    final cx = size.width / 2;
    final cy = baselineY;

    final sunX = cx + rx * math.cos(angle);
    final sunY = cy + ry * math.sin(angle);

    if (isSunUp) {
      // Glow
      final glowPaint = Paint()
        ..color = Colors.amberAccent.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(sunX, sunY), 10, glowPaint);

      // Sun dot
      canvas.drawCircle(Offset(sunX, sunY), 6, Paint()..color = Colors.amberAccent);
    }
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isSunUp != isSunUp;
}
