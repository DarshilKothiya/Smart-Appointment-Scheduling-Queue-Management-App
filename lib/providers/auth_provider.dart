import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService();

  bool _isLoggedIn = false;
  bool _isLoading = false;
  String _role = 'user'; // 'user' | 'admin'
  String _userName = '';
  String? _errorMessage;

  bool get isLoggedIn => _isLoggedIn;
  bool get isLoading => _isLoading;
  bool get isAdmin => _role == 'admin';
  String get role => _role;
  String get userName => _userName;
  String? get errorMessage => _errorMessage;

  // Called on app start — restores session
  Future<void> checkSession() async {
    _isLoading = true;
    notifyListeners();

    _isLoggedIn = await _auth.isLoggedIn();
    if (_isLoggedIn) {
      _role = await _auth.getUserRole();
      _userName = await _auth.getUserName();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _auth.login(username: username, password: password);

    if (result.success) {
      _isLoggedIn = true;
      _role = result.role;
      _userName = username.trim().toLowerCase();
      _errorMessage = null;
    } else {
      _errorMessage = result.message;
    }

    _isLoading = false;
    notifyListeners();
    return result.success;
  }

  Future<void> logout() async {
    await _auth.logout();
    _isLoggedIn = false;
    _role = 'user';
    _userName = '';
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
