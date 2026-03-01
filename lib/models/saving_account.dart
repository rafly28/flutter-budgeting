import 'package:hive/hive.dart';

part 'saving_account.g.dart';

@HiveType(typeId: 7) // Gunakan ID 7
class SavingAccount extends HiveObject {
  @HiveField(0)
  String name; // Contoh: "Tabungan Darurat", "Rekening BCA"

  @HiveField(1)
  double balance; // Saldo tabungan

  SavingAccount({required this.name, this.balance = 0.0});
}
