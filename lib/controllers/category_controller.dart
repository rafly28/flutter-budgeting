import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/transaction_category.dart';

class CategoryController extends ChangeNotifier {
  final Box<TransactionCategory> _box = Hive.box<TransactionCategory>(
    'categoryBox',
  );

  CategoryController() {
    _seedDefaultCategories();
  }

  void _seedDefaultCategories() {
    if (_box.isEmpty) {
      final defaults = [
        TransactionCategory(name: 'Gaji', type: 'income', iconCodePoint: 0xf0204, iconFontFamily: 'MaterialIcons', budgetGroup: 'needs'),
        TransactionCategory(name: 'Bonus', type: 'income', iconCodePoint: 0xf0423, iconFontFamily: 'MaterialIcons', budgetGroup: 'needs'),
        TransactionCategory(name: 'Makanan', type: 'expense', iconCodePoint: 0xf0112, iconFontFamily: 'MaterialIcons', budgetGroup: 'needs'),
        TransactionCategory(name: 'Transportasi', type: 'expense', iconCodePoint: 0xf0481, iconFontFamily: 'MaterialIcons', budgetGroup: 'needs'),
        TransactionCategory(name: 'Hiburan', type: 'expense', iconCodePoint: 0xf03b5, iconFontFamily: 'MaterialIcons', budgetGroup: 'wants'),
        TransactionCategory(name: 'Tabungan', type: 'expense', iconCodePoint: 0xf053a, iconFontFamily: 'MaterialIcons', budgetGroup: 'savings'),
        TransactionCategory(name: 'Tagihan', type: 'expense', iconCodePoint: 0xf0140, iconFontFamily: 'MaterialIcons', budgetGroup: 'needs'),
      ];
      for (var cat in defaults) {
        _box.add(cat);
      }
    }
  }

  List<TransactionCategory> get incomeCategories =>
      _box.values.where((c) => c.type == 'income').toList();

  List<TransactionCategory> get expenseCategories =>
      _box.values.where((c) => c.type == 'expense').toList();

  TransactionCategory? findByName(String name) {
    try {
      return _box.values.firstWhere((c) => c.name == name);
    } catch (_) {
      return null;
    }
  }

  void addCategory(String name, String type, {int? iconCodePoint, String? iconFontFamily, String budgetGroup = 'needs'}) {
    _box.add(TransactionCategory(
      name: name,
      type: type,
      iconCodePoint: iconCodePoint,
      iconFontFamily: iconFontFamily,
      budgetGroup: budgetGroup,
    ));
    notifyListeners();
  }

  void updateCategory(TransactionCategory category, String newName, {int? iconCodePoint, String? iconFontFamily, String? budgetGroup}) {
    category.name = newName;
    if (iconCodePoint != null) category.iconCodePoint = iconCodePoint;
    if (iconFontFamily != null) category.iconFontFamily = iconFontFamily;
    if (budgetGroup != null) category.budgetGroup = budgetGroup;
    category.save();
    notifyListeners();
  }

  void deleteCategory(TransactionCategory category) {
    category.delete();
    notifyListeners();
  }
}
