import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/user_profile.dart';

class UserController extends ChangeNotifier {
  final Box<UserProfile> _userBox = Hive.box<UserProfile>('userBox');

  UserProfile? get user => _userBox.isNotEmpty ? _userBox.getAt(0) : null;

  void setUser(String name) {
    if (_userBox.isEmpty) {
      _userBox.add(UserProfile(name: name));
    } else {
      _userBox.putAt(0, UserProfile(name: name));
    }
    notifyListeners();
  }

  void clearUser() {
    _userBox.clear();
    notifyListeners();
  }
}
