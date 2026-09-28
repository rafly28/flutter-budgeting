import 'dart:io';

import 'package:aturduid/controllers/debt_controller.dart';
import 'package:aturduid/controllers/expense_controller.dart';
import 'package:aturduid/controllers/saving_controller.dart';
import 'package:aturduid/models/debt.dart';
import 'package:aturduid/models/expense.dart';
import 'package:aturduid/models/monthly_report.dart';
import 'package:aturduid/models/saving_account.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:timezone/data/latest_all.dart' as tz;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late SavingController savingController;
  late ExpenseController expenseController;
  late DebtController debtController;

  const mainAccount = ExpenseController.mainAccountName;
  final transactionDate = DateTime(2024, 1, 15, 10);

  setUpAll(() {
    tz.initializeTimeZones();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('dexterous.com/flutter/local_notifications'),
          (_) async => null,
        );
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

    savingController = SavingController();
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

  Future<void> fundMain(double amount) async {
    final added = await expenseController.addExpense(
      Expense(
        amount: amount,
        category: 'Saldo Awal',
        date: transactionDate,
        type: 'income',
      ),
    );
    expect(added, isTrue);
  }

  group('ExpenseController rollback', () {
    test(
      'restores a saving balance after deleting expense and income',
      () async {
        final account = await addSaving('Dompet', 1000);
        final expense = Expense(
          amount: 250,
          category: 'Makan',
          date: transactionDate,
          type: 'expense',
          source: account.name,
        );

        expect(await expenseController.addExpense(expense), isTrue);
        expect(account.balance, 750);
        expect(await expenseController.removeExpense(expense), isTrue);
        expect(account.balance, 1000);

        final income = Expense(
          amount: 400,
          category: 'Bonus',
          date: transactionDate,
          type: 'income',
          source: account.name,
        );
        expect(await expenseController.addExpense(income), isTrue);
        expect(account.balance, 1400);
        expect(await expenseController.removeExpense(income), isTrue);
        expect(account.balance, 1000);
        expect(expenseController.expenses, isEmpty);
      },
    );

    test('restores both saving balances after deleting a transfer', () async {
      final source = await addSaving('Dompet', 1000);
      final destination = await addSaving('Bank', 200);
      final transfer = Expense(
        amount: 300,
        category: 'Transfer',
        note: 'Dari Dompet ke Bank. Pindah dana',
        date: transactionDate,
        type: 'transfer',
        source: source.name,
      );

      expect(await expenseController.addExpense(transfer), isTrue);
      expect(source.balance, 700);
      expect(destination.balance, 500);

      expect(await expenseController.removeExpense(transfer), isTrue);
      expect(source.balance, 1000);
      expect(destination.balance, 200);
      expect(expenseController.expenses, isEmpty);
    });

    test('deletes the requested Hive key, not a list index', () async {
      final account = await addSaving('Dompet', 1000);
      final first = Expense(
        amount: 100,
        category: 'Pertama',
        date: transactionDate,
        type: 'expense',
        source: account.name,
      );
      final second = Expense(
        amount: 200,
        category: 'Kedua',
        date: transactionDate.add(const Duration(hours: 1)),
        type: 'expense',
        source: account.name,
      );
      expect(await expenseController.addExpense(first), isTrue);
      expect(await expenseController.addExpense(second), isTrue);
      final firstKey = first.key;
      final secondKey = second.key;

      expect(await expenseController.removeExpense(first), isTrue);

      final box = Hive.box<Expense>('expensesBox');
      expect(box.get(firstKey), isNull);
      expect(box.get(secondKey)?.category, 'Kedua');
      expect(account.balance, 800);
    });

    test(
      'protects account names that are referenced by transactions',
      () async {
        final account = await addSaving('Dompet', 1000);
        final expense = Expense(
          amount: 100,
          category: 'Makan',
          date: transactionDate,
          type: 'expense',
          source: account.name,
        );
        expect(await expenseController.addExpense(expense), isTrue);

        expect(
          await savingController.updateSavingDetails(
            account,
            'Dompet Baru',
            '',
            '',
            '',
            account.balance,
          ),
          isFalse,
        );
        expect(await savingController.deleteSaving(account), isFalse);
        expect(account.name, 'Dompet');

        expect(await expenseController.removeExpense(expense), isTrue);
        expect(
          await savingController.updateSavingDetails(
            account,
            'Dompet Baru',
            '',
            '',
            '',
            account.balance,
          ),
          isTrue,
        );
      },
    );
  });

  group('DebtController accounting', () {
    for (final type in ['hutang', 'piutang']) {
      for (final principalOnMain in [true, false]) {
        final principalLabel = principalOnMain ? 'main' : 'saving';
        final paymentLabel = principalOnMain ? 'saving' : 'main';

        test(
          '$type can use $principalLabel for principal and $paymentLabel for payment',
          () async {
            await fundMain(2000);
            final saving = await addSaving('Dompet', 2000);
            final principalAccount = principalOnMain
                ? mainAccount
                : saving.name;
            final paymentAccount = principalOnMain ? saving.name : mainAccount;
            final debt = Debt(
              id: '$type-$principalLabel',
              type: type,
              personName: 'Budi',
              amount: 800,
              createdAt: transactionDate,
            );

            expect(
              await debtController.addDebt(debt, principalAccount),
              isTrue,
            );
            expect(
              expenseController.balanceFor(principalAccount),
              type == 'hutang' ? 2800 : 1200,
            );
            expect(expenseController.balanceFor(paymentAccount), 2000);

            expect(
              await debtController.payDebt(debt, 300, paymentAccount),
              isTrue,
            );
            expect(debt.paidAmount, 300);
            expect(
              expenseController.balanceFor(paymentAccount),
              type == 'hutang' ? 1700 : 2300,
            );

            expect(await debtController.deleteDebt(debt), isTrue);
            expect(expenseController.balanceFor(mainAccount), 2000);
            expect(saving.balance, 2000);
            expect(Hive.box<Debt>('debtBox').containsKey(debt.id), isFalse);
            expect(
              expenseController.expenses.where((e) => e.debtId == debt.id),
              isEmpty,
            );
          },
        );
      }
    }

    test(
      'rejects a payment above the remaining debt without mutation',
      () async {
        final saving = await addSaving('Dompet', 1000);
        final debt = Debt(
          id: 'overpayment',
          type: 'hutang',
          personName: 'Siti',
          amount: 500,
          createdAt: transactionDate,
        );
        expect(await debtController.addDebt(debt, saving.name), isTrue);
        final balanceBeforePayment = saving.balance;
        final transactionsBeforePayment = expenseController.expenses.length;

        expect(await debtController.payDebt(debt, 501, saving.name), isFalse);

        expect(debt.paidAmount, 0);
        expect(debt.isSettled, isFalse);
        expect(saving.balance, balanceBeforePayment);
        expect(
          expenseController.expenses,
          hasLength(transactionsBeforePayment),
        );
        expect(
          expenseController.expenses.where((e) => e.debtId == debt.id),
          hasLength(1),
        );
      },
    );

    test('ambiguous legacy rows block deletion without any mutation', () async {
      final debt = Debt(
        id: 'legacy-ambiguous',
        type: 'hutang',
        personName: 'Andi',
        amount: 500,
        createdAt: transactionDate,
      );
      await Hive.box<Debt>('debtBox').put(debt.id, debt);

      for (var i = 0; i < 2; i++) {
        expect(
          await expenseController.addExpense(
            Expense(
              amount: debt.amount,
              category: 'Hutang',
              note: 'Pinjaman dari ${debt.personName}',
              date: debt.createdAt,
              type: 'income',
            ),
          ),
          isTrue,
        );
      }
      final keysBefore = expenseController.expenses.map((e) => e.key).toList();
      final balanceBefore = expenseController.balance;

      expect(await debtController.deleteDebt(debt), isFalse);

      expect(Hive.box<Debt>('debtBox').containsKey(debt.id), isTrue);
      expect(expenseController.expenses.map((e) => e.key), keysBefore);
      expect(expenseController.expenses.every((e) => e.debtId == null), isTrue);
      expect(expenseController.balance, balanceBefore);
    });
  });
}
