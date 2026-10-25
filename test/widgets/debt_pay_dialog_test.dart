import 'dart:io';

import 'package:aturduid/controllers/debt_controller.dart';
import 'package:aturduid/controllers/expense_controller.dart';
import 'package:aturduid/controllers/saving_controller.dart';
import 'package:aturduid/models/debt.dart';
import 'package:aturduid/models/expense.dart';
import 'package:aturduid/models/monthly_report.dart';
import 'package:aturduid/models/saving_account.dart';
import 'package:aturduid/pages/debt_page.dart';
import 'package:aturduid/utils/currency_input_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late SavingController savingController;
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

  group('resolveDebtPayAccount', () {
    test('rute otomatis aktif memakai akun asal', () {
      expect(
        resolveDebtPayAccount(
          originAccount: 'Tabungan A',
          autoToOrigin: true,
          selectedAccount: 'Budget Utama',
        ),
        'Tabungan A',
      );
    });

    test('rute otomatis nonaktif memakai akun pilihan manual', () {
      expect(
        resolveDebtPayAccount(
          originAccount: 'Tabungan A',
          autoToOrigin: false,
          selectedAccount: 'Tabungan B',
        ),
        'Tabungan B',
      );
    });

    test('tanpa akun asal memakai akun pilihan manual', () {
      expect(
        resolveDebtPayAccount(
          originAccount: null,
          autoToOrigin: true,
          selectedAccount: 'Budget Utama',
        ),
        'Budget Utama',
      );
    });
  });

  Future<void> pumpDebtPage(WidgetTester tester) async {
    await tester.pumpWidget(
      ToastificationWrapper(
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: savingController),
            ChangeNotifierProvider.value(value: expenseController),
            ChangeNotifierProvider.value(value: debtController),
          ],
          child: const MaterialApp(home: DebtPage()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openPayDialog(WidgetTester tester) async {
    await tester.tap(find.text('Terima Pembayaran'));
    await tester.pumpAndSettle();
  }

  group('piutang dengan sumber dana tabungan', () {
    setUp(() async {
      await Hive.box<SavingAccount>('savingsBox').add(
        SavingAccount(name: 'Tabungan A', balance: 1000),
      );
      final debt = Debt(
        id: 'piutang-tabungan-a',
        type: 'piutang',
        personName: 'Budi',
        amount: 400,
        createdAt: transactionDate,
      );
      expect(await debtController.addDebt(debt, 'Tabungan A'), isTrue);
    });

    testWidgets(
      'checkbox rute otomatis aktif dan dropdown disembunyikan',
      (tester) async {
        await pumpDebtPage(tester);
        await openPayDialog(tester);

        expect(
          find.text('Terima ke sumber dana asal (Tabungan A)'),
          findsOneWidget,
        );
        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isTrue);
        expect(find.byType(DropdownButtonFormField<String>), findsNothing);
        expect(
          find.text('Saldo: ${CurrencyInputFormatter.format(600)}'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'checkbox dimatikan menampilkan dropdown dengan akun pilihan manual',
      (tester) async {
        await pumpDebtPage(tester);
        await openPayDialog(tester);

        await tester.tap(find.text('Terima ke sumber dana asal (Tabungan A)'));
        await tester.pumpAndSettle();

        expect(tester.widget<Checkbox>(find.byType(Checkbox)).value, isFalse);
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
        expect(find.text('Ke (Tujuan Dana)'), findsOneWidget);
        expect(
          find.text('Saldo: ${CurrencyInputFormatter.format(0)}'),
          findsOneWidget,
        );
      },
    );
  });

  group('piutang tanpa ledger utama', () {
    setUp(() async {
      final debt = Debt(
        id: 'tanpa-ledger',
        type: 'piutang',
        personName: 'Dedi',
        amount: 300,
        createdAt: transactionDate,
      );
      await Hive.box<Debt>('debtBox').put(debt.id, debt);
    });

    testWidgets(
      'dialog tetap memakai dropdown manual tanpa checkbox',
      (tester) async {
        await pumpDebtPage(tester);
        await openPayDialog(tester);

        expect(find.byType(Checkbox), findsNothing);
        expect(find.text('Ke (Tujuan Dana)'), findsOneWidget);
        expect(find.byType(DropdownButtonFormField<String>), findsOneWidget);
      },
    );
  });
}
