class DateHelper {
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static String formatDate(DateTime date) {
    return "${date.day}-${date.month}-${date.year}";
  }
}
