import 'package:flutter/material.dart';
import '../../models/weather_model.dart';

class WeatherAlertBanner extends StatefulWidget {
  final FullWeatherData weatherData;

  const WeatherAlertBanner({
    super.key,
    required this.weatherData,
  });

  @override
  State<WeatherAlertBanner> createState() => _WeatherAlertBannerState();
}

class _WeatherAlertBannerState extends State<WeatherAlertBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final alert = WeatherAlertHelper.checkSevereWeather(widget.weatherData);
    if (alert == null) return const SizedBox.shrink();

    final Color alertColor = alert['color'] as Color;
    final String title = alert['title'] as String;
    final String desc = alert['desc'] as String;
    final IconData icon = alert['icon'] as IconData;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: alertColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: alertColor.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: alertColor.withValues(alpha: 0.2),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: alertColor.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      _isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ],
                ),
                if (_isExpanded) ...[
                  const SizedBox(height: 10),
                  Divider(color: Colors.white.withValues(alpha: 0.15), height: 1),
                  const SizedBox(height: 10),
                  Text(
                    desc,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
