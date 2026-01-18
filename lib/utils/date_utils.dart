class AppDateUtils {
  // Get current date in YYYY-MM-DD format
  static String getCurrentDate() {
    final now = DateTime.now();
    return '${now.year}-${_padZero(now.month)}-${_padZero(now.day)}';
  }

  // Get current month start date (YYYY-MM-DDTHH:MM:SSZ format for API)
  static String getCurrentMonthStart() {
    final now = DateTime.now();
    return '${now.year}-${_padZero(now.month)}-01T00:00:00Z';
  }

  // Get current month end date
  static String getCurrentMonthEnd() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return '${now.year}-${_padZero(now.month)}-${_padZero(lastDay)}T23:59:59Z';
  }

  // Get year range for API (full year needed, we'll filter after)
  static String getYearStart() {
    final now = DateTime.now();
    return '${now.year}-01-01T00:00:00Z';
  }

  static String getYearEnd() {
    final now = DateTime.now();
    return '${now.year}-12-31T23:59:59Z';
  }

  // Get current month name
  static String getCurrentMonthName() {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[DateTime.now().month - 1];
  }

  // Get days in current month
  static int getDaysInCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }

  // Get current day of month
  static int getCurrentDayOfMonth() {
    return DateTime.now().day;
  }

  // Check if date is in current month
  static bool isInCurrentMonth(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month;
    } catch (e) {
      return false;
    }
  }

  // Check if date is today
  static bool isToday(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    } catch (e) {
      return false;
    }
  }

  // Helper: Pad single digit with zero
  static String _padZero(int value) {
    return value.toString().padLeft(2, '0');
  }

  // Format DateTime for display
  static String formatDateTime(DateTime dateTime) {
    return '${getCurrentMonthName()} ${dateTime.day}, ${dateTime.year} at ${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}';
  }
}
