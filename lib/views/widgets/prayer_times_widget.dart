import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../services/unit_helper.dart';
import '../../theme/weather_colors.dart';

class PrayerTimesWidget extends StatelessWidget {
  final PrayerTimesModel? prayerTimes;
  final double? latitude;
  final double? longitude;
  final bool showQibla;
  final bool is24Hour;

  const PrayerTimesWidget({
    super.key,
    this.prayerTimes,
    this.latitude,
    this.longitude,
    this.showQibla = true,
    this.is24Hour = false,
  });

  @override
  Widget build(BuildContext context) {
    if (prayerTimes == null) return const SizedBox.shrink();

    final now = DateTime.now();
    final nextPrayerInfo = prayerTimes!.getNextPrayer(now);
    final nextPrayerName = nextPrayerInfo['name'] as String;
    final nextPrayerCountdown = nextPrayerInfo['countdown'] as String;

    final prayersList = [
      {'name': 'الفجر', 'time': prayerTimes!.fajr, 'icon': Icons.nights_stay_outlined},
      {'name': 'الشروق', 'time': prayerTimes!.sunrise, 'icon': Icons.wb_twilight_rounded},
      {'name': 'الظهر', 'time': prayerTimes!.dhuhr, 'icon': Icons.wb_sunny_rounded},
      {'name': 'العصر', 'time': prayerTimes!.asr, 'icon': Icons.wb_sunny_outlined},
      {'name': 'المغرب', 'time': prayerTimes!.maghrib, 'icon': Icons.nightlight_outlined},
      {'name': 'العشاء', 'time': prayerTimes!.isha, 'icon': Icons.bedtime_outlined},
    ];

    final hasCoordinates = latitude != null && longitude != null;
    final double qiblaDegrees = hasCoordinates
        ? QiblaHelper.calculateQibla(latitude!, longitude!)
        : 135.0;
    final String qiblaText = QiblaHelper.getDirectionText(qiblaDegrees);

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
                  const Icon(Icons.mosque_rounded, color: Colors.amberAccent, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    showQibla ? 'مواقيت الصلاة واتجاه القبلة' : 'مواقيت الصلاة',
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.amberAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amberAccent.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$nextPrayerName بعد $nextPrayerCountdown',
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: WeatherColors.glassDecoration(borderRadius: 20, opacity: 0.15),
          child: Column(
            children: [
              // Row of 6 Prayers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: prayersList.map((prayer) {
                  final String name = prayer['name'] as String;
                  final DateTime time = prayer['time'] as DateTime;
                  final IconData icon = prayer['icon'] as IconData;
                  final isNext = name == nextPrayerName;
                  final timeStr = UnitHelper.formatShortTime(time, is24Hour: is24Hour);

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: isNext ? Colors.amberAccent.withValues(alpha: 0.25) : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: isNext ? Border.all(color: Colors.amberAccent, width: 1.2) : null,
                    ),
                    child: Column(
                      children: [
                        Icon(
                          icon,
                          color: isNext ? Colors.amberAccent : Colors.white70,
                          size: 20,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          name,
                          style: TextStyle(
                            color: isNext ? Colors.amberAccent : Colors.white70,
                            fontSize: 12,
                            fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          timeStr,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: isNext ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

              if (showQibla) ...[
                const SizedBox(height: 14),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 12),

                // Qibla Compass Strip
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.amberAccent.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Text('🕋', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'اتجاه القبلة المشرفة',
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '$qiblaText • ${qiblaDegrees.round()}° درجة من الشمال',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Animated Mini Compass Needle
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white24, width: 1.2),
                            ),
                          ),
                          Transform.rotate(
                            angle: (qiblaDegrees * math.pi / 180.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 3,
                                  height: 12,
                                  decoration: const BoxDecoration(
                                    color: Colors.amberAccent,
                                    borderRadius: BorderRadius.vertical(top: Radius.circular(2)),
                                  ),
                                ),
                                Container(
                                  width: 3,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(2)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
