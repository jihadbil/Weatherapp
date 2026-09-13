import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/weather_model.dart';
import '../../services/unit_helper.dart';
import '../../theme/weather_colors.dart';

class DailyForecastWidget extends StatefulWidget {
  final List<DailyForecastModel> dailyForecast;
  final bool isCelsius;
  final bool is24Hour;

  const DailyForecastWidget({
    super.key,
    required this.dailyForecast,
    this.isCelsius = true,
    this.is24Hour = false,
  });

  @override
  State<DailyForecastWidget> createState() => _DailyForecastWidgetState();
}

class _DailyForecastWidgetState extends State<DailyForecastWidget> {
  int? _expandedIndex;

  String _getDayName(DateTime date, int index) {
    if (index == 0) return 'اليوم';
    try {
      final formatter = DateFormat('EEEE', 'ar');
      return formatter.format(date);
    } catch (_) {
      const weekdays = [
        'الأحد',
        'الإثنين',
        'الثلاثاء',
        'الأربعاء',
        'الخميس',
        'الجمعة',
        'السبت',
      ];
      return weekdays[date.weekday % 7];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.dailyForecast.isEmpty) return const SizedBox.shrink();

    // Calculate global min and max for the week
    double globalMin = widget.dailyForecast.first.tempMin;
    double globalMax = widget.dailyForecast.first.tempMax;
    for (final day in widget.dailyForecast) {
      if (day.tempMin < globalMin) globalMin = day.tempMin;
      if (day.tempMax > globalMax) globalMax = day.tempMax;
    }
    final double tempSpan = (globalMax - globalMin).clamp(4.0, 60.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.calendar_month_rounded, color: Colors.amberAccent, size: 18),
              SizedBox(width: 6),
              Text(
                'توقعات الأسبوع (7 أيام)',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: WeatherColors.glassDecoration(borderRadius: 20, opacity: 0.15),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.dailyForecast.length,
                separatorBuilder: (context, index) =>
                    Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                itemBuilder: (context, index) {
                  final item = widget.dailyForecast[index];
                  final dayName = _getDayName(item.date, index);
                  final icon = WeatherCodeHelper.getIcon(item.weatherCode, true);
                  final isToday = index == 0;
                  final isExpanded = _expandedIndex == index;

                  // Bar calculations
                  final leftPercent = ((item.tempMin - globalMin) / tempSpan).clamp(0.0, 1.0);
                  final rightPercent = ((item.tempMax - globalMin) / tempSpan).clamp(0.0, 1.0);
                  final barWidthPercent = (rightPercent - leftPercent).clamp(0.12, 1.0);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _expandedIndex = isExpanded ? null : index;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              // Day Name
                              SizedBox(
                                width: 62,
                                child: Text(
                                  dayName,
                                  style: TextStyle(
                                    color: isToday ? Colors.amberAccent : Colors.white,
                                    fontSize: 14,
                                    fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),

                              // Weather Icon
                              SizedBox(
                                width: 30,
                                child: Center(
                                  child: Icon(icon, color: Colors.white, size: 22),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Min Temp Text
                              SizedBox(
                                width: 30,
                                child: Text(
                                  UnitHelper.formatTemp(item.tempMin, isCelsius: widget.isCelsius),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Apple Weather Style Capsule Gradient Bar (Responsive Expanded)
                              Expanded(
                                child: SizedBox(
                                  height: 14,
                                  child: LayoutBuilder(
                                    builder: (context, constraints) {
                                      final totalWidth = constraints.maxWidth;
                                      final barStart = (leftPercent * totalWidth).clamp(0.0, totalWidth - 6.0);
                                      final activeWidth = (barWidthPercent * totalWidth).clamp(6.0, totalWidth - barStart);

                                      return Stack(
                                        alignment: AlignmentDirectional.centerStart,
                                        clipBehavior: Clip.none,
                                        children: [
                                          // Track background
                                          Container(
                                            width: totalWidth,
                                            height: 5,
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.25),
                                              borderRadius: BorderRadius.circular(3),
                                            ),
                                          ),
                                          // Colored Range Capsule
                                          PositionedDirectional(
                                            start: barStart,
                                            child: Container(
                                              width: activeWidth,
                                              height: 5,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(3),
                                                gradient: const LinearGradient(
                                                  begin: AlignmentDirectional.centerStart,
                                                  end: AlignmentDirectional.centerEnd,
                                                  colors: [
                                                    Color(0xFF38BDF8), // Sky blue (Cold/Min)
                                                    Color(0xFFFBBF24), // Amber
                                                    Color(0xFFF97316), // Orange (Hot/Max)
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                          // Current temp glowing dot for Today
                                          if (isToday)
                                            PositionedDirectional(
                                              start: (barStart + (activeWidth * 0.5) - 3.5).clamp(0.0, totalWidth - 7),
                                              top: 3.5,
                                              child: Container(
                                                width: 7,
                                                height: 7,
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.black45, width: 1),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.white.withValues(alpha: 0.8),
                                                      blurRadius: 4,
                                                      spreadRadius: 1,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Max Temp Text
                              SizedBox(
                                width: 30,
                                child: Text(
                                  UnitHelper.formatTemp(item.tempMax, isCelsius: widget.isCelsius),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),

                          // Expandable Extra Day Details
                          if (isExpanded) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Icon(icon, color: Colors.amberAccent, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        WeatherCodeHelper.getDescription(item.weatherCode, true),
                                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: [
                                      _buildExpandedChip(
                                        icon: Icons.wb_sunny_rounded,
                                        label: 'مؤشر UV',
                                        value: '${item.uvIndexMax.round()}',
                                      ),
                                      _buildExpandedChip(
                                        icon: Icons.arrow_upward_rounded,
                                        label: 'العظمى',
                                        value: UnitHelper.formatTemp(item.tempMax, isCelsius: widget.isCelsius),
                                      ),
                                      _buildExpandedChip(
                                        icon: Icons.arrow_downward_rounded,
                                        label: 'الصغرى',
                                        value: UnitHelper.formatTemp(item.tempMin, isCelsius: widget.isCelsius),
                                      ),
                                      if (item.sunrise != null)
                                        _buildExpandedChip(
                                          icon: Icons.wb_twilight_rounded,
                                          label: 'الشروق',
                                          value: UnitHelper.formatShortTime(item.sunrise!, is24Hour: widget.is24Hour),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExpandedChip({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.amberAccent, size: 16),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
