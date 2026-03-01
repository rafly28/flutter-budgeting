import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(
  typeId: 4,
) // Menggunakan ID 4 agar tidak bentrok dengan model sebelumnya
class UserSettings extends HiveObject {
  @HiveField(0)
  int payday; // Menyimpan tanggal gajian/tutup buku (contoh: 25)

  UserSettings({required this.payday});
}
