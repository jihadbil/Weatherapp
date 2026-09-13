import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../services/unit_helper.dart';
import '../../theme/weather_colors.dart';

class WeatherDetailsGrid extends StatelessWidget {
  final CurrentWeatherModel current;
  final double uvIndex;
  final bool isCelsius;
  final bool useKmh;
  final String pressureUnit;

  const WeatherDetailsGrid({
    super.key,
    required this.current,
    required this.uvIndex,
    this.isCelsius = true,
    this.useKmh = true,
    this.pressureUnit = 'hPa',
  });

  Widget _buildDetailCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: WeatherColors.glassDecoration(borderRadius: 20, opacity: 0.15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, color: Colors.white70, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(color: Colors.white60, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.grid_view_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 6),
              Text(
                'تفاصيل الجو الحالية',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.35,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildDetailCard(
              icon: Icons.air_rounded,
              title: 'الرياح',
              value: UnitHelper.formatWind(current.windSpeed, useKmh: useKmh),
              subtitle: 'سرعة تدفق الهواء',
            ),
            _buildDetailCard(
              icon: Icons.water_drop_rounded,
              title: 'الرطوبة',
              value: '${current.humidity}%',
              subtitle: current.humidity > 60 ? 'رطوبة عالية' : 'مستوى مريح',
            ),
            _buildDetailCard(
              icon: Icons.thermostat_rounded,
              title: 'الشعور الحقيقي',
              value: UnitHelper.formatTemp(current.apparentTemperature, isCelsius: isCelsius),
              subtitle: 'بناءً على الرياح والرطوبة',
            ),
            _buildDetailCard(
              icon: Icons.compress_rounded,
              title: 'الضغط الجوي',
              value: UnitHelper.formatPressure(current.pressure, unit: pressureUnit),
              subtitle: current.pressure > 1013 ? 'ضغط مرتفع وطقس مستقر' : 'ضغط منخفض نسبي',
            ),
            _buildDetailCard(
              icon: Icons.wb_sunny_outlined,
              title: 'مؤشر UV',
              value: uvIndex.toStringAsFixed(1),
              subtitle: uvIndex > 5 ? 'مرتفع - استخدم واقي' : 'منخفض ومعتدل',
            ),
            _buildDetailCard(
              icon: Icons.grain_rounded,
              title: 'الأمطار',
              value: '${current.precipitation.toStringAsFixed(1)} ملم',
              subtitle: current.precipitation > 0 ? 'هطول نشط حالياً' : 'لا يوجد أمطار',
            ),
          ],
        ),
      ],
    );
  }
}
