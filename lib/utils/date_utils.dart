class DateUtilsID {
  static const _bulan = [
    "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
    "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
  ];

  static String format(DateTime date) {
    final day = date.day;
    final month = _bulan[date.month - 1];
    final year = date.year;
    return "$day $month $year"; // contoh: 28 Sep 2025
  }
}
