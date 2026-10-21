import 'package:flutter/foundation.dart';

class UserModel {
  final String name;
  final String contact;
  final bool isLoggedIn;

  UserModel({
    required this.name,
    required this.contact,
    this.isLoggedIn = false,
  });

  UserModel copyWith({
    String? name,
    String? contact,
    bool? isLoggedIn,
  }) {
    return UserModel(
      name: name ?? this.name,
      contact: contact ?? this.contact,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
    );
  }
}

class AuthProvider extends ChangeNotifier {
  UserModel _user = UserModel(
    name: 'Bé yêu',
    contact: '',
    isLoggedIn: false,
  );

  UserModel get user => _user;
  bool get isLoggedIn => _user.isLoggedIn;
  String get displayName => _user.name.isNotEmpty ? _user.name : 'Bé yêu';

  Future<bool> login(String contact, String password) async {
    // Giả lập xác thực (có thể gắn API thật khi backend triển khai)
    await Future.delayed(const Duration(milliseconds: 600));

    if (contact.trim().isEmpty || password.trim().isEmpty) {
      return false;
    }

    String derivedName = contact.contains('@')
        ? contact.split('@').first
        : 'Bé cưng';

    _user = UserModel(
      name: derivedName,
      contact: contact.trim(),
      isLoggedIn: true,
    );
    notifyListeners();
    return true;
  }

  Future<bool> register({
    required String name,
    required String contact,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    if (name.trim().isEmpty || contact.trim().isEmpty || password.length < 6) {
      return false;
    }

    _user = UserModel(
      name: name.trim(),
      contact: contact.trim(),
      isLoggedIn: true,
    );
    notifyListeners();
    return true;
  }

  void logout() {
    _user = UserModel(
      name: 'Bé yêu',
      contact: '',
      isLoggedIn: false,
    );
    notifyListeners();
  }
}
