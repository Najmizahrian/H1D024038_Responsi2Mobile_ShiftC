import 'package:flutter/material.dart';

/// Helper untuk memetakan WMO Weather Code dari Open-Meteo ke deskripsi & ikon,
/// serta memformat tanggal perkiraan cuaca harian.
class WeatherCodeHelper {
  static String getDescription(int code) {
    switch (code) {
      case 0:
        return 'Cerah';
      case 1:
        return 'Umumnya Cerah';
      case 2:
        return 'Berawan Sebagian';
      case 3:
        return 'Mendung';
      case 45:
      case 48:
        return 'Berkabut';
      case 51:
      case 53:
      case 55:
        return 'Gerimis';
      case 56:
      case 57:
        return 'Gerimis Beku';
      case 61:
        return 'Hujan Ringan';
      case 63:
        return 'Hujan Sedang';
      case 65:
        return 'Hujan Lebat';
      case 66:
      case 67:
        return 'Hujan Beku';
      case 71:
      case 73:
      case 75:
      case 77:
        return 'Hujan Salju';
      case 80:
      case 81:
      case 82:
        return 'Hujan Deras';
      case 85:
      case 86:
        return 'Hujan Salju Deras';
      case 95:
        return 'Badai Petir';
      case 96:
      case 99:
        return 'Badai Petir & Hujan Es';
      default:
        return 'Tidak Diketahui';
    }
  }

  static IconData getIcon(int code) {
    if (code == 0) return Icons.wb_sunny_rounded;
    if (code == 1 || code == 2) return Icons.wb_cloudy_rounded;
    if (code == 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.grain_rounded;
    if (code >= 71 && code <= 77) return Icons.ac_unit_rounded;
    if (code >= 80 && code <= 82) return Icons.umbrella_rounded;
    if (code >= 85 && code <= 86) return Icons.ac_unit_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.cloud_queue_rounded;
  }

  static List<Color> getGradientColors(int code) {
    if (code == 0 || code == 1) {
      return [const Color(0xFF1E88E5), const Color(0xFF42A5F5)];
    }
    if (code == 2 || code == 3 || code == 45 || code == 48) {
      return [const Color(0xFF546E7A), const Color(0xFF78909C)];
    }
    if (code >= 95) {
      return [const Color(0xFF283593), const Color(0xFF3949AB)];
    }
    return [const Color(0xFF1565C0), const Color(0xFF283593)];
  }

  static String formatDayDate(String isoDate, int index) {
    if (index == 0) return 'Hari Ini';
    if (index == 1) return 'Besok';

    final parsed = DateTime.tryParse(isoDate);
    if (parsed == null) return isoDate;

    const days = ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    final dayName = days[parsed.weekday % 7];
    final monthName = months[parsed.month - 1];
    return '$dayName, ${parsed.day} $monthName';
  }
}
