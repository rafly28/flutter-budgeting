import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/saving_account.dart';

class SavingController extends ChangeNotifier {
  final Box<SavingAccount> _box = Hive.box<SavingAccount>('savingsBox');

  List<SavingAccount> get savings => _box.values.toList();

  double get totalSavingsBalance =>
      _box.values.fold(0.0, (sum, item) => sum + item.balance);

  // 👇 UPDATE: Tambah parameter baru
  void addSavingAccount(
    String name,
    double initialBalance,
    String bank,
    String accNum,
    String holderName,
  ) {
    _box.add(
      SavingAccount(
        name: name,
        balance: initialBalance,
        bankName: bank,
        accountNumber: accNum,
        accountHolderName: holderName,
      ),
    );
    notifyListeners();
  }

  // 👇 UPDATE: Fungsi edit
  void updateSavingDetails(
    SavingAccount account,
    String newName,
    String bank,
    String accNum,
    String holderName,
    double newBalance,
  ) {
    account.name = newName;
    account.bankName = bank;
    account.accountNumber = accNum;
    account.accountHolderName = holderName;
    account.balance = newBalance;
    account.save();
    notifyListeners();
  }

  void updateBalance(SavingAccount account, double amount, String type) {
    if (type == 'income') {
      account.balance += amount;
    } else if (type == 'expense') {
      account.balance -= amount;
    }
    account.save();
    notifyListeners();
  }

  void deleteSaving(SavingAccount account) {
    account.delete();
    notifyListeners();
  }
}
