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
  });
}
