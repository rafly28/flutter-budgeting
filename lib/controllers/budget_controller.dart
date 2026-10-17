import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/category_budget.dart';

class BudgetController extends ChangeNotifier {
  final Box<CategoryBudget> _box = Hive.box<CategoryBudget>('budgetBox');

  /// Beri tahu pendengar bahwa data di luar controller berubah (mis. setelah
  /// restore backup yang mengganti isi box).
  void refresh() => notifyListeners();

  // Ambil limit untuk kategori tertentu (kembalikan 0 jika belum disetel)
  double getBudgetLimit(String categoryName) {
    final budget = findBudget(categoryName);
    return budget?.limitAmount ?? 0.0;
  }

  /// Baris limit untuk [categoryName], atau null kalau belum diatur.
  CategoryBudget? findBudget(String categoryName) {
    for (final budget in _box.values) {
      if (budget.categoryName == categoryName) return budget;
    }
    return null;
  }

  // Setel atau perbarui limit budget
  void setBudgetLimit(String categoryName, double amount) {
    final budget = findBudget(categoryName);
    if (budget != null) {
      budget.limitAmount = amount;
      budget.save();
    } else {
      _box.add(CategoryBudget(categoryName: categoryName, limitAmount: amount));
    }
    notifyListeners();
  }

  /// Hapus limit untuk [categoryName]. Dipakai saat kategori dihapus supaya
  /// tidak ada limit yatim yang diam-diam aktif lagi kalau nama yang sama
  /// dipakai ulang.
  Future<bool> clearBudgetLimit(String categoryName) async {
    final budget = findBudget(categoryName);
    if (budget == null) return false;
    await budget.delete();
    notifyListeners();
    return true;
  }
}
