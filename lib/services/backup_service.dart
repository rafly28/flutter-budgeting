import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:toastification/toastification.dart';

import '../models/expense.dart';
import '../models/saving_account.dart';
import '../models/transaction_category.dart';
import '../models/category_budget.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import '../models/monthly_report.dart';
import '../models/plan_item.dart';
import '../models/debt.dart';

class BackupService {
  static Future<void> exportBackup(BuildContext context) async {
    Map<String, dynamic> backupData = {};

    backupData['expensesBox'] = Hive.box<Expense>(
      'expensesBox',
    ).values.toList();
    backupData['savingsBox'] = Hive.box<SavingAccount>(
      'savingsBox',
    ).values.toList();
    backupData['categoryBox'] = Hive.box<TransactionCategory>(
      'categoryBox',
    ).values.toList();
    backupData['budgetBox'] = Hive.box<CategoryBudget>(
      'budgetBox',
    ).values.toList();
    backupData['userBox'] = Hive.box<UserProfile>('userBox').values.toList();
    backupData['userSettingsBox'] = Hive.box<UserSettings>(
      'userSettingsBox',
    ).values.toList();
    backupData['monthlyReportsBox'] = Hive.box<MonthlyReport>(
      'monthlyReportsBox',
    ).values.toList();
    backupData['planBox'] = Hive.box<PlanItem>('planBox').values.toList();
    backupData['debtBox'] = Hive.box<Debt>('debtBox').values.toList();

    String jsonString = jsonEncode(backupData, toEncodable: _toJson);

    Uint8List bytes = Uint8List.fromList(utf8.encode(jsonString));
    try {
      // Gunakan FilePicker untuk memilih lokasi simpan (User bisa buat folder atoorduid di sini)
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Pilih Lokasi Simpan Backup',
        fileName:
            'aturduid_backup_${DateFormat('yyyyMMdd').format(DateTime.now())}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: bytes,
      );

      if (outputFile != null && context.mounted) {
        toastification.show(
          context: context,
          title: const Text("Backup berhasil disimpan"),
          type: ToastificationType.success,
          style: ToastificationStyle.flat,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    } catch (e) {
      if (context.mounted) {
        toastification.show(
          context: context,
          title: Text("Gagal menyimpan file: $e"),
          type: ToastificationType.error,
          style: ToastificationStyle.flat,
          autoCloseDuration: const Duration(seconds: 3),
        );
      }
    }
  }

  static Future<bool> importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null) return false;

    final File file = File(result.files.single.path!);
    final String content = await file.readAsString();
    final Map<String, dynamic> data = jsonDecode(content);

    await _restoreBox<Expense>('expensesBox', data['expensesBox'], expenseFromJson);

    await _restoreBox<SavingAccount>(
      'savingsBox',
      data['savingsBox'],
      savingFromJson,
    );

    await _restoreBox<TransactionCategory>(
      'categoryBox',
      data['categoryBox'],
      categoryFromJson,
    );

    await _restoreBox<CategoryBudget>(
      'budgetBox',
      data['budgetBox'],
      budgetFromJson,
    );

    await _restoreBox<UserProfile>('userBox', data['userBox'], userFromJson);

    await _restoreBox<UserSettings>(
      'userSettingsBox',
      data['userSettingsBox'],
      settingsFromJson,
    );

    await _restoreBox<MonthlyReport>(
      'monthlyReportsBox',
      data['monthlyReportsBox'],
      monthlyReportFromJson,
    );

    await _restoreBox<PlanItem>('planBox', data['planBox'], planFromJson);

    // Debt tetap memakai put(id) supaya key Hive-nya ikut terjaga, bukan
    // auto-increment seperti box lain.
    await _restoreDebtBox(data['debtBox']);

    return true;
  }

  // ───────────────────────── Export mappers ─────────────────────────
  // Semua field model wajib ikut ditulis. Kalau ada yang terlupa, restore
  // akan mengembalikan nilai default dan data pengguna hilang tanpa jejak.

  static Object? _toJson(Object? value) {
    if (value is Expense) return expenseToJson(value);
    if (value is SavingAccount) return savingToJson(value);
    if (value is TransactionCategory) return categoryToJson(value);
    if (value is CategoryBudget) return budgetToJson(value);
    if (value is UserProfile) return userToJson(value);
    if (value is UserSettings) return settingsToJson(value);
    if (value is MonthlyReport) return monthlyReportToJson(value);
    if (value is PlanItem) return planToJson(value);
    if (value is Debt) return debtToJson(value);
    return value;
  }

  static Map<String, dynamic> expenseToJson(Expense v) => {
    'amount': v.amount,
    'category': v.category,
    'note': v.note,
    'date': v.date.toIso8601String(),
    'type': v.type,
    'source': v.source,
    'planId': v.planId,
    'debtId': v.debtId,
    'transferDestination': v.transferDestination,
    'investmentPrices': v.investmentPrices,
  };

  static Map<String, dynamic> savingToJson(SavingAccount v) => {
    'name': v.name,
    'balance': v.balance,
    'bankName': v.bankName,
    'accountNumber': v.accountNumber,
    'accountHolderName': v.accountHolderName,
    'pocketCategory': v.pocketCategory,
    'assetType': v.assetType,
    'unitCount': v.unitCount,
    'avgBuyPrice': v.avgBuyPrice,
    'lastMarketPrice': v.lastMarketPrice,
    'symbol': v.symbol,
    'unitLabel': v.unitLabel,
    'priceFetchedAt': v.priceFetchedAt?.toIso8601String(),
    'lastBuybackPrice': v.lastBuybackPrice,
  };

  static Map<String, dynamic> categoryToJson(TransactionCategory v) => {
    'name': v.name,
    'type': v.type,
    'iconCodePoint': v.iconCodePoint,
    'iconFontFamily': v.iconFontFamily,
    'budgetGroup': v.budgetGroup,
  };

  static Map<String, dynamic> budgetToJson(CategoryBudget v) => {
    'categoryName': v.categoryName,
    'limitAmount': v.limitAmount,
  };

  static Map<String, dynamic> userToJson(UserProfile v) => {'name': v.name};

  static Map<String, dynamic> settingsToJson(UserSettings v) => {
    'payday': v.payday,
    'isNotificationEnabled': v.isNotificationEnabled,
    'resetBalanceOnPayday': v.resetBalanceOnPayday,
    'themeColor': v.themeColor,
    'budgetingMode': v.budgetingMode,
    'isBalanceHidden': v.isBalanceHidden,
  };

  static Map<String, dynamic> monthlyReportToJson(MonthlyReport v) => {
    'month': v.month,
    'totalIncome': v.totalIncome,
    'totalExpense': v.totalExpense,
    'balance': v.balance,
  };

  static Map<String, dynamic> planToJson(PlanItem v) => {
    'id': v.id,
    'title': v.title,
    'amount': v.amount,
    'isPaid': v.isPaid,
    'category': v.category,
    'monthKey': v.monthKey,
    'planType': v.planType,
  };

  static Map<String, dynamic> debtToJson(Debt v) => {
    'id': v.id,
    'type': v.type,
    'personName': v.personName,
    'amount': v.amount,
    'paidAmount': v.paidAmount,
    'createdAt': v.createdAt.toIso8601String(),
    'dueDate': v.dueDate?.toIso8601String(),
    'isSettled': v.isSettled,
  };

  // ───────────────────────── Import mappers ─────────────────────────
  // Semua kunci wajib punya fallback supaya backup versi lama (yang belum
  // menyimpan field baru) tetap bisa diimpor.

  static Expense expenseFromJson(Map<String, dynamic> item) => Expense(
    amount: _toDouble(item['amount']) ?? 0,
    category: item['category'] as String,
    note: item['note'] as String?,
    date: DateTime.parse(item['date'] as String),
    type: item['type'] as String,
    source: item['source'] as String? ?? 'Budget Utama',
    planId: item['planId'] as String?,
    debtId: item['debtId'] as String?,
    transferDestination: item['transferDestination'] as String?,
    investmentPrices: _toDoubleMap(item['investmentPrices']),
  );

  static SavingAccount savingFromJson(Map<String, dynamic> item) =>
      SavingAccount(
        name: item['name'] as String,
        balance: _toDouble(item['balance']) ?? 0,
        bankName: item['bankName'] as String? ?? '',
        accountNumber: item['accountNumber'] as String? ?? '',
        accountHolderName: item['accountHolderName'] as String? ?? '',
        pocketCategory: item['pocketCategory'] as String? ?? 'savings',
        assetType: item['assetType'] as String? ?? 'cash',
        unitCount: _toDouble(item['unitCount']) ?? 0,
        avgBuyPrice: _toDouble(item['avgBuyPrice']) ?? 0,
        lastMarketPrice: _toDouble(item['lastMarketPrice']) ?? 0,
        symbol: item['symbol'] as String? ?? '',
        unitLabel: item['unitLabel'] as String? ?? '',
        priceFetchedAt: item['priceFetchedAt'] == null
            ? null
            : DateTime.parse(item['priceFetchedAt'] as String),
        lastBuybackPrice: _toDouble(item['lastBuybackPrice']) ?? 0,
      );

  static TransactionCategory categoryFromJson(Map<String, dynamic> item) =>
      TransactionCategory(
        name: item['name'] as String,
        type: item['type'] as String,
        iconCodePoint: item['iconCodePoint'] as int?,
        iconFontFamily: item['iconFontFamily'] as String?,
        budgetGroup: item['budgetGroup'] as String? ?? 'needs',
      );

  static CategoryBudget budgetFromJson(Map<String, dynamic> item) =>
      CategoryBudget(
        categoryName: item['categoryName'] as String,
        limitAmount: _toDouble(item['limitAmount']) ?? 0,
      );

  static UserProfile userFromJson(Map<String, dynamic> item) =>
      UserProfile(name: item['name'] as String);

  static UserSettings settingsFromJson(Map<String, dynamic> item) => UserSettings(
    payday: (item['payday'] as num?)?.toInt() ?? 25,
    isNotificationEnabled: item['isNotificationEnabled'] as bool? ?? true,
    resetBalanceOnPayday: item['resetBalanceOnPayday'] as bool? ?? false,
    themeColor: (item['themeColor'] as num?)?.toInt() ?? 0xFF1E3A8A,
    budgetingMode: item['budgetingMode'] as String? ?? 'standard',
    isBalanceHidden: item['isBalanceHidden'] as bool? ?? true,
  );

  static MonthlyReport monthlyReportFromJson(Map<String, dynamic> item) =>
      MonthlyReport(
        month: item['month'] as String,
        totalIncome: _toDouble(item['totalIncome']) ?? 0,
        totalExpense: _toDouble(item['totalExpense']) ?? 0,
        balance: _toDouble(item['balance']) ?? 0,
      );

  static PlanItem planFromJson(Map<String, dynamic> item) => PlanItem(
    id: item['id'] as String,
    title: item['title'] as String,
    amount: _toDouble(item['amount']) ?? 0,
    isPaid: item['isPaid'] as bool? ?? false,
    category: item['category'] as String,
    monthKey: item['monthKey'] as String,
    planType: item['planType'] as String? ?? 'expense',
  );

  static Debt debtFromJson(Map<String, dynamic> item) => Debt(
    id: item['id'] as String,
    type: item['type'] as String,
    personName: item['personName'] as String,
    amount: _toDouble(item['amount']) ?? 0,
    paidAmount: _toDouble(item['paidAmount']) ?? 0,
    createdAt: DateTime.parse(item['createdAt'] as String),
    dueDate: item['dueDate'] == null
        ? null
        : DateTime.parse(item['dueDate'] as String),
    isSettled: item['isSettled'] as bool? ?? false,
  );

  static double? _toDouble(Object? raw) => (raw as num?)?.toDouble();

  /// Peta harga investasi ikut format JSON (kunci string, nilai number).
  /// Backup lama tidak punya field ini, jadi default-nya peta kosong.
  static Map<String, double> _toDoubleMap(Object? raw) {
    if (raw is! Map) return const {};
    final result = <String, double>{};
    raw.forEach((key, value) {
      final price = (value as num?)?.toDouble();
      if (price != null) result['$key'] = price;
    });
    return result;
  }

  static Future<void> _restoreDebtBox(List<dynamic>? data) async {
    final debts = (data ?? const <dynamic>[])
        .map(
          (item) => debtFromJson(Map<String, dynamic>.from(item)),
        )
        .toList();

    final box = Hive.box<Debt>('debtBox');
    await box.clear();
    for (final debt in debts) {
      await box.put(debt.id, debt);
    }
  }

  // Helper agar kode import lebih rapi
  static Future<void> _restoreBox<T>(
    String boxName,
    List<dynamic>? data,
    T Function(Map<String, dynamic>) mapper,
  ) async {
    if (data == null) return;
    final box = Hive.box<T>(boxName);
    await box.clear();
    for (final item in data) {
      await box.add(mapper(Map<String, dynamic>.from(item)));
    }
  }
}