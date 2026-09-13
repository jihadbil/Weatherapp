import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../services/unit_helper.dart';
import '../../theme/weather_colors.dart';

class HourlyForecastWidget extends StatelessWidget {
  final List<HourlyForecastModel> hourlyForecast;
  final bool isDay;
  final bool isCelsius;
  final bool is24Hour;

  const HourlyForecastWidget({
    super.key,
    required this.hourlyForecast,
    required this.isDay,
    this.isCelsius = true,
    this.is24Hour = false,
  });

  @override
  Widget build(BuildContext context) {
    if (hourlyForecast.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.access_time_rounded, color: Colors.white70, size: 18),
              SizedBox(width: 6),
              Text(
                'التوقعات خلال الـ 24 ساعة',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: hourlyForecast.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final item = hourlyForecast[index];
              final timeStr = UnitHelper.formatTime(item.time, is24Hour: is24Hour);
              final icon = WeatherCodeHelper.getIcon(item.weatherCode, isDay);

              return Container(
                width: 78,
                margin: const EdgeInsets.only(left: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: WeatherColors.glassDecoration(borderRadius: 18, opacity: 0.15),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeStr,
                            style: const TextStyle(color: Colors.white70, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Icon(icon, color: Colors.white, size: 26),
                          Text(
                            UnitHelper.formatTemp(item.temperature, isCelsius: isCelsius),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
