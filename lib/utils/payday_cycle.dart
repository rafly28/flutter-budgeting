class PaydayCycle {
  final DateTime start;
  final DateTime end;

  const PaydayCycle({required this.start, required this.end});

  factory PaydayCycle.of(DateTime now, int payday) {
    final day = now.day;
    if (day >= payday) {
      // Siklus berjalan: dari tanggal gajian bulan ini sampai tanggal gajian - 1 bulan depan
      final cycleStart = DateTime(now.year, now.month, payday);
      final cycleEnd = DateTime(now.year, now.month + 1, payday - 1);
      return PaydayCycle(start: cycleStart, end: cycleEnd);
    } else {
      // Siklus berjalan: dari tanggal gajian bulan lalu sampai tanggal gajian - 1 bulan ini
      final cycleStart = DateTime(now.year, now.month - 1, payday);
      final cycleEnd = DateTime(now.year, now.month, payday - 1);
      return PaydayCycle(start: cycleStart, end: cycleEnd);
    }
  }

  bool contains(DateTime date) {
    // Bandingkan hanya tanggal (menggunakan DateUtils.getExpensesByDateRange sudah menangani jam)
    final startNormalized = DateTime(start.year, start.month, start.day);
    final endNormalized = DateTime(end.year, end.month, end.day);
    final dateNormalized = DateTime(date.year, date.month, date.day);
    if (dateNormalized.isBefore(startNormalized)) return false;
    if (dateNormalized.isAfter(endNormalized)) return false;
    return true;
  }
}