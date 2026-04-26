import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';
import '../models/user_settings.dart';
import '../services/notification_service.dart';

class UserController extends ChangeNotifier {
  final Box<UserProfile> _userBox = Hive.box<UserProfile>('userBox');
  final Box<UserSettings> _settingsBox = Hive.box<UserSettings>(
    'userSettingsBox',
  );

  UserProfile? get user => _userBox.isNotEmpty ? _userBox.getAt(0) : null;

  bool get isNotificationEnabled => _settingsBox.isNotEmpty
      ? (_settingsBox.getAt(0)?.isNotificationEnabled ?? true)
      : true;

  // Secara default tanggal 1 jika user belum mengatur
  int get payday => _settingsBox.isNotEmpty ? _settingsBox.getAt(0)!.payday : 1;

  void setUser(String name) {
    if (_userBox.isEmpty) {
      _userBox.add(UserProfile(name: name));
    } else {
      _userBox.putAt(0, UserProfile(name: name));
    }
    notifyListeners();
  }

  void toggleNotification(bool value) {
    if (_settingsBox.isNotEmpty) {
      final settings = _settingsBox.getAt(0)!;
      settings.isNotificationEnabled = value;
      settings.save();

      // Memicu service notifikasi
      if (value) {
        NotificationService.scheduleDailyReminder();
      } else {
        NotificationService.cancelNotification();
      }
      notifyListeners();
    } else {
      // Jika box kosong (saat onboarding belum selesai sempurna)
      _settingsBox.add(UserSettings(payday: 1, isNotificationEnabled: value));
    }
  }

  // 👈 Method baru untuk mengubah tanggal tutup buku
  void setPayday(int date) {
    if (_settingsBox.isEmpty) {
      _settingsBox.add(UserSettings(payday: date));
    } else {
      _settingsBox.putAt(0, UserSettings(payday: date));
    }
    notifyListeners();
  }

  void clearUser() {
    _userBox.clear();
    notifyListeners();
  }
}
