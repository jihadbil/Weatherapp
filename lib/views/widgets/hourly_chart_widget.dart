import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../services/unit_helper.dart';
import '../../theme/weather_colors.dart';

class HourlyChartWidget extends StatefulWidget {
  final List<HourlyForecastModel> hourlyForecast;
  final bool isDay;
  final bool isCelsius;
  final bool is24Hour;

  const HourlyChartWidget({
    super.key,
    required this.hourlyForecast,
    required this.isDay,
    this.isCelsius = true,
    this.is24Hour = false,
  });

  @override
  State<HourlyChartWidget> createState() => _HourlyChartWidgetState();
}

class _HourlyChartWidgetState extends State<HourlyChartWidget> {
  int _selectedTabIndex = 0; // 0 = Temperature, 1 = Rain Chance
  int? _hoveredIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.hourlyForecast.isEmpty) return const SizedBox.shrink();

    final data = widget.hourlyForecast.take(18).toList();
    const double itemWidth = 66.0;
    final totalWidth = data.length * itemWidth + 40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.show_chart_rounded, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 6),
                  const Text(
                    'المخطط البياني التفاعلي',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  if (_hoveredIndex != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.amberAccent.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'محدد 👆',
                        style: TextStyle(color: Colors.amberAccent, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
              // Segmented Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  children: [
                    _buildTabBtn('الحرارة', 0),
                    _buildTabBtn('الأمطار', 1),
                  ],
                ),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 210,
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            decoration: WeatherColors.glassDecoration(borderRadius: 20, opacity: 0.15),
            child: GestureDetector(
              onHorizontalDragStart: (details) => _updateHover(details.localPosition.dx, data.length, itemWidth),
              onHorizontalDragUpdate: (details) => _updateHover(details.localPosition.dx, data.length, itemWidth),
              onHorizontalDragEnd: (_) => setState(() => _hoveredIndex = null),
              onTapDown: (details) => _updateHover(details.localPosition.dx, data.length, itemWidth),
              onTapUp: (_) {
                Future.delayed(const Duration(seconds: 3), () {
                  if (mounted) setState(() => _hoveredIndex = null);
                });
              },
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  width: totalWidth,
                  child: CustomPaint(
                    painter: _HourlyChartPainter(
                      items: data,
                      showRain: _selectedTabIndex == 1,
                      isDay: widget.isDay,
                      isCelsius: widget.isCelsius,
                      is24Hour: widget.is24Hour,
                      hoveredIndex: _hoveredIndex,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _updateHover(double localX, int count, double itemWidth) {
    final rawIndex = ((localX - 20) / itemWidth).round();
    final clamped = rawIndex.clamp(0, count - 1);
    setState(() {
      _hoveredIndex = clamped;
    });
  }

  Widget _buildTabBtn(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedTabIndex = index;
        _hoveredIndex = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.amberAccent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class _HourlyChartPainter extends CustomPainter {
  final List<HourlyForecastModel> items;
  final bool showRain;
  final bool isDay;
  final bool isCelsius;
  final bool is24Hour;
  final int? hoveredIndex;

  _HourlyChartPainter({
    required this.items,
    required this.showRain,
    required this.isDay,
    required this.isCelsius,
    required this.is24Hour,
    this.hoveredIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    const double itemWidth = 66.0;
    const double topMargin = 45.0;
    const double bottomMargin = 40.0;
    final chartHeight = size.height - topMargin - bottomMargin;

    if (showRain) {
      final barPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            Colors.lightBlueAccent,
            Colors.blue.withValues(alpha: 0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, topMargin, size.width, chartHeight))
        ..style = PaintingStyle.fill;

      for (int i = 0; i < items.length; i++) {
        final item = items[i];
        final x = 20.0 + i * itemWidth;
        final prob = (item.precipitationProbability / 100.0).clamp(0.0, 1.0);
        final barHeight = prob * (chartHeight - 10);
        final barTop = size.height - bottomMargin - barHeight;
        final isHovered = hoveredIndex == i;

        // Draw Bar
        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x - 14, barTop, 28, barHeight),
          const Radius.circular(6),
        );
        canvas.drawRRect(rect, isHovered ? (Paint()..color = Colors.cyanAccent) : barPaint);

        // Probability text
        _drawText(
          canvas,
          '${item.precipitationProbability}%',
          Offset(x, barTop - 14),
          color: prob > 0.3 ? Colors.lightBlueAccent : Colors.white54,
          fontSize: 11,
          bold: true,
        );

        // Time Label
        final timeStr = UnitHelper.formatShortTime(item.time, is24Hour: is24Hour);
        _drawText(
          canvas,
          timeStr,
          Offset(x, size.height - 20),
          color: isHovered ? Colors.amberAccent : Colors.white70,
          fontSize: 11,
          bold: isHovered,
        );
      }
    } else {
      // Temperature Spline Curve
      double minTemp = items.first.temperature;
      double maxTemp = items.first.temperature;
      for (final it in items) {
        if (it.temperature < minTemp) minTemp = it.temperature;
        if (it.temperature > maxTemp) maxTemp = it.temperature;
      }
      final tempRange = (maxTemp - minTemp).clamp(3.0, 50.0);

      final List<Offset> points = [];
      for (int i = 0; i < items.length; i++) {
        final x = 20.0 + i * itemWidth;
        final normalized = (items[i].temperature - minTemp) / tempRange;
        final y = size.height - bottomMargin - (normalized * chartHeight);
        points.add(Offset(x, y));
      }

      // Smooth Curve Path
      final path = Path();
      final fillPath = Path();

      path.moveTo(points.first.dx, points.first.dy);
      fillPath.moveTo(points.first.dx, size.height - bottomMargin);
      fillPath.lineTo(points.first.dx, points.first.dy);

      for (int i = 0; i < points.length - 1; i++) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final controlX = (p0.dx + p1.dx) / 2;
        path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
        fillPath.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
      }

      fillPath.lineTo(points.last.dx, size.height - bottomMargin);
      fillPath.close();

      // Draw Gradient Under Curve
      final gradientPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            (isDay ? Colors.amberAccent : Colors.cyanAccent).withValues(alpha: 0.35),
            Colors.transparent,
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawPath(fillPath, gradientPaint);

      // Draw Curve Line
      final linePaint = Paint()
        ..color = isDay ? Colors.amberAccent : Colors.cyanAccent
        ..strokeWidth = 3.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(path, linePaint);

      // Draw Points, Temp Text, and Icons
      final dotPaint = Paint()..color = Colors.white;
      for (int i = 0; i < items.length; i++) {
        final pt = points[i];
        final item = items[i];
        final isHovered = hoveredIndex == i;

        // Outer glow circle
        canvas.drawCircle(pt, isHovered ? 6.5 : 4.5, dotPaint);
        canvas.drawCircle(
          pt,
          isHovered ? 4.0 : 2.5,
          Paint()..color = isHovered ? Colors.amberAccent : (isDay ? Colors.deepOrange : Colors.indigo),
        );

        // Temp Label above dot
        _drawText(
          canvas,
          UnitHelper.formatTemp(item.temperature, isCelsius: isCelsius),
          Offset(pt.dx, pt.dy - 16),
          color: Colors.white,
          fontSize: 12,
          bold: true,
        );

        // Time Label
        final timeStr = UnitHelper.formatShortTime(item.time, is24Hour: is24Hour);
        _drawText(
          canvas,
          timeStr,
          Offset(pt.dx, size.height - 20),
          color: isHovered ? Colors.amberAccent : Colors.white70,
          fontSize: 11,
          bold: isHovered,
        );
      }

      // Interactive Touch Cursor & Floating Tooltip Bubble
      if (hoveredIndex != null && hoveredIndex! < points.length) {
        final pt = points[hoveredIndex!];
        final item = items[hoveredIndex!];

        // Vertical Guide Line
        final guidePaint = Paint()
          ..color = Colors.amberAccent.withValues(alpha: 0.6)
          ..strokeWidth = 1.5;
        canvas.drawLine(Offset(pt.dx, topMargin - 15), Offset(pt.dx, size.height - bottomMargin), guidePaint);

        // Tooltip bubble
        final tooltipCenter = Offset(pt.dx.clamp(45.0, size.width - 45.0), topMargin - 22);
        final tooltipRect = RRect.fromRectAndRadius(
          Rect.fromCenter(center: tooltipCenter, width: 85, height: 26),
          const Radius.circular(8),
        );
        canvas.drawRRect(
          tooltipRect,
          Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.95),
        );
        canvas.drawRRect(
          tooltipRect,
          Paint()
            ..color = Colors.amberAccent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );

        _drawText(
          canvas,
          '${UnitHelper.formatTemp(item.temperature, isCelsius: isCelsius)} • 💧${item.precipitationProbability}%',
          tooltipCenter,
          color: Colors.white,
          fontSize: 11,
          bold: true,
        );
      }
    }
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required Color color,
    required double fontSize,
    bool bold = false,
  }) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _HourlyChartPainter oldDelegate) =>
      oldDelegate.showRain != showRain ||
      oldDelegate.items != items ||
      oldDelegate.hoveredIndex != hoveredIndex;
}
