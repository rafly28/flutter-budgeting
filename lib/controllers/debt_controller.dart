import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/debt.dart';
import '../models/expense.dart';
import 'expense_controller.dart';

class DebtController extends ChangeNotifier {
  final Box<Debt> _box = Hive.box<Debt>('debtBox');
  final ExpenseController _expenseController;
  final Set<String> _busyDebtIds = <String>{};
  late final Future<void> _legacyMigration;

  DebtController(this._expenseController) {
    _legacyMigration = _migrateLegacyExpenses();
  }

  List<Debt> get debts => _box.values.toList();

  List<Debt> get hutang =>
      debts.where((debt) => debt.type == 'hutang').toList();

  List<Debt> get piutang =>
      debts.where((debt) => debt.type == 'piutang').toList();

  List<Debt> get activeHutang =>
      hutang.where((debt) => !debt.isSettled).toList();

  List<Debt> get activePiutang =>
      piutang.where((debt) => !debt.isSettled).toList();

  Future<bool> addDebt(Debt debt, String accountName) async {
    await _legacyMigration;
    if (!_isValidDebt(debt) ||
        debt.paidAmount != 0 ||
        debt.isSettled ||
        !_expenseController.accountExists(accountName) ||
        (debt.type == 'piutang' &&
            !_expenseController.canAfford(accountName, debt.amount)) ||
        !_busyDebtIds.add(debt.id)) {
      return false;
    }

    final expense = _principalExpense(debt, accountName);
    try {
      if (_box.containsKey(debt.id) || debt.isInBox) return false;

      await _box.put(debt.id, debt);
      final added = await _expenseController.addExpense(expense);
      if (!added) {
        await _box.delete(debt.id);
        return false;
      }

      notifyListeners();
      return true;
    } catch (_) {
      if (expense.isInBox) {
        await _tryRemoveExpense(expense);
      }
      if (_box.containsKey(debt.id)) {
        try {
          await _box.delete(debt.id);
        } catch (_) {}
      }
      return false;
    } finally {
      _busyDebtIds.remove(debt.id);
    }
  }

  Future<bool> payDebt(
    Debt debt,
    double amountToPay,
    String accountName,
  ) async {
    await _legacyMigration;
    if (!amountToPay.isFinite ||
        amountToPay <= 0 ||
        !_expenseController.accountExists(accountName) ||
        !_busyDebtIds.add(debt.id)) {
      return false;
    }

    try {
      final storedDebt = _box.get(debt.id);
      if (storedDebt == null ||
          !_isValidDebt(storedDebt) ||
          storedDebt.isSettled) {
        return false;
      }

      final remaining = storedDebt.amount - storedDebt.paidAmount;
      if (amountToPay > remaining ||
          (storedDebt.type == 'hutang' &&
              !_expenseController.canAfford(accountName, amountToPay))) {
        return false;
      }

      final expense = _paymentExpense(storedDebt, amountToPay, accountName);
      var expenseAdded = false;
      try {
        expenseAdded = await _expenseController.addExpense(expense);
        if (!expenseAdded) return false;

        final previousPaidAmount = storedDebt.paidAmount;
        final previousSettled = storedDebt.isSettled;
        final newPaidAmount = previousPaidAmount + amountToPay;
        storedDebt.paidAmount = newPaidAmount >= storedDebt.amount
            ? storedDebt.amount
            : newPaidAmount;
        storedDebt.isSettled = storedDebt.paidAmount == storedDebt.amount;

        try {
          await storedDebt.save();
        } catch (_) {
          storedDebt.paidAmount = previousPaidAmount;
          storedDebt.isSettled = previousSettled;
          try {
            await storedDebt.save();
          } catch (_) {}
          await _tryRemoveExpense(expense);
          return false;
        }

        notifyListeners();
        return true;
      } catch (_) {
        if (expenseAdded || expense.isInBox) {
          await _tryRemoveExpense(expense);
        }
        return false;
      }
    } finally {
      _busyDebtIds.remove(debt.id);
    }
  }

  Future<bool> deleteDebt(Debt debt) async {
    await _legacyMigration;
    if (!_busyDebtIds.add(debt.id)) return false;

    try {
      final storedDebt = _box.get(debt.id);
      if (storedDebt == null || !_isValidDebt(storedDebt)) return false;

      final linkedExpenses = _expenseController.expenses
          .where((expense) => expense.debtId == storedDebt.id)
          .toList();
      final legacyExpenses = linkedExpenses.isEmpty
          ? _findLegacyExpenses(storedDebt)
          : <Expense>[];
      if (linkedExpenses.isEmpty && legacyExpenses == null) return false;
      if (linkedExpenses.isNotEmpty &&
          !_hasCompleteLinkedExpenses(storedDebt, linkedExpenses)) {
        return false;
      }

      final expenses = linkedExpenses.isNotEmpty
          ? linkedExpenses
          : legacyExpenses!;
      if (expenses.isEmpty ||
          expenses.any(
            (expense) =>
                !expense.amount.isFinite ||
                expense.amount <= 0 ||
                (expense.type != 'income' && expense.type != 'expense') ||
                !_expenseController.accountExists(expense.source),
          )) {
        return false;
      }

      if (legacyExpenses != null && legacyExpenses.isNotEmpty) {
        if (!await _setDebtId(legacyExpenses, storedDebt.id)) return false;
      }

      final removed = <Expense>[];
      for (final expense in expenses) {
        final didRemove = await _tryRemoveExpense(expense);
        if (didRemove || !expense.isInBox) removed.add(expense);
        if (!didRemove) {
          await _restoreExpenses(removed);
          if (legacyExpenses != null) await _clearDebtId(legacyExpenses);
          return false;
        }
      }

      try {
        await _box.delete(storedDebt.id);
      } catch (_) {
        await _restoreExpenses(removed);
        if (legacyExpenses != null) await _clearDebtId(legacyExpenses);
        return false;
      }

      notifyListeners();
      return true;
    } finally {
      _busyDebtIds.remove(debt.id);
    }
  }

  bool _isValidDebt(Debt debt) {
    return (debt.type == 'hutang' || debt.type == 'piutang') &&
        debt.personName.trim().isNotEmpty &&
        debt.amount.isFinite &&
        debt.amount > 0 &&
        debt.paidAmount.isFinite &&
        debt.paidAmount >= 0 &&
        debt.paidAmount <= debt.amount;
  }

  Future<void> _migrateLegacyExpenses() async {
    var changed = false;
    for (final debt in _box.values.toList()) {
      final alreadyLinked = _expenseController.expenses.any(
        (expense) => expense.debtId == debt.id,
      );
      if (alreadyLinked) continue;

      final legacyExpenses = _findLegacyExpenses(debt);
      if (legacyExpenses == null || legacyExpenses.isEmpty) continue;
      if (await _setDebtId(legacyExpenses, debt.id)) changed = true;
    }
    if (changed) notifyListeners();
  }

  Expense _principalExpense(Debt debt, String accountName) {
    final isHutang = debt.type == 'hutang';
    return Expense(
      amount: debt.amount,
      category: isHutang ? 'Hutang' : 'Piutang',
      note: isHutang
          ? 'Pinjaman dari ${debt.personName}'
          : 'Dipinjam oleh ${debt.personName}',
      date: debt.createdAt,
      type: isHutang ? 'income' : 'expense',
      source: accountName,
      debtId: debt.id,
    );
  }

  Expense _paymentExpense(Debt debt, double amount, String accountName) {
    final isHutang = debt.type == 'hutang';
    return Expense(
      amount: amount,
      category: isHutang ? 'Bayar Hutang' : 'Terima Cicilan',
      note: isHutang
          ? 'Cicilan hutang ke ${debt.personName}'
          : 'Pembayaran piutang dari ${debt.personName}',
      date: DateTime.now(),
      type: isHutang ? 'expense' : 'income',
      source: accountName,
      debtId: debt.id,
    );
  }

  List<Expense>? _findLegacyExpenses(Debt debt) {
    final expenses = _expenseController.expenses;
    final principalMatches = expenses
        .where(
          (expense) =>
              expense.debtId == null &&
              _matchesPrincipal(expense, debt, legacy: true),
        )
        .toList();
    if (principalMatches.length != 1) return null;

    final paymentMatches = expenses
        .where(
          (expense) =>
              expense.debtId == null &&
              !expense.date.isBefore(debt.createdAt) &&
              _matchesPayment(expense, debt, legacy: true),
        )
        .toList();
    if (debt.paidAmount == 0) {
      return paymentMatches.isEmpty ? principalMatches : null;
    }

    final hasSamePersonDebt = _box.values.any(
      (other) =>
          other.id != debt.id &&
          other.type == debt.type &&
          other.personName == debt.personName,
    );
    if (hasSamePersonDebt) return null;

    final paymentTotal = paymentMatches.fold<double>(
      0,
      (total, expense) => total + expense.amount,
    );
    if (paymentTotal != debt.paidAmount) return null;

    return <Expense>[...principalMatches, ...paymentMatches];
  }

  bool _hasCompleteLinkedExpenses(Debt debt, List<Expense> expenses) {
    final principalMatches = expenses
        .where((expense) => _matchesPrincipal(expense, debt))
        .toList();
    if (principalMatches.length != 1) return false;

    final payments = expenses
        .where((expense) => !identical(expense, principalMatches.single))
        .toList();
    if (payments.any((expense) => !_matchesPayment(expense, debt))) {
      return false;
    }

    return payments.fold<double>(0, (total, item) => total + item.amount) ==
        debt.paidAmount;
  }

  bool _matchesPrincipal(Expense expense, Debt debt, {bool legacy = false}) {
    final isHutang = debt.type == 'hutang';
    return (!legacy || expense.source == ExpenseController.mainAccountName) &&
        expense.type == (isHutang ? 'income' : 'expense') &&
        expense.category == (isHutang ? 'Hutang' : 'Piutang') &&
        expense.note ==
            (isHutang
                ? 'Pinjaman dari ${debt.personName}'
                : 'Dipinjam oleh ${debt.personName}') &&
        expense.amount == debt.amount &&
        expense.date.isAtSameMomentAs(debt.createdAt);
  }

  bool _matchesPayment(Expense expense, Debt debt, {bool legacy = false}) {
    final isHutang = debt.type == 'hutang';
    return (!legacy || expense.source == ExpenseController.mainAccountName) &&
        expense.type == (isHutang ? 'expense' : 'income') &&
        expense.category == (isHutang ? 'Bayar Hutang' : 'Terima Cicilan') &&
        expense.note ==
            (isHutang
                ? 'Cicilan hutang ke ${debt.personName}'
                : 'Pembayaran piutang dari ${debt.personName}') &&
        expense.amount.isFinite &&
        expense.amount > 0;
  }

  Future<bool> _setDebtId(List<Expense> expenses, String debtId) async {
    final updated = <Expense>[];
    try {
      for (final expense in expenses) {
        expense.debtId = debtId;
        await expense.save();
        updated.add(expense);
      }
      return true;
    } catch (_) {
      await _clearDebtId(<Expense>[
        ...updated,
        ...expenses.skip(updated.length),
      ]);
      return false;
    }
  }

  Future<void> _clearDebtId(List<Expense> expenses) async {
    for (final expense in expenses) {
      expense.debtId = null;
      if (!expense.isInBox) continue;
      try {
        await expense.save();
      } catch (_) {}
    }
  }

  Future<bool> _tryRemoveExpense(Expense expense) async {
    try {
      return await _expenseController.removeExpense(expense);
    } catch (_) {
      return false;
    }
  }

  Future<void> _restoreExpenses(List<Expense> expenses) async {
    for (final expense in expenses) {
      if (expense.isInBox) continue;
      try {
        await _expenseController.addExpense(expense);
      } catch (_) {}
    }
  }
}
