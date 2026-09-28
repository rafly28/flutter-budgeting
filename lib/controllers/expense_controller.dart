import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'saving_controller.dart';
import '../models/expense.dart';
import '../models/monthly_report.dart';
import '../models/saving_account.dart';
import '../services/notification_service.dart';

class ExpenseController extends ChangeNotifier {
  static const mainAccountName = 'Budget Utama';

  final SavingController _savingController;
  final Box<Expense> _box = Hive.box<Expense>('expensesBox');
  final Box<MonthlyReport> _reportBox = Hive.box<MonthlyReport>(
    'monthlyReportsBox',
  );

  ExpenseController(this._savingController);

  // Ambil semua transaksi
  List<Expense> get expenses => _box.values.toList();

  // Ambil semua laporan bulanan
  List<MonthlyReport> get monthlyReports => _reportBox.values.toList();

  bool accountExists(String accountName) {
    return accountName == mainAccountName ||
        _savingAccount(accountName) != null;
  }

  double balanceFor(String accountName) {
    if (accountName == mainAccountName) return balance;
    return _savingAccount(accountName)?.balance ?? 0;
  }

  bool canAfford(String accountName, double amount) {
    return accountExists(accountName) &&
        amount.isFinite &&
        amount >= 0 &&
        balanceFor(accountName) >= amount;
  }

  // Tambah transaksi dan terapkan dampaknya ke rekening non-utama.
  Future<bool> addExpense(Expense expense) async {
    final effects = _validatedEffects(expense);
    if (effects == null || !_canApply(expense, effects)) return false;
    if (!await _applyEffects(effects)) return false;

    try {
      await _box.add(expense);
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
      return true;
    } catch (error) {
      await _applyEffects(effects, multiplier: -1);
      if (kDebugMode) print('Gagal menyimpan transaksi: $error');
      return false;
    }
  }

  // Hapus berdasarkan key objek agar aman untuk daftar terfilter/terbalik.
  Future<bool> removeExpense(Expense expense) async {
    final key = expense.key;
    final storedExpense = key == null ? null : _box.get(key);
    if (storedExpense == null) return false;

    final effects = _validatedEffects(storedExpense);
    if (effects == null || !await _applyEffects(effects, multiplier: -1)) {
      return false;
    }

    try {
      await _box.delete(key);
      if (kDebugMode) {
        print('Expense key $key dihapus dari Hive');
      }
      notifyListeners();
      return true;
    } catch (error) {
      await _applyEffects(effects);
      if (kDebugMode) print('Gagal menghapus transaksi: $error');
      return false;
    }
  }

  // Edit memakai snapshot lama dan objek baru supaya saldo dapat dibalik tepat.
  Future<bool> updateExpense(
    Expense previousExpense,
    Expense updatedExpense,
  ) async {
    if (identical(previousExpense, updatedExpense)) return false;

    final key = previousExpense.key;
    final storedExpense = key == null ? null : _box.get(key);
    if (storedExpense == null) return false;

    updatedExpense.planId ??= storedExpense.planId;
    updatedExpense.debtId ??= storedExpense.debtId;

    final previousEffects = _validatedEffects(storedExpense);
    final updatedEffects = _validatedEffects(updatedExpense);
    if (previousEffects == null ||
        updatedEffects == null ||
        !_canApply(
          updatedExpense,
          updatedEffects,
          previousEffects: previousEffects,
        )) {
      return false;
    }

    final netEffects = <String, double>{...updatedEffects};
    for (final entry in previousEffects.entries) {
      netEffects.update(
        entry.key,
        (value) => value - entry.value,
        ifAbsent: () => -entry.value,
      );
    }
    if (!await _applyEffects(netEffects)) return false;

    try {
      await _box.put(key, updatedExpense);
      if (kDebugMode) {
        print(
          "Expense key $key diperbarui: ${updatedExpense.amount}, "
          "kategori: ${updatedExpense.category}, "
          "tipe: ${updatedExpense.type}, "
          "note: ${updatedExpense.note}",
        );
      }
      notifyListeners();
      return true;
    } catch (error) {
      await _applyEffects(netEffects, multiplier: -1);
      if (kDebugMode) print('Gagal memperbarui transaksi: $error');
      return false;
    }
  }

  // Hitung total pemasukan (semua data)
  double get totalIncome {
    double baseIncome = _box.values
        .where((e) => e.type == "income" && e.source == mainAccountName)
        .fold(0.0, (sum, e) => sum + e.amount);
    double transferIn = _box.values
        .where(
          (e) =>
              e.type == 'transfer' &&
              _transferDestination(e) == mainAccountName,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
    return baseIncome + transferIn;
  }

  // Hitung total pengeluaran (semua data)
  double get totalExpense {
    double baseExpense = _box.values
        .where((e) => e.type == "expense" && e.source == mainAccountName)
        .fold(0.0, (sum, e) => sum + e.amount);
    double transferOut = _box.values
        .where((e) => e.type == 'transfer' && e.source == mainAccountName)
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

  SavingAccount? _savingAccount(String accountName) {
    for (final account in _savingController.savings) {
      if (account.name == accountName) return account;
    }
    return null;
  }

  String? _transferDestination(Expense expense) {
    final note = expense.note;
    if (note == null) return null;

    final prefix = 'Dari ${expense.source} ke ';
    if (!note.startsWith(prefix)) return null;

    final end = note.indexOf('.', prefix.length);
    if (end < 0) return null;

    final destination = note.substring(prefix.length, end).trim();
    return destination.isEmpty ? null : destination;
  }

  Map<String, double>? _validatedEffects(Expense expense) {
    if (!expense.amount.isFinite || expense.amount <= 0) return null;

    final effects = <String, double>{};
    switch (expense.type) {
      case 'income':
        effects[expense.source] = expense.amount;
        break;
      case 'expense':
        effects[expense.source] = -expense.amount;
        break;
      case 'transfer':
        final destination = _transferDestination(expense);
        if (destination == null || destination == expense.source) return null;
        effects[expense.source] = -expense.amount;
        effects.update(
          destination,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
        break;
      default:
        return null;
    }

    return effects.keys.every(accountExists) ? effects : null;
  }

  bool _canApply(
    Expense expense,
    Map<String, double> effects, {
    Map<String, double>? previousEffects,
  }) {
    if (expense.type != 'expense' && expense.type != 'transfer') return true;

    final balanceAfterRevert =
        balanceFor(expense.source) - (previousEffects?[expense.source] ?? 0);
    return balanceAfterRevert >= expense.amount &&
        effects[expense.source] == -expense.amount;
  }

  Future<bool> _applyEffects(
    Map<String, double> effects, {
    double multiplier = 1,
  }) async {
    final applied = <MapEntry<String, double>>[];
    try {
      for (final entry in effects.entries) {
        final delta = entry.value * multiplier;
        if (entry.key == mainAccountName || delta == 0) continue;

        final account = _savingAccount(entry.key);
        if (account == null) throw StateError('Akun ${entry.key} tidak ada');
        await _savingController.updateBalance(
          account,
          delta.abs(),
          delta > 0 ? 'income' : 'expense',
        );
        applied.add(MapEntry(entry.key, delta));
      }
      return true;
    } catch (error) {
      for (final entry in applied.reversed) {
        final account = _savingAccount(entry.key);
        if (account == null) continue;
        try {
          await _savingController.updateBalance(
            account,
            entry.value.abs(),
            entry.value > 0 ? 'expense' : 'income',
          );
        } catch (rollbackError) {
          if (kDebugMode) {
            print('Gagal mengembalikan saldo rekening: $rollbackError');
          }
        }
      }
      if (kDebugMode) print('Gagal memperbarui saldo rekening: $error');
      return false;
    }
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
