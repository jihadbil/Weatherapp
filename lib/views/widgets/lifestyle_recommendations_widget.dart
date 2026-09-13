import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/weather_model.dart';
import '../../theme/weather_colors.dart';

class LifestyleRecommendationsWidget extends StatelessWidget {
  final CurrentWeatherModel current;
  final double uvIndex;

  const LifestyleRecommendationsWidget({
    super.key,
    required this.current,
    required this.uvIndex,
  });

  String _getRunningAdvice() {
    if (current.weatherCode >= 61 && current.weatherCode <= 99) {
      return 'غير مناسب بسبب الأمطار والعواصف';
    } else if (current.temperature > 34) {
      return 'الطقس حار جداً، يفضل التمارين المغلقة';
    } else if (current.temperature < 5) {
      return 'برودة شديدة، ارتدِ ملابس ثقيلة';
    } else {
      return 'ممتاز جداً للرياضة والجري الخارجي';
    }
  }

  String _getCarWashAdvice() {
    if (current.weatherCode >= 51 && current.weatherCode <= 99) {
      return 'تجنب الغسيل اليوم بسبب احتمالية المطر';
    } else {
      return 'وقت مناسب جداً لغسيل السيارة';
    }
  }

  String _getClothingAdvice() {
    if (current.temperature > 28) {
      return 'ملابس صيفية خفيفة مع نظارة شمسية';
    } else if (current.temperature >= 18 && current.temperature <= 28) {
      return 'ملابس معتدلة ومريحة';
    } else {
      return 'ملابس دافئة / معطف شتوي';
    }
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
              Icon(Icons.directions_run_rounded, color: Colors.amberAccent, size: 20),
              SizedBox(width: 6),
              Text(
                'مؤشرات ونصائح الأنشطة اليومية',
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
              padding: const EdgeInsets.all(16),
              decoration: WeatherColors.glassDecoration(borderRadius: 20, opacity: 0.15),
              child: Column(
                children: [
                  _buildActivityRow(
                    icon: Icons.directions_run_rounded,
                    title: 'ممارسة الرياضة والجري',
                    advice: _getRunningAdvice(),
                    color: Colors.lightGreenAccent,
                  ),
                  const Divider(color: Colors.white12, height: 20),
                  _buildActivityRow(
                    icon: Icons.directions_car_rounded,
                    title: 'غسيل السيارة',
                    advice: _getCarWashAdvice(),
                    color: Colors.cyanAccent,
                  ),
                  const Divider(color: Colors.white12, height: 20),
                  _buildActivityRow(
                    icon: Icons.checkroom_rounded,
                    title: 'الملابس الموصى بها',
                    advice: _getClothingAdvice(),
                    color: Colors.orangeAccent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow({
    required IconData icon,
    required String title,
    required String advice,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                advice,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
