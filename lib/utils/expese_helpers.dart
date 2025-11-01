import '../models/expense.dart';

class ExpenseHelpers {
  /// Ambil transaksi pada hari tertentu
  static List<Expense> getExpensesByDay(List<Expense> expenses, DateTime day) {
    return expenses
        .where((e) =>
            e.date.year == day.year &&
            e.date.month == day.month &&
            e.date.day == day.day)
        .toList();
  }

  /// Ambil transaksi hanya bulan & tahun tertentu
  static List<Expense> getExpensesByMonth(
      List<Expense> expenses, int year, int month) {
    return expenses
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
  }

  /// Hitung total pemasukan
  static double getTotalIncome(List<Expense> expenses) {
    return expenses
        .where((e) => e.type == "income")
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Hitung total pengeluaran
  static double getTotalExpense(List<Expense> expenses) {
    return expenses
        .where((e) => e.type == "expense")
        .fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Hitung saldo akhir
  static double getBalance(List<Expense> expenses) {
    return getTotalIncome(expenses) - getTotalExpense(expenses);
  }

  /// Hitung total transaksi harian
  static double getDailyTotal(List<Expense> expenses, DateTime day,
      {String? type}) {
    final daily = getExpensesByDay(expenses, day);
    if (type != null) {
      return daily
          .where((e) => e.type == type)
          .fold(0.0, (sum, e) => sum + e.amount);
    }
    return daily.fold(0.0, (sum, e) => sum + e.amount);
  }

  /// Cek apakah transaksi bisa diedit/hapus (hanya hari ini & bulan berjalan)
  static bool canModify(Expense expense) {
    final now = DateTime.now();
    return expense.date.year == now.year &&
        expense.date.month == now.month &&
        expense.date.day == now.day;
  }
}


class DateHelper {
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isSameMonth(DateTime date, DateTime other) {
    return date.year == other.year && date.month == other.month;
  }
}