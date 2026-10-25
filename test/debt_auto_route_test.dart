import 'dart:io';

import 'package:aturduid/controllers/debt_controller.dart';
import 'package:aturduid/controllers/expense_controller.dart';
import 'package:aturduid/controllers/saving_controller.dart';
import 'package:aturduid/models/debt.dart';
import 'package:aturduid/models/expense.dart';
import 'package:aturduid/models/monthly_report.dart';
import 'package:aturduid/models/saving_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late ExpenseController expenseController;
  late DebtController debtController;

  final transactionDate = DateTime(2024, 1, 15, 10);

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MonthlyReportAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(SavingAccountAdapter());
    }
    if (!Hive.isAdapterRegistered(9)) Hive.registerAdapter(DebtAdapter());
  });

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('aturduid-test-');
    Hive.init(hiveDirectory.path);
    await Hive.openBox<SavingAccount>('savingsBox');
    await Hive.openBox<Expense>('expensesBox');
    await Hive.openBox<MonthlyReport>('monthlyReportsBox');
    await Hive.openBox<Debt>('debtBox');

    final savingController = SavingController();
    expenseController = ExpenseController(savingController);
    debtController = DebtController(expenseController);
  });

  tearDown(() async {
    await Hive.close();
    if (await hiveDirectory.exists()) {
      await hiveDirectory.delete(recursive: true);
    }
  });

  Future<SavingAccount> addSaving(String name, double balance) async {
    final account = SavingAccount(name: name, balance: balance);
    await Hive.box<SavingAccount>('savingsBox').add(account);
    return account;
  }

  group('principalAccountOf', () {
    test('mengembalikan akun asal piutang yang tertaut di ledger', () async {
      await addSaving('Tabungan A', 1000);
      final debt = Debt(
        id: 'piutang-sumber',
        type: 'piutang',
        personName: 'Budi',
        amount: 400,
        createdAt: transactionDate,
      );
      expect(await debtController.addDebt(debt, 'Tabungan A'), isTrue);

      expect(debtController.principalAccountOf(debt), 'Tabungan A');
    });

    test('mengembalikan tujuan awal hutang yang tertaut di ledger', () async {
      await addSaving('Tabungan A', 0);
      final debt = Debt(
        id: 'hutang-sumber',
        type: 'hutang',
        personName: 'Citra',
        amount: 500,
        createdAt: transactionDate,
      );
      expect(await debtController.addDebt(debt, 'Tabungan A'), isTrue);

      expect(debtController.principalAccountOf(debt), 'Tabungan A');
    });

    test('null bila tidak ada ledger utama yang tertaut', () async {
      final debt = Debt(
        id: 'tanpa-ledger',
        type: 'piutang',
        personName: 'Dedi',
        amount: 300,
        createdAt: transactionDate,
      );
      await Hive.box<Debt>('debtBox').put(debt.id, debt);

      expect(debtController.principalAccountOf(debt), isNull);
    });
  });
}
