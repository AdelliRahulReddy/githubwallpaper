import 'package:intl/intl.dart';

class AppDateUtils {
  static String getCurrentMonthName() {
    return DateFormat('MMMM').format(DateTime.now());
  }

  static int getCurrentDayOfMonth() {
    return DateTime.now().day;
  }

  static int getDaysInCurrentMonth() {
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    final lastDayOfMonth = nextMonth.subtract(Duration(days: 1));
    return lastDayOfMonth.day;
  }

  static String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  static String getDayName(DateTime date) {
    return DateFormat('EEEE').format(date);
  }

  static DateTime getStartOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static DateTime getEndOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0);
  }

  static DateTime getYearStart() {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  static DateTime getYearEnd() {
    final now = DateTime.now();
    return DateTime(now.year, 12, 31);
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isInCurrentMonth(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month;
  }

  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static DateTime parseDate(String dateString) {
    return DateTime.parse(dateString);
  }
}
