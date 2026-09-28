import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../models/saving_account.dart';
import '../services/market_api_service.dart';

class SavingController extends ChangeNotifier {
  final Box<SavingAccount> _box = Hive.box<SavingAccount>('savingsBox');

  List<SavingAccount> get savings => _box.values.toList();

  double get totalSavingsBalance =>
      _box.values.fold(0.0, (sum, item) => sum + item.balance);

  // 👇 UPDATE: Tambah parameter baru
  Future<bool> addSavingAccount(
    String name,
    double initialBalance,
    String bank,
    String accNum,
    String holderName, {
    String pocketCategory = 'savings',
    String assetType = 'cash',
    double unitCount = 0.0,
    double avgBuyPrice = 0.0,
    String symbol = '',
  }) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty ||
        !initialBalance.isFinite ||
        initialBalance < 0 ||
        normalizedName == 'Budget Utama' ||
        savings.any((account) => account.name == normalizedName)) {
      return false;
    }

    try {
      await _box.add(
        SavingAccount(
          name: normalizedName,
          balance: initialBalance,
          bankName: bank,
          accountNumber: accNum,
          accountHolderName: holderName,
          pocketCategory: pocketCategory,
          assetType: assetType,
          unitCount: unitCount,
          avgBuyPrice: avgBuyPrice,
          symbol: symbol,
        ),
      );
    } catch (_) {
      return false;
    }
    notifyListeners();
    return true;
  }

  // 👇 UPDATE: Fungsi edit
  Future<bool> updateSavingDetails(
    SavingAccount account,
    String newName,
    String bank,
    String accNum,
    String holderName,
    double newBalance, {
    String? pocketCategory,
    String? assetType,
    double? unitCount,
    double? avgBuyPrice,
    String? symbol,
  }) async {
    final normalizedName = newName.trim();
    final isRenaming = normalizedName != account.name;
    final duplicateName = savings.any(
      (other) => other.key != account.key && other.name == normalizedName,
    );
    if (normalizedName.isEmpty ||
        !newBalance.isFinite ||
        newBalance < 0 ||
        normalizedName == 'Budget Utama' ||
        duplicateName ||
        (isRenaming && _isReferenced(account.name))) {
      return false;
    }

    final oldName = account.name;
    final oldBank = account.bankName;
    final oldAccountNumber = account.accountNumber;
    final oldHolder = account.accountHolderName;
    final oldBalance = account.balance;
    account.name = normalizedName;
    account.bankName = bank;
    account.accountNumber = accNum;
    account.accountHolderName = holderName;
    account.balance = newBalance;
    if (pocketCategory != null) {
      account.pocketCategory = pocketCategory;
    }
    if (assetType != null) account.assetType = assetType;
    if (unitCount != null) account.unitCount = unitCount;
    if (avgBuyPrice != null) account.avgBuyPrice = avgBuyPrice;
    if (symbol != null) account.symbol = symbol;
    try {
      await account.save();
    } catch (_) {
      account.name = oldName;
      account.bankName = oldBank;
      account.accountNumber = oldAccountNumber;
      account.accountHolderName = oldHolder;
      account.balance = oldBalance;
      return false;
    }
    notifyListeners();
    return true;
  }

  Future<void> updateBalance(
    SavingAccount account,
    double amount,
    String type,
  ) async {
    final previousBalance = account.balance;
    if (type == 'income') {
      account.balance += amount;
    } else if (type == 'expense') {
      account.balance -= amount;
    } else {
      throw ArgumentError.value(type, 'type', 'Tipe saldo tidak didukung');
    }

    try {
      await account.save();
    } catch (_) {
      account.balance = previousBalance;
      rethrow;
    }
    notifyListeners();
  }

  Future<bool> deleteSaving(SavingAccount account) async {
    if (_isReferenced(account.name)) return false;
    try {
      await account.delete();
    } catch (_) {
      return false;
    }
    notifyListeners();
    return true;
  }

  bool _isReferenced(String accountName) {
    if (!Hive.isBoxOpen('expensesBox')) return false;
    return Hive.box<Expense>('expensesBox').values.any(
      (expense) =>
          expense.source == accountName ||
          _transferDestination(expense) == accountName,
    );
  }

  String? _transferDestination(Expense expense) {
    if (expense.type != 'transfer' || expense.note == null) return null;
    final prefix = 'Dari ${expense.source} ke ';
    if (!expense.note!.startsWith(prefix)) return null;
    final end = expense.note!.indexOf('.', prefix.length);
    if (end == -1) return null;
    return expense.note!.substring(prefix.length, end).trim();
  }

  Future<void> refreshMarketPrices() async {
    bool updated = false;
    for (var acc in savings) {
      if (acc.assetType != 'cash' && acc.symbol.isNotEmpty) {
        final price = await MarketApiService.fetchPrice(acc.assetType, acc.symbol);
        if (price != null) {
          acc.lastMarketPrice = price;
          acc.balance = acc.unitCount * price;
          await acc.save();
          updated = true;
        }
      }
    }
    if (updated) notifyListeners();
  }
}
