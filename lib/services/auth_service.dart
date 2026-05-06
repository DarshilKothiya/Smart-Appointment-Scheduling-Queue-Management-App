import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyUserRole = 'user_role';
  static const String _keyUserName = 'user_name';

  // ── Hardcoded credentials ─────────────────────────────────────────────────
  static const Map<String, String> _userCredentials = {
    'user': 'user123',
    'admin': 'admin123',
  };

  static const Map<String, String> _roleMap = {
    'user': 'user',
    'admin': 'admin',
  };

  // ── Login ─────────────────────────────────────────────────────────────────
  Future<({bool success, String message, String role})> login({
    required String username,
    required String password,
  }) async {
    final trimmedUser = username.trim().toLowerCase();
    final trimmedPass = password.trim();

    if (trimmedUser.isEmpty || trimmedPass.isEmpty) {
      return (success: false, message: 'Please enter username and password', role: '');
    }

    final expectedPass = _userCredentials[trimmedUser];
    if (expectedPass == null) {
      return (success: false, message: 'User not found', role: '');
    }
    if (expectedPass != trimmedPass) {
      return (success: false, message: 'Incorrect password', role: '');
    }

    final role = _roleMap[trimmedUser]!;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyIsLoggedIn, true);
    await prefs.setString(_keyUserRole, role);
    await prefs.setString(_keyUserName, trimmedUser);

    return (success: true, message: 'Login successful', role: role);
  }

  // ── Logout ────────────────────────────────────────────────────────────────
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyIsLoggedIn);
    await prefs.remove(_keyUserRole);
    await prefs.remove(_keyUserName);
  }

  // ── Session check ─────────────────────────────────────────────────────────
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyIsLoggedIn) ?? false;
  }

  Future<String> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole) ?? 'user';
  }

  Future<String> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserName) ?? '';
  }
}
