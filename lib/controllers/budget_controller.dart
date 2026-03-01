import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/category_budget.dart';

class BudgetController extends ChangeNotifier {
  final Box<CategoryBudget> _box = Hive.box<CategoryBudget>('budgetBox');

  // Ambil limit untuk kategori tertentu (kembalikan 0 jika belum disetel)
  double getBudgetLimit(String categoryName) {
    try {
      final budget = _box.values.firstWhere(
        (b) => b.categoryName == categoryName,
      );
      return budget.limitAmount;
    } catch (e) {
      return 0.0;
    }
  }

  // Setel atau perbarui limit budget
  void setBudgetLimit(String categoryName, double amount) {
    try {
      // Jika sudah ada, update
      final budget = _box.values.firstWhere(
        (b) => b.categoryName == categoryName,
      );
      budget.limitAmount = amount;
      budget.save();
    } catch (e) {
      // Jika belum ada, buat baru
      _box.add(CategoryBudget(categoryName: categoryName, limitAmount: amount));
    }
    notifyListeners();
  }
}
