import 'package:hive/hive.dart';

part 'saving_account.g.dart';

@HiveType(typeId: 7)
class SavingAccount extends HiveObject {
  @HiveField(0)
  String name; // Contoh: "Tabungan Darurat"

  @HiveField(1)
  double balance;

  // 👇 TAMBAHAN BARU
  @HiveField(2, defaultValue: '')
  String bankName; // Contoh: "BCA", "Mandiri", "Gopay"

  @HiveField(3, defaultValue: '')
  String accountNumber; // Nomor rekening/HP

  @HiveField(4, defaultValue: '')
  String accountHolderName; // Atas nama

  SavingAccount({
    required this.name,
    this.balance = 0.0,
    this.bankName = '',
    this.accountNumber = '',
    this.accountHolderName = '',
  });
}
