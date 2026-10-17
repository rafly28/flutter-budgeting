import 'package:hive/hive.dart';

part 'saving_account.g.dart';

@HiveType(typeId: 7)
class SavingAccount extends HiveObject {
  @HiveField(0)
  String name; // Contoh: "Tabungan Darurat"

  @HiveField(1)
  double balance;

  @HiveField(2, defaultValue: '')
  String bankName; // Contoh: "BCA", "Mandiri", "Gopay"

  @HiveField(3, defaultValue: '')
  String accountNumber; // Nomor rekening/HP

  @HiveField(4, defaultValue: '')
  String accountHolderName; // Atas nama

  @HiveField(5, defaultValue: 'savings')
  String pocketCategory; // 'needs', 'wants', atau 'savings'

  @HiveField(6, defaultValue: 'cash')
  String assetType; // 'cash', 'gold', 'crypto', 'stock'

  @HiveField(7, defaultValue: 0.0)
  double unitCount; // e.g., 5.0 (grams), 0.025 (BTC), 10 (lots)

  @HiveField(8, defaultValue: 0.0)
  double avgBuyPrice; // Modal beli rata-rata

  @HiveField(9, defaultValue: 0.0)
  double lastMarketPrice; // Harga pasar terakhir

  @HiveField(10, defaultValue: '')
  String symbol; // Ticker: 'XAU', 'BTC', 'BBCA.JK'

  /// Satuan dari [unitCount], mis. 'gram', 'lot', 'coin'. Kosong berarti
  /// pakai satuan default per [assetType] (lihat unitForDisplay).
  @HiveField(11, defaultValue: '')
  String unitLabel;

  /// Kapan [lastMarketPrice] terakhir benar-benar diambil dari API pasar.
  /// Dipakai untuk memberi tahu pengguna kalau harga yang tampil sudah basi.
  @HiveField(12)
  DateTime? priceFetchedAt;

  /// Harga buyback terakhir per unit — harga yang dibayar toko saat pengguna
  /// menjual kembali aset ini. Untuk emas lebih rendah dari [lastMarketPrice]
  /// (harga jual) karena ada spread. Kosong untuk aset tanpa spread
  /// (kripto/saham) maupun sebelum harga pernah diambil.
  @HiveField(13, defaultValue: 0.0)
  double lastBuybackPrice;

  SavingAccount({
    required this.name,
    this.balance = 0.0,
    this.bankName = '',
    this.accountNumber = '',
    this.accountHolderName = '',
    this.pocketCategory = 'savings',
    this.assetType = 'cash',
    this.unitCount = 0.0,
    this.avgBuyPrice = 0.0,
    this.lastMarketPrice = 0.0,
    this.symbol = '',
    this.unitLabel = '',
    this.priceFetchedAt,
    this.lastBuybackPrice = 0.0,
  });

  /// Satuan tampilan: pakai [unitLabel] kalau diisi, kalau tidak fallback
  /// ke satuan yang paling masuk akal untuk [assetType].
  String get effectiveUnitLabel {
    final trimmed = unitLabel.trim();
    if (trimmed.isNotEmpty) return trimmed;
    switch (assetType) {
      case 'gold':
        return 'gram';
      case 'stock':
        return 'lot';
      case 'crypto':
        return symbol.trim().isNotEmpty ? symbol.trim() : 'coin';
      default:
        return '';
    }
  }

  bool get isInvestment => assetType != 'cash';

  bool get hasLivePrice =>
      isInvestment && unitCount > 0 && lastMarketPrice > 0;

  /// Nilai pasar saat ini. Untuk aset non-kas [balance] berisi modal yang
  /// diinvestasikan, bukan nilai pasar, supaya setoran tidak tertimpa.
  double get marketValue {
    if (!isInvestment) return balance;
    if (unitCount <= 0 || lastMarketPrice <= 0) return balance;
    return unitCount * lastMarketPrice;
  }

  bool get hasKnownPrice => isInvestment && lastMarketPrice > 0;
}
