import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/expense.dart';
import '../models/saving_account.dart';
import '../models/transaction_category.dart';
import '../models/category_budget.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import '../models/monthly_report.dart';

class BackupService {
  static const List<String> _boxNames = [
    'expensesBox',
    'savingsBox',
    'categoryBox',
    'budgetBox',
    'userBox',
    'userSettingsBox',
    'monthlyReportsBox',
  ];

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

    String jsonString = jsonEncode(
      backupData,
      toEncodable: (Object? value) {
        if (value is Expense)
          return {
            'amount': value.amount,
            'category': value.category,
            'note': value.note,
            'date': value.date.toIso8601String(),
            'type': value.type,
            'source': value.source,
          };
        if (value is SavingAccount)
          return {
            'name': value.name,
            'balance': value.balance,
            'bankName': value.bankName,
            'accountNumber': value.accountNumber,
            'accountHolderName': value.accountHolderName,
          };
        if (value is TransactionCategory)
          return {'name': value.name, 'type': value.type};
        if (value is CategoryBudget)
          return {
            'categoryName': value.categoryName,
            'limitAmount': value.limitAmount,
          };
        if (value is UserProfile) return {'name': value.name};
        if (value is UserSettings)
          return {
            'payday': value.payday,
            'isNotificationEnabled': value.isNotificationEnabled,
          };
        if (value is MonthlyReport)
          return {
            'month': value.month,
            'totalIncome': value.totalIncome,
            'totalExpense': value.totalExpense,
            'balance': value.balance,
          };
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Backup berhasil disimpan"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal menyimpan file: $e"),
            backgroundColor: Colors.red,
          ),
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
        ),
      );

      await _restoreBox<TransactionCategory>(
        'categoryBox',
        data['categoryBox'],
        (item) => TransactionCategory(name: item['name'], type: item['type']),
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
      box.add(mapper(Map<String, dynamic>.from(item)));
    }
  }
}
