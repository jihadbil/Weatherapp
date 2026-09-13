import 'package:intl/intl.dart';

class UnitHelper {
  /// Converts Celsius temperature to string with unit
  static String formatTemp(
    double tempC, {
    bool isCelsius = true,
    bool showUnit = true,
    bool includeLetter = false,
  }) {
    if (isCelsius) {
      final unitStr = showUnit ? (includeLetter ? '°C' : '°') : '';
      return '${tempC.round()}$unitStr';
    } else {
      final tempF = (tempC * 9.0 / 5.0) + 32.0;
      final unitStr = showUnit ? (includeLetter ? '°F' : '°') : '';
      return '${tempF.round()}$unitStr';
    }
  }

  /// Converts wind speed (km/h) to string with unit
  static String formatWind(double windKmh, {bool useKmh = true}) {
    if (useKmh) {
      return '${windKmh.round()} كم/س';
    } else {
      final windMph = windKmh * 0.621371;
      return '${windMph.round()} mph';
    }
  }

  /// Converts pressure (hPa) to string with unit
  static String formatPressure(double pressureHpa, {String unit = 'hPa'}) {
    if (unit == 'mmHg') {
      final mm = pressureHpa * 0.750062;
      return '${mm.round()} ملم زئبق';
    }
    return '${pressureHpa.round()} hPa';
  }

  /// Formats time in 12h or 24h
  static String formatTime(DateTime time, {bool is24Hour = false}) {
    if (is24Hour) {
      return DateFormat('HH:mm').format(time);
    } else {
      return DateFormat('hh:mm a')
          .format(time)
          .replaceAll('AM', 'ص')
          .replaceAll('PM', 'م');
    }
  }

  /// Formats short time (hour:minute)
  static String formatShortTime(DateTime time, {bool is24Hour = false}) {
    if (is24Hour) {
      return DateFormat('HH:mm').format(time);
    } else {
      return DateFormat('h:mm').format(time);
    }
  }
}
