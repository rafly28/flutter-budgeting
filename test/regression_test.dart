import 'dart:io';

import 'package:aturduid/controllers/category_controller.dart';
import 'package:aturduid/controllers/expense_controller.dart';
import 'package:aturduid/controllers/saving_controller.dart';
import 'package:aturduid/controllers/user_controller.dart';
import 'package:aturduid/models/category_budget.dart';
import 'package:aturduid/models/monthly_report.dart';
import 'package:aturduid/models/expense.dart';
import 'package:aturduid/models/saving_account.dart';
import 'package:aturduid/models/transaction_category.dart';
import 'package:aturduid/models/user_settings.dart';
import 'package:aturduid/models/user_profile.dart';
import 'package:aturduid/services/backup_service.dart';
import 'package:aturduid/services/market_api_service.dart';
import 'package:aturduid/utils/currency_input_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory hiveDirectory;
  late SavingController savingController;
  late ExpenseController expenseController;
  late CategoryController categoryController;

  final transactionDate = DateTime(2024, 1, 15, 10);

  setUpAll(() {
    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(ExpenseAdapter());
    if (!Hive.isAdapterRegistered(5)) {
      Hive.registerAdapter(TransactionCategoryAdapter());
    }
    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(MonthlyReportAdapter());
    }
    if (!Hive.isAdapterRegistered(4)) Hive.registerAdapter(UserSettingsAdapter());
    if (!Hive.isAdapterRegistered(6)) {
      Hive.registerAdapter(CategoryBudgetAdapter());
    }
    if (!Hive.isAdapterRegistered(7)) {
      Hive.registerAdapter(SavingAccountAdapter());
    }
  });

  setUp(() async {
    hiveDirectory = await Directory.systemTemp.createTemp('aturduid-reg-');
    Hive.init(hiveDirectory.path);
    await Hive.openBox<SavingAccount>('savingsBox');
    await Hive.openBox<Expense>('expensesBox');
    await Hive.openBox<MonthlyReport>('monthlyReportsBox');
    await Hive.openBox<TransactionCategory>('categoryBox');
    await Hive.openBox<CategoryBudget>('budgetBox');
    await Hive.openBox<UserSettings>('userSettingsBox');
    await Hive.openBox<UserProfile>('userBox');

    savingController = SavingController();
    expenseController = ExpenseController(savingController);
    categoryController = CategoryController();
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

  group('removeExpense tidak boleh overdraf', () {
    test('menolak menghapus income yang sudah dibelanjakan', () async {
      final account = await addSaving('Dompet', 1000);

      final income = Expense(
        amount: 500,
        category: 'Gaji',
        date: transactionDate,
        type: 'income',
        source: account.name,
      );
      expect(await expenseController.addExpense(income), isTrue);
      expect(account.balance, 1500);

      final spend = Expense(
        amount: 1400,
        category: 'Belanja',
        date: transactionDate,
        type: 'expense',
        source: account.name,
      );
      expect(await expenseController.addExpense(spend), isTrue);
      expect(account.balance, 100);

      // Income 500 sudah terpakai oleh belanja 1400. Menghapus income itu
      // akan membuat saldo -400, jadi harus ditolak.
      String? reason;
      final removed = await expenseController.removeExpense(
        income,
        onFailure: (r) => reason = r,
      );

      expect(removed, isFalse);
      expect(reason, isNotNull);
      expect(account.balance, 100, reason: 'saldo tidak boleh menjadi minus');
      expect(expenseController.expenses, hasLength(2));
    });

    test('menolak menghapus transfer kalau rekening tujuan tidak cukup', () async {
      final source = await addSaving('Dompet', 1000);
      final destination = await addSaving('Bank', 200);

      final transfer = Expense(
        amount: 300,
        category: 'Transfer',
        note: 'Dari Dompet ke Bank.',
        date: transactionDate,
        type: 'transfer',
        source: source.name,
        transferDestination: destination.name,
      );
      expect(await expenseController.addExpense(transfer), isTrue);
      expect(source.balance, 700);
      expect(destination.balance, 500);

      // Kembalikan 300 dari Bank supaya sisa 200 < 300.
      final withdrawal = Expense(
        amount: 300,
        category: 'Tarik',
        date: transactionDate,
        type: 'expense',
        source: destination.name,
      );
      expect(await expenseController.addExpense(withdrawal), isTrue);
      expect(destination.balance, 200);

      // Membatalkan transfer akan menarik 300 kembali dari Bank yang hanya
      // punya 200.
      expect(await expenseController.removeExpense(transfer), isFalse);
      expect(source.balance, 700);
      expect(destination.balance, 200);
    });

    test('masih bisa menghapus income ketika saldo cukup', () async {
      final account = await addSaving('Dompet', 0);
      final income = Expense(
        amount: 500,
        category: 'Gaji',
        date: transactionDate,
        type: 'income',
        source: account.name,
      );
      expect(await expenseController.addExpense(income), isTrue);
      expect(await expenseController.removeExpense(income), isTrue);
      expect(account.balance, 0);
    });
  });

  group('Transfer dengan nama rekening bertitik', () {
    test('tujuan dari note legacy bisa dipulihkan dengan benar', () async {
      await addSaving('Budget Utama', 0);
      await addSaving('PT. BCA', 0);
      await addSaving('PT', 0);

      // Baris lama (tanpa field transferDestination) dengan nama akun
      // ber-titik. Parser harus memilih "PT. BCA", bukan "PT".
      final legacy = Expense(
        amount: 100,
        category: 'Transfer',
        note: 'Dari Budget Utama ke PT. BCA. setoran',
        date: transactionDate,
        type: 'transfer',
        source: 'Budget Utama',
      );
      await Hive.box<Expense>('expensesBox').add(legacy);

      expect(
        expenseController.transferDestinationOf(legacy),
        'PT. BCA',
      );
    });

    test('field transferDestination dipakai duluan', () async {
      await addSaving('Dompet', 1000);
      await addSaving('Bank', 0);

      final transfer = Expense(
        amount: 100,
        category: 'Transfer',
        note: 'Dari Dompet ke Bank. tidak relevan',
        date: transactionDate,
        type: 'transfer',
        source: 'Dompet',
        transferDestination: 'Bank',
      );
      expect(expenseController.transferDestinationOf(transfer), 'Bank');
      expect(await expenseController.addExpense(transfer), isTrue);
      final dompet = savingController.savings.firstWhere(
        (a) => a.name == 'Dompet',
      );
      final bank = savingController.savings.firstWhere(
        (a) => a.name == 'Bank',
      );
      expect(dompet.balance, 900);
      expect(bank.balance, 100);
    });
  });

  group('Investasi: modal terpisah dari nilai pasar', () {
    test('marketValue memakai unitCount x lastMarketPrice', () {
      final account = SavingAccount(
        name: 'Emas',
        balance: 10000000,
        assetType: 'gold',
        unitCount: 5,
        avgBuyPrice: 2400000,
        lastMarketPrice: 2560000,
        unitLabel: 'gram',
      );

      expect(account.isInvestment, isTrue);
      expect(account.effectiveUnitLabel, 'gram');
      // balance = modal yang diinvestasikan, tidak ditimpa harga pasar.
      expect(account.balance, 10000000);
      expect(account.marketValue, 12800000);
    });

    test('satuan default per tipe aset saat unitLabel kosong', () {
      expect(
        SavingAccount(name: 'E', assetType: 'gold', unitCount: 1)
            .effectiveUnitLabel,
        'gram',
      );
      expect(
        SavingAccount(name: 'S', assetType: 'stock', unitCount: 1)
            .effectiveUnitLabel,
        'lot',
      );
      expect(
        SavingAccount(name: 'C', assetType: 'crypto', symbol: 'bitcoin')
            .effectiveUnitLabel,
        'bitcoin',
      );
      expect(
        SavingAccount(name: 'U', assetType: 'cash').effectiveUnitLabel,
        '',
      );
      expect(
        SavingAccount(name: 'X', assetType: 'gold', unitLabel: 'oz')
            .effectiveUnitLabel,
        'oz',
      );
    });

    test('totalSavingsBalance menjumlahkan kas + nilai investasi', () async {
      await addSaving('Dompet', 500000);
      await Hive.box<SavingAccount>('savingsBox').add(
        SavingAccount(
          name: 'Emas',
          balance: 10000000,
          assetType: 'gold',
          unitCount: 5,
          lastMarketPrice: 2560000,
        ),
      );

      expect(savingController.cashBalance, 500000);
      expect(savingController.investmentBalance, 12800000);
      expect(savingController.totalSavingsBalance, 13300000);
    });

    test('setoran ke akun investasi tidak hilang saat harga disegarkan', () async {
      final gold = await addSaving('Emas', 12000000);
      await Hive.box<SavingAccount>('savingsBox').delete(gold.key);
      final goldAccount = SavingAccount(
        name: 'Emas',
        balance: 12000000,
        assetType: 'gold',
        unitCount: 5,
        avgBuyPrice: 2400000,
        lastMarketPrice: 2400000,
        lastBuybackPrice: 2300000,
      );
      await Hive.box<SavingAccount>('savingsBox').add(goldAccount);

      // Setor 1 juta ke akun emas lewat transfer.
      await addSaving('Dompet', 5000000);
      final deposit = Expense(
        amount: 1000000,
        category: 'Transfer',
        note: 'Dari Dompet ke Emas. setoran bulanan',
        date: transactionDate,
        type: 'transfer',
        source: 'Dompet',
        transferDestination: 'Emas',
      );
      expect(await expenseController.addExpense(deposit), isTrue);

      // Setoran harus menambah unit, bukan cuma modal: rupiah yang dipindahkan
      // jadi gram memakai harga jual.
      expect(goldAccount.unitCount, closeTo(5 + 1000000 / 2400000, 1e-9));
      expect(goldAccount.balance, 13000000);
      expect(goldAccount.marketValue, closeTo(13000000, 1e-6));

      // Refresh harga tidak boleh menimpa modal yang sudah disetor.
      // Di lingkungan test tidak ada jaringan, jadi harga tetap yang
      // tersimpan — yang penting saldo deposit utuh.
      await savingController.refreshMarketPrices();
      expect(goldAccount.balance, 13000000);
      expect(
        goldAccount.marketValue,
        goldAccount.unitCount * goldAccount.lastMarketPrice,
      );
    });
  });

  group('Investasi: konversi rupiah jadi unit', () {
    const sell = 2555000.0;
    const buyback = 2450000.0;

    Future<SavingAccount> addGold({
      double balance = 5000000,
      double unitCount = 2,
      double avgBuyPrice = 2500000,
    }) async {
      final account = SavingAccount(
        name: 'Emas',
        balance: balance,
        assetType: 'gold',
        unitCount: unitCount,
        avgBuyPrice: avgBuyPrice,
        lastMarketPrice: sell,
        lastBuybackPrice: buyback,
      );
      await Hive.box<SavingAccount>('savingsBox').add(account);
      return account;
    }

    test('transfer masuk memakai harga jual, bukan buyback', () async {
      final gold = await addGold(balance: 0, unitCount: 0, avgBuyPrice: 0);
      await addSaving('Dompet', 5000000);

      final deposit = Expense(
        amount: 2555000,
        category: 'Transfer',
        note: 'Dari Dompet ke Emas. beli emas',
        date: transactionDate,
        type: 'transfer',
        source: 'Dompet',
        transferDestination: 'Emas',
      );
      expect(await expenseController.addExpense(deposit), isTrue);

      // 2.555.000 / 2.555.000 = 1 gram.
      expect(gold.unitCount, closeTo(1.0, 1e-9));
      expect(gold.balance, 2555000);
      expect(gold.avgBuyPrice, closeTo(sell, 1e-6));
    });

    test('transfer keluar memakai harga buyback', () async {
      final gold = await addGold();
      await addSaving('Dompet', 0);

      // Jual 1 gram -> terima 2.450.000 (buyback), bukan 2.555.000.
      final sellGold = Expense(
        amount: 2450000,
        category: 'Transfer',
        note: 'Dari Emas ke Dompet. jual emas',
        date: transactionDate,
        type: 'transfer',
        source: 'Emas',
        transferDestination: 'Dompet',
      );
      expect(await expenseController.addExpense(sellGold), isTrue);

      expect(gold.unitCount, closeTo(1.0, 1e-9));
      // Modal sisa mengikuti unit yang tersisa dengan harga beli rata-rata.
      expect(gold.balance, closeTo(2500000, 1e-6));
      expect(gold.avgBuyPrice, closeTo(2500000, 1e-6));
      final dompet = savingController.savings.firstWhere(
        (a) => a.name == 'Dompet',
      );
      expect(dompet.balance, 2450000);
    });

    test('hapus setoran mengembalikan unit persis', () async {
      final gold = await addGold(balance: 0, unitCount: 0, avgBuyPrice: 0);
      await addSaving('Dompet', 5000000);
      final deposit = Expense(
        amount: 1000000,
        category: 'Transfer',
        note: 'Dari Dompet ke Emas.',
        date: transactionDate,
        type: 'transfer',
        source: 'Dompet',
        transferDestination: 'Emas',
      );
      expect(await expenseController.addExpense(deposit), isTrue);
      final unitsAfter = gold.unitCount;
      expect(unitsAfter, greaterThan(0));

      // Harga pasar berubah sesudah transaksi dibuat — pembatalan tetap harus
      // memakai harga tersimpan supaya unit kembali persis.
      gold.lastMarketPrice = 3000000;
      gold.lastBuybackPrice = 2900000;

      expect(await expenseController.removeExpense(deposit), isTrue);
      expect(gold.unitCount, closeTo(0.0, 1e-9));
      expect(gold.balance, 0);
    });

    test('menolak menjual lebih dari unit yang dimiliki', () async {
      final gold = await addGold();
      await addSaving('Dompet', 0);
      final sellTooMuch = Expense(
        amount: 9000000,
        category: 'Transfer',
        note: 'Dari Emas ke Dompet. jual semua',
        date: transactionDate,
        type: 'transfer',
        source: 'Emas',
        transferDestination: 'Dompet',
      );

      expect(await expenseController.addExpense(sellTooMuch), isFalse);
      expect(gold.unitCount, 2);
      expect(gold.balance, 5000000);
    });

    test('harga pasar kosong jatuh ke harga modal rata-rata', () async {
      final gold = SavingAccount(
        name: 'Emas',
        balance: 5000000,
        assetType: 'gold',
        unitCount: 2,
        avgBuyPrice: 2500000,
      );
      await Hive.box<SavingAccount>('savingsBox').add(gold);
      await addSaving('Dompet', 5000000);

      final deposit = Expense(
        amount: 5000000,
        category: 'Transfer',
        note: 'Dari Dompet ke Emas.',
        date: transactionDate,
        type: 'transfer',
        source: 'Dompet',
        transferDestination: 'Emas',
      );
      expect(await expenseController.addExpense(deposit), isTrue);
      // 5.000.000 / 2.500.000 = 2 gram.
      expect(gold.unitCount, closeTo(4.0, 1e-9));
      expect(deposit.investmentPrices['Emas'], 2500000);
    });

    test('tanpa harga sama sekali transaksi ditolak tanpa mengubah apa pun', () async {
      final gold = SavingAccount(
        name: 'Emas',
        balance: 0,
        assetType: 'gold',
        unitCount: 0,
        avgBuyPrice: 0,
      );
      await Hive.box<SavingAccount>('savingsBox').add(gold);
      await addSaving('Dompet', 5000000);

      final deposit = Expense(
        amount: 1000000,
        category: 'Transfer',
        note: 'Dari Dompet ke Emas.',
        date: transactionDate,
        type: 'transfer',
        source: 'Dompet',
        transferDestination: 'Emas',
      );
      // Jaringan tidak tersedia di test, jadi harga tetap tidak bisa diambil.
      expect(await expenseController.addExpense(deposit), isFalse);
      expect(gold.unitCount, 0);
      expect(gold.balance, 0);
      expect(expenseController.lastFailureReason, isNotNull);
      final dompet = savingController.savings.firstWhere(
        (a) => a.name == 'Dompet',
      );
      expect(dompet.balance, 5000000, reason: 'sumber tidak boleh terpotong');
    });

    test('edit nominal setoran menyesuaikan unit dan sumber', () async {
      final gold = await addGold(balance: 0, unitCount: 0, avgBuyPrice: 0);
      await addSaving('Dompet', 20000000);
      final deposit = Expense(
        amount: 2555000,
        category: 'Transfer',
        note: 'Dari Dompet ke Emas. awal',
        date: transactionDate,
        type: 'transfer',
        source: 'Dompet',
        transferDestination: 'Emas',
      );
      expect(await expenseController.addExpense(deposit), isTrue);
      expect(gold.unitCount, closeTo(1.0, 1e-9));
      final dompet = savingController.savings.firstWhere(
        (a) => a.name == 'Dompet',
      );
      expect(dompet.balance, 20000000 - 2555000);

      // Nominal jadi dua kali lipat: unit harus ikut jadi dua kali lipat,
      // dan Dompet hanya tertahan sekali penarikan.
      final updated = Expense(
        amount: 5110000,
        category: 'Transfer',
        note: 'Dari Dompet ke Emas. diubah',
        date: transactionDate,
        type: 'transfer',
        source: 'Dompet',
        transferDestination: 'Emas',
      );
      expect(await expenseController.updateExpense(deposit, updated), isTrue);
      expect(gold.unitCount, closeTo(2.0, 1e-9));
      expect(gold.balance, closeTo(5110000, 1e-6));
      expect(dompet.balance, 20000000 - 5110000);
    });
  });

  group('MarketApiService parsing harga emas', () {
    test('memilih Antam 1 gram, bukan Certicard', () {
      final rows = [
        {
          'materialType': 'Logam Mulia ANTAM Certicard gramasi 100 gram',
          'weight': 1,
          'weightUnit': 'gr',
          'sellPrice': 2493000,
          'buybackPrice': 2450000,
        },
        {
          'materialType': 'LM Antam produksi tahun 2026',
          'weight': 1,
          'weightUnit': 'gr',
          'sellPrice': 2555000,
          'buybackPrice': 2450000,
        },
      ];

      final price = MarketApiService.parseGoldPrices(rows);
      expect(price, isNotNull);
      expect(price!.sell, 2555000);
      expect(price.buyback, 2450000);
    });

    test('harga 0,5 gram diabaikan', () {
      final rows = [
        {
          'materialType': 'LM Antam',
          'weight': 0.5,
          'weightUnit': 'gr',
          'sellPrice': 1327000,
          'buybackPrice': 1135000,
        },
      ];
      expect(MarketApiService.parseGoldPrices(rows), isNull);
    });

    test('hanya ada Certicard -> tetap dipakai sebagai cadangan', () {
      final rows = [
        {
          'materialType': 'ANTAM Certicard',
          'weight': 1,
          'weightUnit': 'gr',
          'sellPrice': 2493000,
          'buybackPrice': 2400000,
        },
      ];
      final price = MarketApiService.parseGoldPrices(rows);
      expect(price?.sell, 2493000);
      expect(price?.buyback, 2400000);
    });
  });

  group('CategoryController validasi nama', () {
    test('menolak nama kosong, duplikat, dan nama sistem', () {
      expect(categoryController.validateName('   '), isNotNull);
      expect(
        categoryController.validateName('Kopi'),
        isNull,
        reason: 'nama baru harus valid',
      );
      // "Makanan" sudah ada sebagai kategori bawaan, jadi duplikat.
      expect(categoryController.validateName('Makanan'), isNotNull);
      expect(categoryController.addCategory('Makanan', 'expense'), isFalse);
      // Tipe tidak dikenal juga ditolak.
      expect(categoryController.addCategory('Kopi', 'transfer'), isFalse);
      expect(categoryController.addCategory('Kopi', 'expense'), isTrue);
      // Sekarang "Kopi" ada, jadi jadi duplikat.
      expect(categoryController.addCategory('Kopi', 'expense'), isFalse);
      expect(categoryController.addCategory('   ', 'expense'), isFalse);
      expect(categoryController.addCategory('Semua', 'expense'), isFalse);
      expect(categoryController.addCategory('Hutang', 'expense'), isFalse);
      expect(
        categoryController.addCategory('Bayar Hutang', 'income'),
        isFalse,
      );
    });

    test('rename memindahkan transaksi, limit, dan rencana', () async {
      final category = categoryController.findByName('Makanan')!;
      await Hive.box<Expense>('expensesBox').add(
        Expense(
          amount: 25000,
          category: 'Makanan',
          date: transactionDate,
          type: 'expense',
        ),
      );
      await Hive.box<CategoryBudget>('budgetBox').add(
        CategoryBudget(categoryName: 'Makanan', limitAmount: 1500000),
      );

      final renamed = await categoryController.updateCategory(
        category,
        'Makan Siang',
      );
      expect(renamed, isTrue);

      expect(
        Hive.box<Expense>('expensesBox').values.first.category,
        'Makan Siang',
      );
      expect(
        Hive.box<CategoryBudget>('budgetBox').values.first.categoryName,
        'Makan Siang',
      );
      expect(categoryController.findByName('Makanan'), isNull);
      expect(categoryController.findByName('Makan Siang'), isNotNull);
    });

    test('hapus kategori ditolak selama masih dirujuk', () async {
      await Hive.box<Expense>('expensesBox').add(
        Expense(
          amount: 25000,
          category: 'Makanan',
          date: transactionDate,
          type: 'expense',
        ),
      );

      final category = categoryController.findByName('Makanan')!;
      expect(categoryController.referenceCount('Makanan'), 1);
      expect(await categoryController.deleteCategory(category), isFalse);
      expect(categoryController.findByName('Makanan'), isNotNull);
    });

    test('hapus kategori membersihkan limit budget', () async {
      final category = categoryController.findByName('Tagihan')!;
      await Hive.box<CategoryBudget>('budgetBox').add(
        CategoryBudget(categoryName: 'Tagihan', limitAmount: 500000),
      );
      expect(categoryController.hasBudgetLimit('Tagihan'), isTrue);
      expect(categoryController.referenceCount('Tagihan'), 0);

      expect(await categoryController.deleteCategory(category), isTrue);
      expect(categoryController.findByName('Tagihan'), isNull);
      expect(
        Hive.box<CategoryBudget>('budgetBox').values,
        isEmpty,
        reason: 'limit yatim harus ikut terhapus',
      );
    });
  });

  group('BackupService round-trip', () {
    test('semua field SavingAccount tersimpan dan kembali utuh', () {
      final original = SavingAccount(
        name: 'Emas',
        balance: 12345678.9,
        bankName: '',
        accountNumber: '',
        accountHolderName: '',
        pocketCategory: 'savings',
        assetType: 'gold',
        unitCount: 5.5,
        avgBuyPrice: 2400000,
        lastMarketPrice: 2560000,
        lastBuybackPrice: 2450000,
        symbol: 'XAU',
        unitLabel: 'gram',
        priceFetchedAt: DateTime(2024, 3, 2, 11, 30),
      );

      final restored = BackupService.savingFromJson(
        BackupService.savingToJson(original),
      );

      expect(restored.name, original.name);
      expect(restored.balance, original.balance);
      expect(restored.pocketCategory, original.pocketCategory);
      expect(restored.assetType, 'gold');
      expect(restored.unitCount, 5.5);
      expect(restored.avgBuyPrice, 2400000);
      expect(restored.lastMarketPrice, 2560000);
      expect(restored.lastBuybackPrice, 2450000);
      expect(restored.symbol, 'XAU');
      expect(restored.unitLabel, 'gram');
      expect(restored.priceFetchedAt, DateTime(2024, 3, 2, 11, 30));
    });

    test('backup lama tanpa field baru tetap bisa diimpor', () {
      final restored = BackupService.savingFromJson({
        'name': 'Lama',
        'balance': 1000.0,
      });
      expect(restored.assetType, 'cash');
      expect(restored.unitCount, 0);
      expect(restored.unitLabel, '');
      expect(restored.lastBuybackPrice, 0);
      expect(restored.priceFetchedAt, isNull);
    });

    test('investmentPrices ikut tersimpan dan backup lama tetap kosong', () {
      final original = Expense(
        amount: 1000000,
        category: 'Transfer',
        note: 'Dari Dompet ke Emas.',
        date: transactionDate,
        type: 'transfer',
        source: 'Dompet',
        transferDestination: 'Emas',
        investmentPrices: {'Emas': 2555000},
      );
      final restored = BackupService.expenseFromJson(
        BackupService.expenseToJson(original),
      );
      expect(restored.investmentPrices['Emas'], 2555000);

      final legacy = BackupService.expenseFromJson({
        'amount': 1000,
        'category': 'Transfer',
        'date': DateTime(2024, 1, 15).toIso8601String(),
        'type': 'transfer',
      });
      expect(legacy.investmentPrices, isEmpty);
    });

    test('budgetGroup kategori tidak hilang saat restore', () {
      final original = TransactionCategory(
        name: 'Hiburan',
        type: 'expense',
        iconCodePoint: 0xf03b5,
        iconFontFamily: 'MaterialIcons',
        budgetGroup: 'wants',
      );
      final restored = BackupService.categoryFromJson(
        BackupService.categoryToJson(original),
      );
      expect(restored.budgetGroup, 'wants');

      // Backup lama tidak punya budgetGroup -> balik ke default 'needs'.
      expect(
        BackupService.categoryFromJson({'name': 'X', 'type': 'expense'})
            .budgetGroup,
        'needs',
      );
    });

    test('budgetingMode dan isBalanceHidden ikut tersimpan', () {
      final original = UserSettings(
        payday: 25,
        budgetingMode: 'pocket_50_30_20',
        isBalanceHidden: true,
        themeColor: 0xFF0F172A,
      );
      final restored = BackupService.settingsFromJson(
        BackupService.settingsToJson(original),
      );
      expect(restored.budgetingMode, 'pocket_50_30_20');
      expect(restored.isBalanceHidden, isTrue);
      expect(restored.themeColor, 0xFF0F172A);
    });

    test('transferDestination ikut tersimpan', () {
      final original = Expense(
        amount: 1000,
        category: 'Transfer',
        note: 'Dari Dompet ke PT. BCA. setoran',
        date: transactionDate,
        type: 'transfer',
        source: 'Dompet',
        transferDestination: 'PT. BCA',
      );
      final restored = BackupService.expenseFromJson(
        BackupService.expenseToJson(original),
      );
      expect(restored.transferDestination, 'PT. BCA');
    });

    test('export memuat seluruh field yang dibutuhkan jsonEncode', () {
      final gold = SavingAccount(
        name: 'Emas',
        assetType: 'gold',
        unitCount: 5,
        avgBuyPrice: 2400000,
        lastMarketPrice: 2560000,
        lastBuybackPrice: 2450000,
        symbol: 'XAU',
        unitLabel: 'gram',
        priceFetchedAt: DateTime(2024, 3, 2),
      );
      final encoded = BackupService.savingToJson(gold);
      for (final key in const [
        'name',
        'balance',
        'bankName',
        'accountNumber',
        'accountHolderName',
        'pocketCategory',
        'assetType',
        'unitCount',
        'avgBuyPrice',
        'lastMarketPrice',
        'lastBuybackPrice',
        'symbol',
        'unitLabel',
        'priceFetchedAt',
      ]) {
        expect(encoded.containsKey(key), isTrue, reason: 'field $key hilang');
      }
    });

    test('expense export memuat investmentPrices', () {
      final transfer = Expense(
        amount: 1000,
        category: 'Transfer',
        date: transactionDate,
        type: 'transfer',
        source: 'Dompet',
        transferDestination: 'Emas',
        investmentPrices: {'Emas': 2555000},
      );
      final encoded = BackupService.expenseToJson(transfer);
      expect(encoded.containsKey('investmentPrices'), isTrue);
    });
  });

  group('Payday reset cycle', () {
    test('saldo siklus hanya hitung transaksi dalam siklus saat reset aktif',
        () async {
      final settingsBox = Hive.box<UserSettings>('userSettingsBox');
      if (settingsBox.isNotEmpty) await settingsBox.clear();
      await settingsBox.add(UserSettings(payday: 25, resetBalanceOnPayday: true));
      final userController = UserController();
      expenseController = ExpenseController(savingController, userController);

      // Transaksi di siklus lalu
      await expenseController.addExpense(
        Expense(
          amount: 1000000,
          category: 'Gaji',
          date: DateTime(2023, 12, 20),
          type: 'income',
          source: 'Budget Utama',
        ),
      );
      // Belum ada transaksi di siklus sekarang (15 Jan 2024, siklus 25 Des 2023-24 Jan 2024)
      // Saldo siklus sekarang harus 0 - tidak boleh membawa saldo siklus lama
      expect(
        expenseController.balanceFor('Budget Utama', at: DateTime(2024, 1, 15)),
        0,
      );
      // Ledger tetap berisi semua data
      expect(expenseController.balance, 1000000);
      // Matikan reset → kembali ke all-time
      await settingsBox.clear();
      await settingsBox.add(UserSettings(payday: 25, resetBalanceOnPayday: false));
      userController.refresh();
      expect(
        expenseController.balanceFor('Budget Utama', at: DateTime(2024, 1, 15)),
        1000000,
      );
    });
  });

  group('CurrencyInputFormatter', () {
    test('teks tanpa digit tidak melempar exception', () {
      final formatter = CurrencyInputFormatter();
      const old = TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );

      expect(
        () => formatter.formatEditUpdate(
          old,
          const TextEditingValue(
            text: 'abc',
            selection: TextSelection.collapsed(offset: 3),
          ),
        ),
        returnsNormally,
      );
    });
  });
}
