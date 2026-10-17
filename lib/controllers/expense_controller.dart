import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'saving_controller.dart';
import 'user_controller.dart';
import '../models/expense.dart';
import '../models/monthly_report.dart';
import '../models/saving_account.dart';
import '../services/notification_service.dart';
import '../utils/payday_cycle.dart';

class ExpenseController extends ChangeNotifier {
  /// Beri tahupendengar bahwa data di luar controller berubah (mis. setelah
  /// restore backup yang mengganti isi box). Dipanggil juga setelah add/remove
  /// sinkron, jadi regenerate tampilan tanpa perlu rebuild manual.
  void refresh() => notifyListeners();

  static const mainAccountName = 'Budget Utama';

  /// Toleransi pembulatan floating point untuk perbandingan saldo rupiah.
  static const moneyTolerance = 0.005;

  /// Alasan kegagalan terakhir yang layak ditampilkan ke pengguna. Diisi
  /// kalau transaksi ditolak karena harga aset investasi tidak bisa
  /// ditentukan — kondisi yang harus diklarifikasi, bukan diam-diam gagal.
  String? _lastFailureReason;

  String? get lastFailureReason => _lastFailureReason;

  final SavingController _savingController;
  final UserController? _userController;
  final Box<Expense> _box = Hive.box<Expense>('expensesBox');
  final Box<MonthlyReport> _reportBox = Hive.box<MonthlyReport>(
    'monthlyReportsBox',
  );

  ExpenseController(this._savingController, [this._userController]);

  // Ambil semua transaksi
  List<Expense> get expenses => _box.values.toList();

  // Ambil semua laporan bulanan
  List<MonthlyReport> get monthlyReports => _reportBox.values.toList();

  bool accountExists(String accountName) {
    return accountName == mainAccountName ||
        _savingAccount(accountName) != null;
  }

  double balanceFor(String accountName, {DateTime? at}) {
    if (accountName == mainAccountName) {
      if (_userController != null && _userController!.resetBalanceOnPayday) {
        return _mainBalanceInCycle(at ?? DateTime.now());
      }
      return balance;
    }
    final account = _savingAccount(accountName);
    if (account == null) return 0;
    // Akun investasi bisa dijual, jadi yang tersedia untuk transfer keluar
    // adalah nilai pasarnya — bukan modal yang sudah terinvestasikan.
    return account.isInvestment ? account.marketValue : account.balance;
  }

  bool canAfford(String accountName, double amount, {DateTime? at}) {
    return accountExists(accountName) &&
        amount.isFinite &&
        amount >= 0 &&
        balanceFor(accountName, at: at) >= amount;
  }

  // Tambah transaksi dan terapkan dampaknya ke rekening non-utama.
  Future<bool> addExpense(Expense expense) async {
    final effects = _validatedEffects(expense);
    _lastFailureReason = null;
    if (effects == null) return false;

    final prices = await _resolveInvestmentPrices(expense, effects);
    if (prices == null) {
      _lastFailureReason = _missingPriceReason(effects);
      return false;
    }
    expense.investmentPrices = prices;

    if (!_canApply(expense, effects, prices: prices)) return false;
    if (!await _applyEffects(effects, prices: prices)) return false;

    try {
      await _box.add(expense);
      if (kDebugMode) {
        print(
          "Transaksi disimpan ke DB: ${expense.amount}, "
          "kategori: ${expense.category}, "
          "tipe: ${expense.type}, "
          "note: ${expense.note}",
        );
      }
      final now = DateTime.now();
      if (expense.date.year == now.year &&
          expense.date.month == now.month &&
          expense.date.day == now.day) {
        NotificationService.skipTodayReminder();
      }
      notifyListeners();
      return true;
    } catch (error) {
      await _applyEffects(effects, multiplier: -1, prices: prices);
      if (kDebugMode) print('Gagal menyimpan transaksi: $error');
      return false;
    }
  }

  // Hapus berdasarkan key objek agar aman untuk daftar terfilter/terbalik.
  ///
  /// Pembatalan selalu mengembalikan efek transaksi secara terbalik, jadi
  /// income yang dihapus berarti uang ditarik dari rekening asal. Kalau
  /// saldo rekening tidak cukup, pembatalan ditolak supaya saldo tidak
  /// pernah menjadi minus.
  Future<bool> removeExpense(
    Expense expense, {
    void Function(String reason)? onFailure,
  }) async {
    final key = expense.key;
    final storedExpense = key == null ? null : _box.get(key);
    if (storedExpense == null) {
      onFailure?.call('Akun transaksi tidak ditemukan. Transaksi belum dihapus.');
      return false;
    }

    final effects = _validatedEffects(storedExpense);
    if (effects == null) {
      onFailure?.call('Transaksi tidak bisa dibatalkan. Transaksi belum dihapus.');
      return false;
    }
    // Baris lama tidak punya harga tersimpan, jadi pakai harga yang ada
    // sekarang. Pembatalan yang butuh harga baru tidak bisa dihitung, dan
    // lebih baik ditolak daripada membalik unit dengan tebakan.
    final prices = _storedInvestmentPrices(storedExpense, effects);
    if (prices == null) {
      onFailure?.call(
        'Harga aset investasi sudah tidak tersedia, jadi transaksi belum bisa '
        'dibatalkan. Refresh harga di halaman Tabungan.',
      );
      return false;
    }
    if (!_canReverseEffects(effects, prices)) {
      final debitAccount = _reverseDebitAccount(effects, prices);
      onFailure?.call(
        'Saldo ${debitAccount ?? ''} tidak cukup untuk membatalkan '
        'transaksi ini. Transaksi belum dihapus.',
      );
      return false;
    }
    if (!await _applyEffects(effects, multiplier: -1, prices: prices)) {
      onFailure?.call('Gagal memperbarui saldo rekening. Transaksi belum dihapus.');
      return false;
    }

    try {
      await _box.delete(key);
      if (kDebugMode) {
        print('Expense key $key dihapus dari Hive');
      }
      notifyListeners();
      return true;
    } catch (error) {
      await _applyEffects(effects, prices: prices);
      if (kDebugMode) print('Gagal menghapus transaksi: $error');
      onFailure?.call('Gagal menghapus transaksi. Transaksi belum dihapus.');
      return false;
    }
  }

  /// Rekening yang akan didebet saat pembatalan, untuk pesan error.
  String? _reverseDebitAccount(
    Map<String, double> effects,
    Map<String, double> prices,
  ) {
    for (final entry in effects.entries) {
      if (entry.value <= 0) continue;
      if (_canCover(entry.key, entry.value, prices)) continue;
      return entry.key;
    }
    return null;
  }

  /// True bila pembatalan [effects] tidak akan membuat saldo rekening mana pun
  /// menjadi minus.
  ///
  /// Pembatalan memakai multiplier -1, jadi entri positif (rekening yang
  /// dikreditkan saat transaksi dibuat) justru jadi debit. Income dan
  /// transfer masuk termasuk kategori ini.
  bool _canReverseEffects(
    Map<String, double> effects,
    Map<String, double> prices,
  ) {
    for (final entry in effects.entries) {
      if (entry.value <= 0) continue;
      if (!_canCover(entry.key, entry.value, prices)) return false;
    }
    return true;
  }

  // Edit memakai snapshot lama dan objek baru supaya saldo dapat dibalik tepat.
  Future<bool> updateExpense(
    Expense previousExpense,
    Expense updatedExpense,
  ) async {
    if (identical(previousExpense, updatedExpense)) return false;
    _lastFailureReason = null;

    final key = previousExpense.key;
    final storedExpense = key == null ? null : _box.get(key);
    if (storedExpense == null) return false;

    updatedExpense.planId ??= storedExpense.planId;
    updatedExpense.debtId ??= storedExpense.debtId;

    final previousEffects = _validatedEffects(storedExpense);
    if (previousEffects == null) return false;
    final previousPrices = _storedInvestmentPrices(storedExpense, previousEffects);
    if (previousPrices == null) {
      _lastFailureReason =
          'Harga aset investasi sudah tidak tersedia, jadi transaksi belum '
          'bisa diubah. Refresh harga di halaman Tabungan.';
      return false;
    }
    if (!_canReverseEffects(previousEffects, previousPrices)) return false;

    final updatedEffects = _validatedEffects(updatedExpense);
    if (updatedEffects == null) return false;
    final newPrices = await _resolveInvestmentPrices(
      updatedExpense,
      updatedEffects,
    );
    if (newPrices == null) {
      _lastFailureReason = _missingPriceReason(updatedEffects);
      return false;
    }
    updatedExpense.investmentPrices = newPrices;

    // Efek lama dibalik dulu supaya saldo rekening kembali persis seperti
    // sebelum transaksi ini dibuat. Validate dan apply yang baru dihitung
    // terhadap keadaan itu, bukan terhadap saldo yang sudah digeser.
    if (!await _applyEffects(previousEffects, multiplier: -1, prices: previousPrices)) {
      return false;
    }

    if (!_canApply(updatedExpense, updatedEffects, prices: newPrices) ||
        !await _applyEffects(updatedEffects, prices: newPrices)) {
      await _applyEffects(previousEffects, prices: previousPrices);
      return false;
    }

    try {
      await _box.put(key, updatedExpense);
      if (kDebugMode) {
        print(
          "Expense key $key diperbarui: ${updatedExpense.amount}, "
          "kategori: ${updatedExpense.category}, "
          "tipe: ${updatedExpense.type}, "
          "note: ${updatedExpense.note}",
        );
      }
      notifyListeners();
      return true;
    } catch (error) {
      await _applyEffects(updatedEffects, multiplier: -1, prices: newPrices);
      await _applyEffects(previousEffects, prices: previousPrices);
      if (kDebugMode) print('Gagal memperbarui transaksi: $error');
      return false;
    }
  }

  double _mainIncomeInRange(DateTime start, DateTime end) {
    double baseIncome = _box.values
        .where((e) {
          final inRange = e.date.isAfter(start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(end.add(const Duration(days: 1)));
          return inRange && e.type == "income" && e.source == mainAccountName;
        })
        .fold(0.0, (sum, e) => sum + e.amount);
    double transferIn = _box.values
        .where((e) {
          final inRange = e.date.isAfter(start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(end.add(const Duration(days: 1)));
          return inRange &&
              e.type == 'transfer' &&
              transferDestinationOf(e) == mainAccountName;
        })
        .fold(0.0, (sum, e) => sum + e.amount);
    return baseIncome + transferIn;
  }

  double _mainExpenseInRange(DateTime start, DateTime end) {
    double baseExpense = _box.values
        .where((e) {
          final inRange = e.date.isAfter(start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(end.add(const Duration(days: 1)));
          return inRange && e.type == "expense" && e.source == mainAccountName;
        })
        .fold(0.0, (sum, e) => sum + e.amount);
    double transferOut = _box.values
        .where((e) {
          final inRange = e.date.isAfter(start.subtract(const Duration(days: 1))) &&
              e.date.isBefore(end.add(const Duration(days: 1)));
          return inRange && e.type == 'transfer' && e.source == mainAccountName;
        })
        .fold(0.0, (sum, e) => sum + e.amount);
    return baseExpense + transferOut;
  }

  double _mainBalanceInCycle(DateTime at) {
    final payday = _userController?.payday ?? 1;
    final cycle = PaydayCycle.of(at, payday);
    final totalIncome = _mainIncomeInRange(cycle.start, cycle.end);
    final totalExpense = _mainExpenseInRange(cycle.start, cycle.end);
    return totalIncome - totalExpense;
  }

  // Hitung total pemasukan (semua data)
  double get totalIncome {
    double baseIncome = _box.values
        .where((e) => e.type == "income" && e.source == mainAccountName)
        .fold(0.0, (sum, e) => sum + e.amount);
    double transferIn = _box.values
        .where(
          (e) =>
              e.type == 'transfer' &&
              transferDestinationOf(e) == mainAccountName,
        )
        .fold(0.0, (sum, e) => sum + e.amount);
    return baseIncome + transferIn;
  }

  // Hitung total pengeluaran (semua data)
  double get totalExpense {
    double baseExpense = _box.values
        .where((e) => e.type == "expense" && e.source == mainAccountName)
        .fold(0.0, (sum, e) => sum + e.amount);
    double transferOut = _box.values
        .where((e) => e.type == 'transfer' && e.source == mainAccountName)
        .fold(0.0, (sum, e) => sum + e.amount);
    return baseExpense + transferOut;
  }

  // Hitung saldo akhir (semua data)
  double get balance => totalIncome - totalExpense;

  // Tutup bulan → simpan laporan bulanan
  void closeMonth() {
    if (_box.isEmpty) return;

    final now = DateTime.now();
    final monthKey = "${now.year}-${now.month.toString().padLeft(2, '0')}";

    final report = MonthlyReport(
      month: monthKey,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: balance,
    );

    _reportBox.put(monthKey, report);

    if (kDebugMode) {
      print(
        "📊 Monthly Report disimpan: $monthKey "
        "(Income: ${report.totalIncome}, "
        "Expense: ${report.totalExpense}, "
        "Balance: ${report.balance})",
      );
    }

    notifyListeners();
  }

  // Filter transaksi berdasarkan bulan & tahun
  List<Expense> getExpensesByMonth(int year, int month) {
    return _box.values
        .where((e) => e.date.year == year && e.date.month == month)
        .toList();
  }

  List<Expense> getExpensesByDateRange(DateTime startDate, DateTime endDate) {
    return _box.values.where((e) {
      // Mengambil transaksi yang berada di antara startDate dan endDate
      return e.date.isAfter(startDate.subtract(const Duration(days: 1))) &&
          e.date.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  SavingAccount? _savingAccount(String accountName) {
    for (final account in _savingController.savings) {
      if (account.name == accountName) return account;
    }
    return null;
  }

  /// Tujuan transfer dari [expense], atau null kalau ini bukan transfer.
  ///
  /// Memakai [Expense.transferDestination] kalau ada (data, jadi aman dari
  /// nama akun yang mengandung titik). Baris lama fallback ke parsing note.
  String? transferDestinationOf(Expense expense) {
    if (expense.type != 'transfer') return null;

    final stored = expense.transferDestination?.trim();
    if (stored != null && stored.isNotEmpty) return stored;

    return _legacyTransferDestination(expense);
  }

  /// Memulihkan tujuan transfer dari note baris lama (sebelum field
  /// transferDestination ada).
  ///
  /// Nama akun bisa mengandung titik ("PT. BCA"), jadi separator titik
  /// pertama tidak bisa dipakai. Sebagai gantinya kandidat dicocokkan dengan
  /// nama rekening yang benar-benar ada, dari yang terpanjang supaya
  /// "PT. BCA" menang atas "PT".
  String? _legacyTransferDestination(Expense expense) {
    final note = expense.note;
    if (note == null) return null;

    final prefix = 'Dari ${expense.source} ke ';
    if (!note.startsWith(prefix)) return null;

    final body = note.substring(prefix.length);

    final candidates = _savingController.savings
        .map((account) => account.name)
        .where((name) => name.isNotEmpty && body.startsWith('$name.'))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));

    if (candidates.isNotEmpty) return candidates.first;

    // Destinasi tidak lagi ada di daftar rekening: pakai separator pertama.
    final end = body.indexOf('.');
    final fallback = (end >= 0 ? body.substring(0, end) : body).trim();
    return fallback.isEmpty ? null : fallback;
  }

  Map<String, double>? _validatedEffects(Expense expense) {
    if (!expense.amount.isFinite || expense.amount <= 0) return null;

    final effects = <String, double>{};
    switch (expense.type) {
      case 'income':
        effects[expense.source] = expense.amount;
        break;
      case 'expense':
        effects[expense.source] = -expense.amount;
        break;
      case 'transfer':
        final destination = transferDestinationOf(expense);
        if (destination == null || destination == expense.source) return null;
        effects[expense.source] = -expense.amount;
        effects.update(
          destination,
          (value) => value + expense.amount,
          ifAbsent: () => expense.amount,
        );
        break;
      default:
        return null;
    }

    return effects.keys.every(accountExists) ? effects : null;
  }

  bool _canApply(
    Expense expense,
    Map<String, double> effects, {
    required Map<String, double> prices,
  }) {
    if (expense.type != 'expense' && expense.type != 'transfer') return true;
    if (effects[expense.source] != -expense.amount) return false;
    return _canCover(
      expense.source,
      expense.amount,
      prices,
      at: expense.date,
    );
  }

  /// True kalau [accountName] masih bisa menanggung [amount] rupiah keluar.
  ///
  /// Rekening tunai dan Budget Utama dibandingkan dari saldo. Aset investasi
  /// dibandingkan dari jumlah unit yang dimiliki, karena yang membatasi
  /// penjualan adalah unit — bukan nilai pasarnya yang ikut bergerak bersama
  /// harga.
  bool _canCover(
    String accountName,
    double amount,
    Map<String, double> prices, {
    DateTime? at,
  }) {
    final account = _savingAccount(accountName);
    if (account != null && account.isInvestment) {
      final price = prices[accountName];
      if (price == null || price <= 0) return false;
      final units = _savingController.availableUnits(account, price);
      return units + SavingController.unitTolerance >= amount / price;
    }
    return balanceFor(accountName, at: at) + moneyTolerance >= amount;
  }

  /// Harga per unit untuk setiap aset investasi yang tersentuh [effects].
  ///
  /// Memakai harga yang tersimpan di [expense] kalau ada, supaya pembatalan
  /// dan edit membalik jumlah unit dengan harga yang sama. Kalau belum ada —
  /// transaksi baru atau baris lama — coba ambil harga pasar satu kali.
  ///
  /// Mengembalikan null kalau ada aset investasi yang price-nya tetap tidak
  /// bisa ditentukan.
  Future<Map<String, double>?> _resolveInvestmentPrices(
    Expense expense,
    Map<String, double> effects,
  ) async {
    final prices = <String, double>{};
    for (final entry in effects.entries) {
      if (entry.key == mainAccountName || entry.value == 0) continue;
      final account = _savingAccount(entry.key);
      if (account == null || !account.isInvestment) continue;

      final incoming = entry.value > 0;
      final stored = expense.investmentPrices[entry.key];
      if (stored != null && stored > 0) {
        prices[entry.key] = stored;
        continue;
      }
      var price = _savingController.conversionPriceFor(
        account,
        incoming: incoming,
      );
      if (price == null) {
        price = await _savingController.refreshPriceFor(
          account,
          incoming: incoming,
        );
      }
      if (price == null || price <= 0) return null;
      prices[entry.key] = price;
    }
    return prices;
  }

  /// Harga yang tersimpan di [expense] untuk aset investasi di [effects],
  /// tanpa menyentuh jaringan. Null kalau ada aset yang price-nya hilang,
  /// supaya pembatalan tidak pernah memakai tebakan.
  Map<String, double>? _storedInvestmentPrices(
    Expense expense,
    Map<String, double> effects,
  ) {
    final prices = <String, double>{};
    for (final entry in effects.entries) {
      if (entry.key == mainAccountName || entry.value == 0) continue;
      final account = _savingAccount(entry.key);
      if (account == null || !account.isInvestment) continue;

      final stored = expense.investmentPrices[entry.key];
      if (stored != null && stored > 0) {
        prices[entry.key] = stored;
        continue;
      }
      final fallback = _savingController.conversionPriceFor(
        account,
        incoming: entry.value > 0,
      );
      if (fallback == null || fallback <= 0) return null;
      prices[entry.key] = fallback;
    }
    return prices;
  }

  /// Pesan yang menjelaskan kenapa transaksi ditolak karena harga aset
  /// investasi tidak bisa ditentukan.
  String _missingPriceReason(Map<String, double> effects) {
    final blocked = effects.keys
        .map(_savingAccount)
        .whereType<SavingAccount>()
        .where((account) => account.isInvestment)
        .map((account) => account.name)
        .toList();
    if (blocked.isEmpty) {
      return 'Transaksi gagal disimpan karena akun terkait tidak ditemukan.';
    }
    return 'Harga ${blocked.join(', ')} belum tersedia, jadi jumlah unitnya '
        'tidak bisa dihitung. Refresh harga di halaman Tabungan, lalu coba '
        'lagi.';
  }

  Future<bool> _applyEffects(
    Map<String, double> effects, {
    double multiplier = 1,
    required Map<String, double> prices,
  }) async {
    final applied = <MapEntry<String, double>>[];
    try {
      for (final entry in effects.entries) {
        final delta = entry.value * multiplier;
        if (entry.key == mainAccountName || delta == 0) continue;

        final account = _savingAccount(entry.key);
        if (account == null) throw StateError('Akun ${entry.key} tidak ada');
        final price = account.isInvestment ? (prices[entry.key] ?? 0) : 1.0;
        if (account.isInvestment && (price <= 0 || !price.isFinite)) {
          throw StateError('Harga aset ${entry.key} tidak tersedia');
        }
        final ok = await _savingController.applyInvestmentFlow(
          account,
          delta.abs(),
          incoming: delta > 0,
          price: price,
        );
        if (!ok) {
          throw StateError(
            'Perubahan ${entry.key} tidak bisa diterapkan '
            '(unit tidak cukup atau aset bukan investasi)',
          );
        }
        applied.add(MapEntry(entry.key, delta));
      }
      return true;
    } catch (error) {
      for (final entry in applied.reversed) {
        final account = _savingAccount(entry.key);
        if (account == null) continue;
        final price = account.isInvestment ? (prices[entry.key] ?? 0) : 1.0;
        if (account.isInvestment && (price <= 0 || !price.isFinite)) continue;
        try {
          await _savingController.applyInvestmentFlow(
            account,
            entry.value.abs(),
            incoming: entry.value < 0,
            price: price,
          );
        } catch (rollbackError) {
          if (kDebugMode) {
            print('Gagal mengembalikan saldo rekening: $rollbackError');
          }
        }
      }
      if (kDebugMode) print('Gagal memperbarui saldo rekening: $error');
      return false;
    }
  }

  // Hapus transaksi lama lebih dari X bulan.
  //
  // Saldo rekening harus ikut dibalik supaya tetap konsisten dengan ledger,
  // dan baris yang terhubung ke hutang/piutang dilewati supaya tidak merusak
  // pembukuan DebtController.
  Future<int> cleanupOldExpenses({int months = 6}) async {
    final now = DateTime.now();
    final cutoffDate = DateTime(now.year, now.month - months, now.day);

    final candidates = _box.values.where((expense) {
      if (expense.debtId != null) return false;
      if (!expense.date.isBefore(cutoffDate)) return false;
      final effects = _validatedEffects(expense);
      if (effects == null) return false;
      final prices = _storedInvestmentPrices(expense, effects);
      return prices != null && _canReverseEffects(effects, prices);
    }).toList();

    var removed = 0;
    for (final expense in candidates) {
      if (await removeExpense(expense)) removed++;
    }

    if (removed > 0 && kDebugMode) {
      print('🧹 $removed transaksi lama dihapus (lebih dari $months bulan)');
    }
    return removed;
  }
}
