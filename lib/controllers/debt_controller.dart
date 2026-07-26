import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/debt.dart';
import '../models/expense.dart';
import 'expense_controller.dart';

class DebtController extends ChangeNotifier {
  final Box<Debt> _box = Hive.box<Debt>('debtBox');
  final ExpenseController _expenseController;

  DebtController(this._expenseController);

  List<Debt> get debts => _box.values.toList();

  List<Debt> get activeHutang =>
      debts.where((d) => d.type == 'hutang' && !d.isSettled).toList();

  List<Debt> get activePiutang =>
      debts.where((d) => d.type == 'piutang' && !d.isSettled).toList();

  void addDebt(Debt debt) {
    _box.put(debt.id, debt);

    // Otomatis buat transaksi di ExpenseController (Budget Utama)
    if (debt.type == 'hutang') {
      // Kita meminjam uang -> Uang masuk ke Budget Utama (Income)
      _expenseController.addExpense(Expense(
        amount: debt.amount,
        category: 'Hutang',
        note: 'Pinjaman dari ${debt.personName}',
        date: debt.createdAt,
        type: 'income',
        source: 'Budget Utama',
      ));
    } else if (debt.type == 'piutang') {
      // Kita meminjamkan uang -> Uang keluar dari Budget Utama (Expense)
      _expenseController.addExpense(Expense(
        amount: debt.amount,
        category: 'Piutang',
        note: 'Dipinjam oleh ${debt.personName}',
        date: debt.createdAt,
        type: 'expense',
        source: 'Budget Utama',
      ));
    }

    notifyListeners();
  }

  void payDebt(Debt debt, double amountToPay) {
    if (amountToPay <= 0) return;

    double newPaidAmount = debt.paidAmount + amountToPay;
    bool isSettled = false;
    
    if (newPaidAmount >= debt.amount) {
      newPaidAmount = debt.amount; // tidak boleh lebih dari total
      isSettled = true;
    }

    debt.paidAmount = newPaidAmount;
    debt.isSettled = isSettled;
    debt.save();

    // Buat transaksi pembayaran
    if (debt.type == 'hutang') {
      // Membayar hutang -> Uang keluar (Expense)
      _expenseController.addExpense(Expense(
        amount: amountToPay,
        category: 'Bayar Hutang',
        note: 'Cicilan hutang ke ${debt.personName}',
        date: DateTime.now(),
        type: 'expense',
        source: 'Budget Utama',
      ));
    } else if (debt.type == 'piutang') {
      // Orang membayar piutang ke kita -> Uang masuk (Income)
      _expenseController.addExpense(Expense(
        amount: amountToPay,
        category: 'Terima Cicilan',
        note: 'Pembayaran piutang dari ${debt.personName}',
        date: DateTime.now(),
        type: 'income',
        source: 'Budget Utama',
      ));
    }

    notifyListeners();
  }

  void deleteDebt(Debt debt) {
    // Note: Kita tidak otomatis menghapus Expense yang sudah tercatat
    // karena mungkin itu akan merusak riwayat transaksi. 
    // Pengguna harus menghapusnya manual di History jika diperlukan.
    debt.delete();
    notifyListeners();
  }
}
