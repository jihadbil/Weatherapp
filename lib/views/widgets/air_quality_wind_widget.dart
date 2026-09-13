import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../services/unit_helper.dart';
import '../../theme/weather_colors.dart';

class AirQualityWindWidget extends StatelessWidget {
  final AirQualityModel? airQuality;
  final CurrentWeatherModel current;
  final bool useKmh;

  const AirQualityWindWidget({
    super.key,
    this.airQuality,
    required this.current,
    this.useKmh = true,
  });

  @override
  Widget build(BuildContext context) {
    final aqi = airQuality ?? AirQualityModel(aqi: 28, pm2_5: 8.5, pm10: 16.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.air_rounded, color: Colors.amberAccent, size: 18),
              SizedBox(width: 6),
              Text(
                'جودة الهواء وبوصلة الرياح',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Air Quality Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: WeatherColors.glassDecoration(borderRadius: 20, opacity: 0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'جودة الهواء',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: aqi.statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: aqi.statusColor.withValues(alpha: 0.5)),
                          ),
                          child: Text(
                            aqi.statusText,
                            style: TextStyle(
                              color: aqi.statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // AQI Number Big
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${aqi.aqi}',
                          style: TextStyle(
                            color: aqi.statusColor,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'AQI',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Progress Bar Gauge
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (aqi.aqi / 150.0).clamp(0.05, 1.0),
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(aqi.statusColor),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // PM2.5 & PM10 Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PM2.5: ${aqi.pm2_5.round()}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                        Text(
                          'PM10: ${aqi.pm10.round()}',
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      aqi.healthTip,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Wind Compass Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: WeatherColors.glassDecoration(borderRadius: 20, opacity: 0.15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'اتجاه الرياح',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          UnitHelper.formatWind(current.windSpeed, useKmh: useKmh),
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Compass Graphic
                    SizedBox(
                      height: 80,
                      width: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Compass Ring
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 1.5),
                            ),
                          ),
                          // Cardinal letters
                          const Positioned(
                            top: 2,
                            child: Text('N', style: TextStyle(color: Colors.amberAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                          const Positioned(
                            bottom: 2,
                            child: Text('S', style: TextStyle(color: Colors.white38, fontSize: 9)),
                          ),
                          const Positioned(
                            left: 4,
                            child: Text('W', style: TextStyle(color: Colors.white38, fontSize: 9)),
                          ),
                          const Positioned(
                            right: 4,
                            child: Text('E', style: TextStyle(color: Colors.white38, fontSize: 9)),
                          ),

                          // Rotating Needle
                          Transform.rotate(
                            angle: (current.windDirection * math.pi / 180.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: const BoxDecoration(
                                    color: Colors.redAccent,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
                                  ),
                                ),
                                Container(
                                  width: 4,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.5),
                                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Center dot
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    Text(
                      current.windDirectionText,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${current.windDirection}° درجة',
                      style: const TextStyle(color: Colors.white54, fontSize: 10),
                      textAlign: TextAlign.center,
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
