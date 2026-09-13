import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../services/unit_helper.dart';
import '../../theme/weather_colors.dart';

class CityWeatherCard extends StatelessWidget {
  final String cityName;
  final String country;
  final FullWeatherData? weatherData;
  final bool isCurrentLocation;
  final bool isLoading;
  final bool isCelsius;
  final bool useKmh;
  final bool is24Hour;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const CityWeatherCard({
    super.key,
    required this.cityName,
    this.country = '',
    this.weatherData,
    this.isCurrentLocation = false,
    this.isLoading = false,
    this.isCelsius = true,
    this.useKmh = true,
    this.is24Hour = false,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final current = weatherData?.current;
    final today = weatherData != null && weatherData!.daily.isNotEmpty ? weatherData!.daily.first : null;

    final gradientColors = current != null
        ? WeatherColors.getThemeGradient(current.weatherCode, current.isDay)
        : [const Color(0xFF1E293B), const Color(0xFF0F172A)];

    final desc = current != null
        ? WeatherCodeHelper.getDescription(current.weatherCode, current.isDay)
        : 'جاري التحميل...';

    final iconData = current != null
        ? WeatherCodeHelper.getIcon(current.weatherCode, current.isDay)
        : Icons.cloud_outlined;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.white.withValues(alpha: 0.1),
            highlightColor: Colors.white.withValues(alpha: 0.05),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    gradientColors.first.withValues(alpha: 0.85),
                    gradientColors.last.withValues(alpha: 0.95),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1.2,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Location Title & Badges + Delete or GPS Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isCurrentLocation) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    margin: const EdgeInsets.only(left: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.amberAccent.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.near_me_rounded, color: Colors.amberAccent, size: 12),
                                        SizedBox(width: 4),
                                        Text(
                                          'موقعي',
                                          style: TextStyle(
                                            color: Colors.amberAccent,
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                Flexible(
                                  child: Text(
                                    cityName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (weatherData != null) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.access_time_rounded, color: Colors.white70, size: 10),
                                        const SizedBox(width: 3),
                                        Text(
                                          UnitHelper.formatTime(weatherData!.localTime, is24Hour: is24Hour),
                                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (country.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  country,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7),
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Actions: Temp Big or Loading
                      if (isLoading)
                        const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.amberAccent,
                          ),
                        )
                      else if (current != null)
                        Text(
                          UnitHelper.formatTemp(current.temperature, isCelsius: isCelsius),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 44,
                            fontWeight: FontWeight.w300,
                            height: 1,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Middle Row: Condition with Icon & High/Low Temp
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(iconData, color: Colors.white, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            desc,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      if (today != null)
                        Text(
                          'عظمى: ${UnitHelper.formatTemp(today.tempMax, isCelsius: isCelsius)}  صغرى: ${UnitHelper.formatTemp(today.tempMin, isCelsius: isCelsius)}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                  const SizedBox(height: 12),

                  // Bottom Row: Quick Stats (Humidity, Wind) & Navigation prompt
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (current != null) ...[
                            _buildMiniChip(
                              icon: Icons.water_drop_outlined,
                              label: '${current.humidity}%',
                            ),
                            const SizedBox(width: 8),
                            _buildMiniChip(
                              icon: Icons.air_rounded,
                              label: UnitHelper.formatWind(current.windSpeed, useKmh: useKmh),
                            ),
                          ],
                        ],
                      ),
                      Row(
                        children: [
                          if (!isCurrentLocation && onDelete != null)
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: 'حذف من المحفوظات',
                              onPressed: onDelete,
                            ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              children: [
                                Text(
                                  'التفاصيل',
                                  style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniChip({required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 13),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
