import 'package:hive/hive.dart';

part 'user_settings.g.dart';

@HiveType(typeId: 4)
class UserSettings extends HiveObject {
  @HiveField(0)
  int payday;

  @HiveField(1, defaultValue: true)
  bool isNotificationEnabled;

  @HiveField(2, defaultValue: false)
  bool resetBalanceOnPayday;

  @HiveField(3, defaultValue: 0xFF1E3A8A)
  int themeColor;

  @HiveField(4, defaultValue: 'standard')
  String budgetingMode;

  @HiveField(5, defaultValue: true)
  bool isBalanceHidden; // Mode privasi aktif secara default

  UserSettings({
    required this.payday,
    this.isNotificationEnabled = true,
    this.resetBalanceOnPayday = false,
    this.themeColor = 0xFF1E3A8A,
    this.budgetingMode = 'standard',
    this.isBalanceHidden = true,
  });
}
