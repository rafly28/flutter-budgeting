import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../models/monthly_report.dart';

class ExpenseController extends ChangeNotifier {
  final Box<Expense> _box = Hive.box<Expense>('expensesBox');
  final Box<MonthlyReport> _reportBox = Hive.box<MonthlyReport>(
    'monthlyReportsBox',
  );

  // Ambil semua transaksi
  List<Expense> get expenses => _box.values.toList();

  // Ambil semua laporan bulanan
  List<MonthlyReport> get monthlyReports => _reportBox.values.toList();

  // Tambah transaksi
  void addExpense(Expense expense) {
    _box.add(expense);
    if (kDebugMode) {
      print(
        "✅ Expense disimpan ke Hive: ${expense.amount}, "
        "kategori: ${expense.category}, "
        "tipe: ${expense.type}, "
        "note: ${expense.note}",
      );
    }
    notifyListeners();
  }

  // Hapus transaksi
  void removeExpense(int index) {
    if (index >= 0 && index < _box.length) {
      _box.deleteAt(index);
      if (kDebugMode) {
        print("🗑️ Expense index $index dihapus dari Hive");
      }
      notifyListeners();
    }
  }

  // Edit transaksi
  void updateExpense(int index, Expense updatedExpense) {
    if (index >= 0 && index < _box.length) {
      _box.putAt(index, updatedExpense);
      if (kDebugMode) {
        print(
          "✏️ Expense index $index diperbarui: ${updatedExpense.amount}, "
          "kategori: ${updatedExpense.category}, "
          "tipe: ${updatedExpense.type}, "
          "note: ${updatedExpense.note}",
        );
      }
      notifyListeners();
    }
  }

  // Hitung total pemasukan (semua data, bukan hanya bulan ini)
  double get totalIncome => _box.values
      .where((e) => e.type == "income")
      .fold(0.0, (sum, e) => sum + e.amount);

  // Hitung total pengeluaran (semua data, bukan hanya bulan ini)
  double get totalExpense => _box.values
      .where((e) => e.type == "expense")
      .fold(0.0, (sum, e) => sum + e.amount);

  // Hitung saldo akhir (semua data, bukan hanya bulan ini)
  double get balance => totalIncome - totalExpense;

  // Tutup bulan → simpan laporan bulanan
  void closeMonth() {
    if (_box.isEmpty) return;

    final now = DateTime.now();
    final monthKey = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final report = MonthlyReport(
      month: monthKey,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: balance,
    );

    _reportBox.put(monthKey, report);

    if (kDebugMode) {
      print(
        "📊 Monthly Report disimpan: $monthKey "
        "(Income: ${report.totalIncome}, "
        "Expense: ${report.totalExpense}, "
        "Balance: ${report.balance})",
      );
    }

    notifyListeners();
  }

  // Filter transaksi berdasarkan bulan & tahun
  List<Expense> getExpensesByMonth(int year, int month) {
    return _box.values
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
  }

  List<Expense> getExpensesByDateRange(DateTime startDate, DateTime endDate) {
    return _box.values.where((e) {
      // Mengambil transaksi yang berada di antara startDate dan endDate
      return e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          e.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  // Hapus transaksi lama lebih dari X bulan
  void cleanupOldExpenses({int months = 6}) {
    final cutoffDate = DateTime(
      DateTime.now().year,
      DateTime.now().month - months,
      DateTime.now().day,
    );

    final toDeleteKeys = _box.keys.where((key) {
      final expense = _box.get(key);
      if (expense == null) return false;
      return expense.date.isBefore(cutoffDate);
    }).toList();

    for (var key in toDeleteKeys) {
      _box.delete(key);
    }

    if (toDeleteKeys.isNotEmpty) {
      if (kDebugMode) {
        print(
          "🧹 ${toDeleteKeys.length} transaksi lama dihapus (lebih dari $months bulan)",
        );
      }
      notifyListeners();
    }
  }
}
