import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/transaction_category.dart';
import '../models/expense.dart';
import '../models/category_budget.dart';
import '../models/plan_item.dart';

class CategoryController extends ChangeNotifier {
  /// Beri tahupendengar bahwa data di luar controller berubah (mis. setelah
  /// restore backup yang mengganti isi box). Dipanggil juga setelah add/remove
  /// sinkron, jadi regenerate tampilan tanpa perlu rebuild manual.
  void refresh() => notifyListeners();

  final Box<TransactionCategory> _box = Hive.box<TransactionCategory>(
    'categoryBox',
  );

  /// Nama yang dipakai DebtController sebagai penanda transaksi hutang/piutang.
  /// Kategori milik pengguna tidak boleh memakai nama ini, kalau tidak
  /// transaksinya bisa ikut terdeteksi dan terhapus baris debt.
  static const reservedNames = <String>{
    'Semua',
    'Hutang',
    'Piutang',
    'Bayar Hutang',
    'Terima Cicilan',
  };

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
    for (final category in _box.values) {
      if (category.name == name) return category;
    }
    return null;
  }

  /// Alasan kenapa [name] tidak boleh dipakai, atau null kalau valid.
  String? validateName(String name, {TransactionCategory? ignoring}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Nama kategori tidak boleh kosong.';
    if (reservedNames.contains(trimmed)) {
      return '"$trimmed" adalah nama khusus yang dipakai sistem.';
    }
    final taken = _box.values.any(
      (other) => other.key != ignoring?.key && other.name == trimmed,
    );
    if (taken) return 'Kategori "$trimmed" sudah ada.';
    return null;
  }

  bool addCategory(
    String name,
    String type, {
    int? iconCodePoint,
    String? iconFontFamily,
    String budgetGroup = 'needs',
  }) {
    if (validateName(name) != null) return false;
    if (type != 'income' && type != 'expense') return false;

    _box.add(
      TransactionCategory(
        name: name.trim(),
        type: type,
        iconCodePoint: iconCodePoint,
        iconFontFamily: iconFontFamily,
        budgetGroup: budgetGroup,
      ),
    );
    notifyListeners();
    return true;
  }

  /// Ubah kategori. Kalau namanya berubah, semua baris yang menyimpan nama
  /// lama ikut diperbarui supaya transaksi, limit budget, dan rencana tidak
  /// jadi yatim.
  Future<bool> updateCategory(
    TransactionCategory category,
    String newName, {
    int? iconCodePoint,
    String? iconFontFamily,
    String? budgetGroup,
  }) async {
    if (validateName(newName, ignoring: category) != null) return false;

    final oldName = category.name;
    final trimmed = newName.trim();
    final isRenaming = trimmed != oldName;

    category.name = trimmed;
    if (iconCodePoint != null) category.iconCodePoint = iconCodePoint;
    if (iconFontFamily != null) category.iconFontFamily = iconFontFamily;
    if (budgetGroup != null) category.budgetGroup = budgetGroup;

    if (isRenaming) {
      await _migrateReferences(oldName, trimmed);
    }

    await category.save();
    notifyListeners();
    return true;
  }

  /// Jumlah transaksi + rencana yang masih menunjuk ke [name]. Ini yang
  /// memblokir penghapusan — limit budget ikut dibersihkan sendiri, bukan
  /// dipakai sebagai alasan menolak.
  int referenceCount(String name) {
    var count = 0;
    if (Hive.isBoxOpen('expensesBox')) {
      count += Hive.box<Expense>(
        'expensesBox',
      ).values.where((row) => row.category == name).length;
    }
    if (Hive.isBoxOpen('planBox')) {
      count += Hive.box<PlanItem>(
        'planBox',
      ).values.where((row) => row.category == name).length;
    }
    return count;
  }

  /// True kalau masih ada limit budget tersimpan untuk [name].
  bool hasBudgetLimit(String name) {
    if (!Hive.isBoxOpen('budgetBox')) return false;
    return Hive.box<CategoryBudget>(
      'budgetBox',
    ).values.any((row) => row.categoryName == name);
  }

  /// Hapus kategori hanya kalau tidak ada transaksi atau rencana yang masih
  /// menunjuk ke sana. Memblokir lebih aman daripada meninggalkan baris yatim
  /// yang tidak bisa dibersihkan. Limit budget ikut dihapus supaya tidak
  /// diam-diam aktif lagi kalau nama yang sama dipakai ulang.
  Future<bool> deleteCategory(TransactionCategory category) async {
    if (referenceCount(category.name) > 0) return false;

    if (Hive.isBoxOpen('budgetBox')) {
      final budgetBox = Hive.box<CategoryBudget>('budgetBox');
      for (final budget in budgetBox.values
          .where((row) => row.categoryName == category.name)) {
        await budget.delete();
      }
    }

    try {
      await category.delete();
    } catch (_) {
      return false;
    }
    notifyListeners();
    return true;
  }

  /// Ikuti perubahan nama kategori ke Expense.category,
  /// CategoryBudget.categoryName, dan PlanItem.category.
  Future<void> _migrateReferences(String oldName, String newName) async {
    if (Hive.isBoxOpen('expensesBox')) {
      final box = Hive.box<Expense>('expensesBox');
      for (final expense in box.values.where((e) => e.category == oldName)) {
        expense.category = newName;
        await expense.save();
      }
    }
    if (Hive.isBoxOpen('budgetBox')) {
      final box = Hive.box<CategoryBudget>('budgetBox');
      for (final budget in box.values.where((b) => b.categoryName == oldName)) {
        budget.categoryName = newName;
        await budget.save();
      }
    }
    if (Hive.isBoxOpen('planBox')) {
      final box = Hive.box<PlanItem>('planBox');
      for (final plan in box.values.where((p) => p.category == oldName)) {
        plan.category = newName;
        await plan.save();
      }
    }
  }
}