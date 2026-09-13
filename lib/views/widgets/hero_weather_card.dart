import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../services/unit_helper.dart';
import '../../theme/weather_colors.dart';

class HeroWeatherCard extends StatelessWidget {
  final FullWeatherData weatherData;
  final VoidCallback? onSearchTap;
  final bool isCelsius;

  const HeroWeatherCard({
    super.key,
    required this.weatherData,
    this.onSearchTap,
    this.isCelsius = true,
  });

  @override
  Widget build(BuildContext context) {
    final current = weatherData.current;
    final today = weatherData.daily.isNotEmpty ? weatherData.daily.first : null;
    final desc = WeatherCodeHelper.getDescription(current.weatherCode, current.isDay);
    final iconData = WeatherCodeHelper.getIcon(current.weatherCode, current.isDay);

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: WeatherColors.glassDecoration(borderRadius: 24, opacity: 0.2),
          child: Column(
            children: [
              // Header: City Name & Search Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 6),
                      Text(
                        weatherData.locationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (onSearchTap != null)
                    IconButton(
                      onPressed: onSearchTap,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Weather Icon & Temp
              Icon(
                iconData,
                size: 72,
                color: Colors.white,
              ),
              const SizedBox(height: 8),

              // Temperature Big
              Text(
                UnitHelper.formatTemp(current.temperature, isCelsius: isCelsius),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 76,
                  fontWeight: FontWeight.w200,
                  height: 1,
                ),
              ),
              const SizedBox(height: 8),

              // Weather Condition Description
              Text(
                desc,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),

              // Temp Max / Min Badges
              if (today != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_upward_rounded, color: Colors.amberAccent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'العظمى: ${UnitHelper.formatTemp(today.tempMax, isCelsius: isCelsius)}',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.arrow_downward_rounded, color: Colors.lightBlueAccent, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            'الصغرى: ${UnitHelper.formatTemp(today.tempMin, isCelsius: isCelsius)}',
                            style: const TextStyle(color: Colors.white, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
