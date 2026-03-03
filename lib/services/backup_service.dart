import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
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

  // 📤 EXPORT: Simpan data ke File JSON dan Share
  static Future<void> exportBackup() async {
    Map<String, dynamic> backupData = {};

    for (var boxName in _boxNames) {
      var box = Hive.box(boxName);
      // Konversi isi box menjadi list of maps
      backupData[boxName] = box.values.toList();
    }

    // Ubah ke JSON String (Butuh mapping manual jika HiveObject tidak otomatis)
    // Untuk mempermudah, kita asumsikan HiveObject sudah punya toJson atau kita map manual
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
        if (value is UserSettings) return {'payday': value.payday};
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

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/aturduid_backup.json');
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'Backup Data AturDuid');
  }

  // 📥 IMPORT: Baca File JSON dan Timpa Box Hive
  static Future<bool> importBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      Map<String, dynamic> data = jsonDecode(content);

      // Pastikan semua box kosong dulu sebelum ditimpa
      for (var boxName in _boxNames) {
        var box = Hive.box(boxName);
        await box.clear();

        List<dynamic> list = data[boxName];
        for (var item in list) {
          if (boxName == 'expensesBox')
            box.add(
              Expense(
                amount: item['amount'],
                category: item['category'],
                note: item['note'],
                date: DateTime.parse(item['date']),
                type: item['type'],
                source: item['source'] ?? 'Budget Utama',
              ),
            );
          if (boxName == 'savingsBox')
            box.add(
              SavingAccount(
                name: item['name'],
                balance: item['balance'],
                bankName: item['bankName'],
                accountNumber: item['accountNumber'],
                accountHolderName: item['accountHolderName'],
              ),
            );
          if (boxName == 'categoryBox')
            box.add(
              TransactionCategory(name: item['name'], type: item['type']),
            );
          if (boxName == 'budgetBox')
            box.add(
              CategoryBudget(
                categoryName: item['categoryName'],
                limitAmount: item['limitAmount'],
              ),
            );
          if (boxName == 'userBox') box.add(UserProfile(name: item['name']));
          if (boxName == 'userSettingsBox')
            box.add(UserSettings(payday: item['payday']));
          if (boxName == 'monthlyReportsBox')
            box.add(
              MonthlyReport(
                month: item['month'],
                totalIncome: item['totalIncome'],
                totalExpense: item['totalExpense'],
                balance: item['balance'],
              ),
            );
        }
      }
      return true;
    }
    return false;
  }
}
