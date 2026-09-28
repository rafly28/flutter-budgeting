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

    String jsonString = jsonEncode(
      backupData,
      toEncodable: (Object? value) {
        if (value is Expense) {
          return {
            'amount': value.amount,
            'category': value.category,
            'note': value.note,
            'date': value.date.toIso8601String(),
            'type': value.type,
            'source': value.source,
            'planId': value.planId,
            'debtId': value.debtId,
          };
        }
        if (value is SavingAccount) {
          return {
            'name': value.name,
            'balance': value.balance,
            'bankName': value.bankName,
            'accountNumber': value.accountNumber,
            'accountHolderName': value.accountHolderName,
            'pocketCategory': value.pocketCategory,
          };
        }
        if (value is TransactionCategory) {
          return {
            'name': value.name,
            'type': value.type,
            'iconCodePoint': value.iconCodePoint,
            'iconFontFamily': value.iconFontFamily,
          };
        }
        if (value is CategoryBudget) {
          return {
            'categoryName': value.categoryName,
            'limitAmount': value.limitAmount,
          };
        }
        if (value is UserProfile) return {'name': value.name};
        if (value is UserSettings) {
          return {
            'payday': value.payday,
            'isNotificationEnabled': value.isNotificationEnabled,
            'resetBalanceOnPayday': value.resetBalanceOnPayday,
            'themeColor': value.themeColor,
          };
        }
        if (value is MonthlyReport) {
          return {
            'month': value.month,
            'totalIncome': value.totalIncome,
            'totalExpense': value.totalExpense,
            'balance': value.balance,
          };
        }
        if (value is PlanItem) {
          return {
            'id': value.id,
            'title': value.title,
            'amount': value.amount,
            'isPaid': value.isPaid,
            'category': value.category,
            'monthKey': value.monthKey,
            'planType': value.planType,
          };
        }
        if (value is Debt) {
          return {
            'id': value.id,
            'type': value.type,
            'personName': value.personName,
            'amount': value.amount,
            'paidAmount': value.paidAmount,
            'createdAt': value.createdAt.toIso8601String(),
            'dueDate': value.dueDate?.toIso8601String(),
            'isSettled': value.isSettled,
          };
        }
        return value;
      },
    );
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

    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      Map<String, dynamic> data = jsonDecode(content);

      // 🎯 PERBAIKAN: Restore Box satu per satu dengan tipe yang benar
      await _restoreBox<Expense>(
        'expensesBox',
        data['expensesBox'],
        (item) => Expense(
          amount: item['amount'],
          category: item['category'],
          note: item['note'],
          date: DateTime.parse(item['date']),
          type: item['type'],
          source: item['source'] ?? 'Budget Utama',
          planId: item['planId'],
          debtId: item['debtId'],
        ),
      );

      await _restoreBox<SavingAccount>(
        'savingsBox',
        data['savingsBox'],
        (item) => SavingAccount(
          name: item['name'],
          balance: item['balance'],
          bankName: item['bankName'],
          accountNumber: item['accountNumber'],
          accountHolderName: item['accountHolderName'],
          pocketCategory: item['pocketCategory'] ?? 'savings',
        ),
      );

      await _restoreBox<TransactionCategory>(
        'categoryBox',
        data['categoryBox'],
        (item) => TransactionCategory(
          name: item['name'],
          type: item['type'],
          iconCodePoint: item['iconCodePoint'],
          iconFontFamily: item['iconFontFamily'],
        ),
      );

      await _restoreBox<CategoryBudget>(
        'budgetBox',
        data['budgetBox'],
        (item) => CategoryBudget(
          categoryName: item['categoryName'],
          limitAmount: item['limitAmount'],
        ),
      );

      await _restoreBox<UserProfile>(
        'userBox',
        data['userBox'],
        (item) => UserProfile(name: item['name']),
      );

      await _restoreBox<UserSettings>(
        'userSettingsBox',
        data['userSettingsBox'],
        (item) => UserSettings(
          payday: item['payday'],
          isNotificationEnabled: item['isNotificationEnabled'] ?? true,
          resetBalanceOnPayday: item['resetBalanceOnPayday'] ?? false,
          themeColor: item['themeColor'] ?? 0xFF1E3A8A,
          budgetingMode: item['budgetingMode'] ?? 'standard',
          isBalanceHidden: item['isBalanceHidden'] ?? false,
        ),
      );

      await _restoreBox<MonthlyReport>(
        'monthlyReportsBox',
        data['monthlyReportsBox'],
        (item) => MonthlyReport(
          month: item['month'],
          totalIncome: item['totalIncome'],
          totalExpense: item['totalExpense'],
          balance: item['balance'],
        ),
      );

      await _restoreBox<PlanItem>(
        'planBox',
        data['planBox'],
        (item) => PlanItem(
          id: item['id'],
          title: item['title'],
          amount: item['amount'],
          isPaid: item['isPaid'],
          category: item['category'],
          monthKey: item['monthKey'],
          planType: item['planType'] ?? 'expense',
        ),
      );

      await _restoreDebtBox(data['debtBox']);

      return true;
    }
    return false;
  }

  // Helper agar kode import lebih rapi
  static Future<void> _restoreBox<T>(
    String boxName,
    List<dynamic>? data,
    T Function(Map<String, dynamic>) mapper,
  ) async {
    if (data == null) return;
    var box = Hive.box<T>(boxName);
    await box.clear();
    for (var item in data) {
      await box.add(mapper(Map<String, dynamic>.from(item)));
    }
  }

  static Future<void> _restoreDebtBox(List<dynamic>? data) async {
    final debts = (data ?? const <dynamic>[]).map((item) {
      final map = Map<String, dynamic>.from(item);
      return Debt(
        id: map['id'],
        type: map['type'],
        personName: map['personName'],
        amount: (map['amount'] as num).toDouble(),
        paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
        createdAt: DateTime.parse(map['createdAt']),
        dueDate: map['dueDate'] == null ? null : DateTime.parse(map['dueDate']),
        isSettled: map['isSettled'] ?? false,
      );
    }).toList();

    final box = Hive.box<Debt>('debtBox');
    await box.clear();
    for (final debt in debts) {
      await box.put(debt.id, debt);
    }
  }
}
