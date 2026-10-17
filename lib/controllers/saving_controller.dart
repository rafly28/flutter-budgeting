import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/expense.dart';
import '../models/saving_account.dart';
import '../services/market_api_service.dart';

class SavingController extends ChangeNotifier {
  /// Beri tahupendengar bahwa data di luar controller berubah (mis. setelah
  /// restore backup yang mengganti isi box). Dipanggil juga setelah add/remove
  /// sinkron, jadi regenerate tampilan tanpa perlu rebuild manual.
  void refresh() => notifyListeners();

  final Box<SavingAccount> _box = Hive.box<SavingAccount>('savingsBox');

  List<SavingAccount> get savings => _box.values.toList();

  /// Total kekayaan: saldo tunai plus nilai pasar aset investasi.
  double get totalSavingsBalance =>
      savings.fold(0.0, (sum, item) => sum + item.marketValue);

  /// Bagian kas (rekeningbank / e-wallet).
  double get cashBalance =>
      savings
          .where((item) => !item.isInvestment)
          .fold(0.0, (sum, item) => sum + item.balance);

  /// Bagian investasi (emas, crypto, saham) dihitung dari harga pasar.
  double get investmentBalance =>
      savings
          .where((item) => item.isInvestment)
          .fold(0.0, (sum, item) => sum + item.marketValue);

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
    String unitLabel = '',
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
          unitLabel: unitLabel,
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
    String? unitLabel,
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
    final oldPocketCategory = account.pocketCategory;
    final oldAssetType = account.assetType;
    final oldUnitCount = account.unitCount;
    final oldAvgBuyPrice = account.avgBuyPrice;
    final oldSymbol = account.symbol;
    final oldUnitLabel = account.unitLabel;
    final oldPriceFetchedAt = account.priceFetchedAt;

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
    if (unitLabel != null) account.unitLabel = unitLabel;
    try {
      await account.save();
    } catch (_) {
      // Kembalikan SEMUA field yang disentuh, bukan hanya lima yang pertama.
      // Kalau tidak, edit yang gagal bisa diam-diam tersimpan di movements
      // berikutnya.
      account.name = oldName;
      account.bankName = oldBank;
      account.accountNumber = oldAccountNumber;
      account.accountHolderName = oldHolder;
      account.balance = oldBalance;
      account.pocketCategory = oldPocketCategory;
      account.assetType = oldAssetType;
      account.unitCount = oldUnitCount;
      account.avgBuyPrice = oldAvgBuyPrice;
      account.symbol = oldSymbol;
      account.unitLabel = oldUnitLabel;
      account.priceFetchedAt = oldPriceFetchedAt;
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

  /// Harga per unit yang dipakai untuk mengubah rupiah menjadi unit.
  ///
  /// Membeli aset memakai harga jual toko ([lastMarketPrice]) karena itu
  /// harga yang benar-benar dibayar pengguna. Menjual memakai harga buyback
  /// ([lastBuybackPrice]) karena itu harga yang benar-benar diterima pengguna,
  /// jadi spread tidak mengubah jumlah unit secara diam-diam.
  ///
  /// Kalau harga pasar belum pernah diambil, jatuh ke modal beli rata-rata.
  /// Mengembalikan null kalau tidak ada harga sama sekali — pemanggil harus
  /// menolak transaksi daripada menebak angka.
  double? conversionPriceFor(
    SavingAccount account, {
    required bool incoming,
  }) {
    if (!account.isInvestment) return null;
    if (incoming) {
      if (account.lastMarketPrice > 0) return account.lastMarketPrice;
      return account.avgBuyPrice > 0 ? account.avgBuyPrice : null;
    }
    if (account.lastBuybackPrice > 0) return account.lastBuybackPrice;
    if (account.lastMarketPrice > 0) return account.lastMarketPrice;
    return account.avgBuyPrice > 0 ? account.avgBuyPrice : null;
  }

  /// Jumlah unit yang akan dibeli atau dijual untuk sejumlah rupiah.
  ///
  /// Null kalau tidak ada harga untuk dikonversi.
  double? unitsForAmount(
    SavingAccount account, {
    required double amount,
    required bool incoming,
  }) {
    final price = conversionPriceFor(account, incoming: incoming);
    if (price == null || price <= 0 || !amount.isFinite) return null;
    return amount / price;
  }

  /// Jumlah unit yang bisa dijual pada [price].
  ///
  /// Akun investasi yang dibuat sebelum hierarki unit ada bisa punya modal
  /// tanpa unit; modal itu dinilai sebagai unit pada harga saat ini supaya
  /// nilai yang tampil dan yang bisa ditarik tetap sama.
  double availableUnits(SavingAccount account, double price) {
    if (account.unitCount > unitTolerance) return account.unitCount;
    if (account.balance > 0 && price > 0) return account.balance / price;
    return 0;
  }

  /// Menyetorkan rupiah ke akun investasi dengan membeli unit.
  ///
  /// Beli: unit dan modal naik, [SavingAccount.avgBuyPrice] jadi rata-rata
  /// tertimbang. Jual: unit turun dan modal sisanya ikut prorata, sementara
  /// [SavingAccount.avgBuyPrice] tidak berubah karena harga beli rata-rata
  /// unit yang tersisa memang sama.
  ///
  /// [price] dipakai apa adanya supaya pembatalan transaksi bisa membalik
  /// jumlah unit persis, walau harga pasar sudah berubah.
  ///
  /// Mengembalikan false kalau unit yang dijual tidak cukup — sisa aset tidak
  /// boleh minus.
  Future<bool> applyInvestmentFlow(
    SavingAccount account,
    double amount, {
    required bool incoming,
    required double price,
  }) async {
    if (!account.isInvestment) {
      await updateBalance(
        account,
        amount,
        incoming ? 'income' : 'expense',
      );
      return true;
    }
    if (!amount.isFinite || amount <= 0 || !price.isFinite || price <= 0) {
      return false;
    }

    final previousBalance = account.balance;
    final previousUnitCount = account.unitCount;
    final previousAvgBuyPrice = account.avgBuyPrice;
    final units = amount / price;

    // Data lama bisa punya modal tapi belum punya unit (mis. akun emas yang
    // dibuat sebelum hierarki unit ada). Modal itu dinilai sebagai unit yang
    // dibeli di harga saat ini supaya nilainya tidak anjlok saat akun dipakai
    // untuk transfer.
    final seededUnits =
        account.unitCount <= unitTolerance && account.balance > 0
            ? account.balance / price
            : 0.0;
    if (seededUnits > 0 && account.avgBuyPrice <= 0) {
      account.avgBuyPrice = price;
    }

    if (incoming) {
      account.unitCount += seededUnits + units;
      account.balance += amount;
      account.avgBuyPrice =
          account.unitCount > 0 ? account.balance / account.unitCount : 0.0;
    } else {
      if (availableUnits(account, price) + unitTolerance < units) return false;
      account.unitCount = account.unitCount + seededUnits - units;
      if (account.unitCount <= unitTolerance) {
        account.unitCount = 0.0;
      }
      // Modal yang tersisa ikut berkurang secara proporsional supaya
      // avgBuyPrice tetap jadi harga beli rata-rata unit yang tersisa.
      account.balance = account.unitCount * account.avgBuyPrice;
    }

    try {
      await account.save();
    } catch (_) {
      account.balance = previousBalance;
      account.unitCount = previousUnitCount;
      account.avgBuyPrice = previousAvgBuyPrice;
      return false;
    }
    notifyListeners();
    return true;
  }

  /// Toleransi floating point untuk perbandingan jumlah unit.
  static const unitTolerance = 1e-9;

  /// Harga pasar satu akun saja, dipakai sebelum transfer ke/from investasi
  /// yang belum punya harga. Mengembalikan null kalau tidak bisa diambil,
  /// supaya pemanggil bisa menolak transaksi dengan pesan yang jelas.
  Future<double?> refreshPriceFor(
    SavingAccount account, {
    required bool incoming,
  }) async {
    final price = await MarketApiService.fetchPrice(
      account.assetType,
      account.symbol,
    );
    if (price == null || price.sell <= 0) return null;

    final changed =
        account.lastMarketPrice != price.sell ||
        account.lastBuybackPrice != price.buyback;
    account.lastMarketPrice = price.sell;
    account.lastBuybackPrice = price.buyback;
    account.priceFetchedAt = DateTime.now();
    try {
      await account.save();
    } catch (_) {
      return conversionPriceFor(account, incoming: incoming);
    }
    if (changed) notifyListeners();
    return conversionPriceFor(account, incoming: incoming);
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
    if (expense.type != 'transfer') return null;

    final stored = expense.transferDestination?.trim();
    if (stored != null && stored.isNotEmpty) return stored;

    final note = expense.note;
    if (note == null) return null;
    final prefix = 'Dari ${expense.source} ke ';
    if (!note.startsWith(prefix)) return null;

    final body = note.substring(prefix.length);
    final candidates = savings
        .map((account) => account.name)
        .where((name) => name.isNotEmpty && body.startsWith('$name.'))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    if (candidates.isNotEmpty) return candidates.first;

    final end = body.indexOf('.');
    final fallback = (end >= 0 ? body.substring(0, end) : body).trim();
    return fallback.isEmpty ? null : fallback;
  }

  Future<void> refreshMarketPrices() async {
    var updated = false;

    for (final acc in savings.toList()) {
      if (!acc.isInvestment) continue;
      // Emas tidak butuh ticker; hanya crypto/saham yang butuh simbol.
      final price = await MarketApiService.fetchPrice(
        acc.assetType,
        acc.symbol,
      );
      if (price == null || price.sell <= 0) continue;

      acc.lastMarketPrice = price.sell;
      acc.lastBuybackPrice = price.buyback;
      acc.priceFetchedAt = DateTime.now();
      try {
        await acc.save();
      } catch (_) {
        continue;
      }
      updated = true;
    }

    if (updated) notifyListeners();
  }
}
