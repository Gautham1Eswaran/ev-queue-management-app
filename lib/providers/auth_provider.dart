import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/token_manager.dart';
import '../models/models.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;

  Future<bool> login(String username, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _apiService.login(username, password);
      final token = response['token'] ?? 'mock_token'; // Ensure backend returns token
      await TokenManager.saveToken(token);
      _user = User.fromJson(response);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<bool> register(Map<String, dynamic> userData) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.register(userData);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> logout() async {
    await TokenManager.clearAll();
    _user = null;
    notifyListeners();
  }

  Future<void> checkLoginStatus() async {
    final isLoggedIn = await TokenManager.isLoggedIn();
    if (isLoggedIn) {
      // In a real app, you'd fetch user profile here
      // _user = await _apiService.getProfile();
    }
    notifyListeners();
  }
}
