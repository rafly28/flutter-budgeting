import 'package:hive/hive.dart';

part 'expense.g.dart'; // 👈 ini file adapter auto-generated

@HiveType(typeId: 0) // setiap model butuh ID unik
class Expense extends HiveObject {
  @HiveField(0)
  double amount;

  @HiveField(1)
  String category;

  @HiveField(2)
  String? note;

  @HiveField(3)
  DateTime date;

  @HiveField(4)
  String type; // "income" atau "expense"

  @HiveField(5, defaultValue: 'Budget Utama')
  String source;

  @HiveField(6)
  String? planId;

  @HiveField(7)
  String? debtId;

  /// Nama akun tujuan untuk transfer. Disimpan sebagai data (bukan diparse
  /// dari [note]) supaya nama akun yang mengandung titik tetap aman.
  /// Null untuk baris lama / bukan transfer.
  @HiveField(8)
  String? transferDestination;

  /// Harga per unit yang benar-benar dipakai saat transaksi ini mengubah
  /// jumlah unit sebuah akun investasi (nama akun → harga per unit).
  ///
  /// Disimpan supaya pembatalan / edit bisa membalik perubahan unit secara
  /// persis, walau harga pasar sudah berubah sejak transaksi dibuat. Baris
  /// lama dan transaksi non-investasi punya peta kosong.
  @HiveField(9, defaultValue: {})
  Map<String, double> investmentPrices;

  Expense({
    required this.amount,
    required this.category,
    this.note,
    required this.date,
    required this.type,
    this.source = 'Budget Utama',
    this.planId,
    this.debtId,
    this.transferDestination,
    this.investmentPrices = const {},
  });
}
