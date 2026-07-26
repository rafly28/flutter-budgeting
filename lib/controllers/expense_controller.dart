import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../models/monthly_report.dart';
import '../services/notification_service.dart';

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
        "Transaksi disimpan ke DB: ${expense.amount}, "
        "kategori: ${expense.category}, "
        "tipe: ${expense.type}, "
        "note: ${expense.note}",
      );
    }
    final now = DateTime.now();
    if (expense.date.year == now.year &&
        expense.date.month == now.month &&
        expense.date.day == now.day) {
      NotificationService.skipTodayReminder();
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

  // Hitung total pemasukan (semua data)
  double get totalIncome {
    double baseIncome = _box.values
        .where((e) => e.type == "income" && e.source == 'Budget Utama')
        .fold(0.0, (sum, e) => sum + e.amount);
    double transferIn = _box.values
        .where((e) => e.type == 'transfer' && e.note != null && e.note!.contains("ke Budget Utama"))
        .fold(0.0, (sum, e) => sum + e.amount);
    return baseIncome + transferIn;
  }

  // Hitung total pengeluaran (semua data)
  double get totalExpense {
    double baseExpense = _box.values
        .where((e) => e.type == "expense" && e.source == 'Budget Utama')
        .fold(0.0, (sum, e) => sum + e.amount);
    double transferOut = _box.values
        .where((e) => e.type == 'transfer' && e.source == 'Budget Utama')
        .fold(0.0, (sum, e) => sum + e.amount);
    return baseExpense + transferOut;
  }

  // Hitung saldo akhir (semua data)
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
