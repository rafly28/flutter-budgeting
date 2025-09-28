import 'package:flutter/foundation.dart';
import '../models/expense.dart';

class ExpenseController extends ChangeNotifier {
  final List<Expense> _expenses = [];

  List<Expense> get expenses => _expenses;

  void addExpense(Expense expense) {
    _expenses.add(expense);
    if (kDebugMode) {
      print("Expense ditambahkan: ${expense.amount}, "
          "kategori: ${expense.category}, "
          "tipe: ${expense.type}, "
          "note: ${expense.note}");
    }
    notifyListeners();
  }

  void removeExpense(int index) {
    if (index >= 0 && index < _expenses.length) {
      _expenses.removeAt(index);
      notifyListeners();
    }
  }

  // Hitung total pemasukan
  double get totalIncome => _expenses
      .where((e) => e.type == "income")
      .fold(0, (sum, e) => sum + e.amount);

  // Hitung total pengeluaran
  double get totalExpense => _expenses
      .where((e) => e.type == "expense")
      .fold(0, (sum, e) => sum + e.amount);

  // Hitung saldo akhir
  double get balance => totalIncome - totalExpense;
}
