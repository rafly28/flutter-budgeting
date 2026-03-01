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

  // Memberikan kategori bawaan jika database masih kosong
  void _seedDefaultCategories() {
    if (_box.isEmpty) {
      final defaults = [
        TransactionCategory(name: 'Gaji', type: 'income'),
        TransactionCategory(name: 'Bonus', type: 'income'),
        TransactionCategory(name: 'Makanan', type: 'expense'),
        TransactionCategory(name: 'Transportasi', type: 'expense'),
        TransactionCategory(name: 'Hiburan', type: 'expense'),
        TransactionCategory(name: 'Tagihan', type: 'expense'),
      ];
      for (var cat in defaults) {
        _box.add(cat);
      }
    }
  }

  // Ambil list kategori pemasukan
  List<TransactionCategory> get incomeCategories =>
      _box.values.where((c) => c.type == 'income').toList();

  // Ambil list kategori pengeluaran
  List<TransactionCategory> get expenseCategories =>
      _box.values.where((c) => c.type == 'expense').toList();

  // CREATE
  void addCategory(String name, String type) {
    _box.add(TransactionCategory(name: name, type: type));
    notifyListeners();
  }

  // UPDATE
  void updateCategory(TransactionCategory category, String newName) {
    category.name = newName;
    category.save(); // Fitur canggih dari HiveObject
    notifyListeners();
  }

  // DELETE
  void deleteCategory(TransactionCategory category) {
    category.delete(); // Fitur canggih dari HiveObject
    notifyListeners();
  }
}
