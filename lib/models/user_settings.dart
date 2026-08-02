import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(
  typeId: 4,
) // Menggunakan ID 4 agar tidak bentrok dengan model sebelumnya
class UserSettings extends HiveObject {
  @HiveField(0)
  int payday; // Menyimpan tanggal gajian/tutup buku (contoh: 25)

  @HiveField(1, defaultValue: true)
  bool isNotificationEnabled;

  @HiveField(2, defaultValue: false)
  bool resetBalanceOnPayday;

  UserSettings({
    required this.payday,
    this.isNotificationEnabled = true,
    this.resetBalanceOnPayday = false,
  });
}
