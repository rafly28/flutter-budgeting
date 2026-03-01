import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/saving_account.dart';

class SavingController extends ChangeNotifier {
  final Box<SavingAccount> _box = Hive.box<SavingAccount>('savingsBox');

  List<SavingAccount> get savings => _box.values.toList();

  // Hitung total semua uang di tabungan
  double get totalSavingsBalance =>
      _box.values.fold(0.0, (sum, item) => sum + item.balance);

  // Buat cabang tabungan baru
  void addSavingAccount(String name, double initialBalance) {
    _box.add(SavingAccount(name: name, balance: initialBalance));
    notifyListeners();
  }

  // Update nama tabungan
  void updateSavingName(SavingAccount account, String newName) {
    account.name = newName;
    account.save();
    notifyListeners();
  }

  // Tambah/Kurangi saldo tabungan (digunakan saat ada transaksi)
  void updateBalance(SavingAccount account, double amount, String type) {
    if (type == 'income') {
      account.balance += amount;
    } else if (type == 'expense') {
      account.balance -= amount;
    }
    account.save();
    notifyListeners();
  }

  // Hapus tabungan
  void deleteSaving(SavingAccount account) {
    account.delete();
    notifyListeners();
  }
}
