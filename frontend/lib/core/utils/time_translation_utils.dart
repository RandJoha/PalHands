import '../constants/app_strings.dart';

class TimeTranslationUtils {
  /// Efficient method to get time ago string for any time period
  static String getTimeAgoString(int value, String unit, String languageCode) {
    return AppStrings.getTimeAgo(value, unit, languageCode);
  }

  /// Get month name for any month number (1-12)
  static String getMonthName(int month, String languageCode) {
    return AppStrings.getMonthName(month, languageCode);
  }

  /// Format a date with proper month translation
  static String formatDate(int day, int month, int year, String languageCode) {
    String monthName = getMonthName(month, languageCode);
    
    if (languageCode == 'ar') {
      return '$day $monthName $year';
    } else {
      return '$monthName $day, $year';
    }
  }

  /// Get relative time string (e.g., "2 hours ago", "قبل ساعتين")
  static String getRelativeTime(DateTime dateTime, String languageCode) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return getTimeAgoString(difference.inSeconds, 'second', languageCode);
    } else if (difference.inMinutes < 60) {
      return getTimeAgoString(difference.inMinutes, 'minute', languageCode);
    } else if (difference.inHours < 24) {
      return getTimeAgoString(difference.inHours, 'hour', languageCode);
    } else if (difference.inDays < 7) {
      return getTimeAgoString(difference.inDays, 'day', languageCode);
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).round();
      return getTimeAgoString(weeks, 'week', languageCode);
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).round();
      return getTimeAgoString(months, 'month', languageCode);
    } else {
      final years = (difference.inDays / 365).round();
      return getTimeAgoString(years, 'year', languageCode);
    }
  }

  /// Example usage methods
  static String getExampleTimeStrings(String languageCode) {
    return '''
Examples of time translations:
- 1 second ago: ${getTimeAgoString(1, 'second', languageCode)}
- 2 minutes ago: ${getTimeAgoString(2, 'minute', languageCode)}
- 3 hours ago: ${getTimeAgoString(3, 'hour', languageCode)}
- 1 day ago: ${getTimeAgoString(1, 'day', languageCode)}
- 2 weeks ago: ${getTimeAgoString(2, 'week', languageCode)}
- 1 month ago: ${getTimeAgoString(1, 'month', languageCode)}
- 1 year ago: ${getTimeAgoString(1, 'year', languageCode)}
- March: ${getMonthName(3, languageCode)}
- January: ${getMonthName(1, languageCode)}
''';
  }
} 