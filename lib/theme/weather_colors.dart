import 'package:flutter/material.dart';

class WeatherColors {
  /// Returns gradient colors based on condition and time of day
  static List<Color> getThemeGradient(int code, bool isDay) {
    if (!isDay) {
      return [
        const Color(0xFF0D1B2A),
        const Color(0xFF1B263B),
        const Color(0xFF415A77),
      ];
    }

    switch (code) {
      case 0: // Sunny / Clear
        return [
          const Color(0xFF2193B0),
          const Color(0xFF6DD5ED),
        ];
      case 1:
      case 2: // Partly Cloudy
        return [
          const Color(0xFF3A6073),
          const Color(0xFF3A7BD5),
        ];
      case 3: // Overcast
      case 45:
      case 48: // Fog
        return [
          const Color(0xFF525252),
          const Color(0xFF3D72B4),
        ];
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65: // Rain
      case 80:
      case 81:
      case 82:
        return [
          const Color(0xFF1F1C2C),
          const Color(0xFF928DAB),
        ];
      case 95:
      case 96:
      case 99: // Thunderstorm
        return [
          const Color(0xFF141E30),
          const Color(0xFF243B55),
        ];
      default:
        return [
          const Color(0xFF2193B0),
          const Color(0xFF6DD5ED),
        ];
    }
  }

  // Glassmorphic Decoration helper
  static BoxDecoration glassDecoration({
    double borderRadius = 20.0,
    double opacity = 0.18,
  }) {
    return BoxDecoration(
      color: Colors.white.withOpacity(opacity),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          spreadRadius: 2,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
