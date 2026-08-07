import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/auth_storage.dart';
import '../models/user_model.dart';

/// Authentication State Management Provider
/// Features persistent session caching ("Remember Me") so reloads keep the user logged in seamlessly.
class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  UserModel? _user;
  String? _token;
  bool _isLoading = false;
  String? _errorMessage;

  String _activeView = 'customer';
  bool _isMerchantAccount = false;
  bool _rememberMe = true;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty && _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String get activeView => _activeView;
  bool get isMerchantAccount => _isMerchantAccount || (_user != null && (_user!.isMerchant || _user!.isAdmin));
  bool get rememberMe => _rememberMe;

  AuthProvider() {
    _loadSavedSession();
  }

  /// Restores saved session from local storage immediately on app start/reload
  Future<void> _loadSavedSession() async {
    _rememberMe = await AuthStorage.getRememberMe();
    final savedToken = await AuthStorage.getToken();
    final cachedUserJson = await AuthStorage.getUserData();

    if (savedToken != null && savedToken.isNotEmpty) {
      _token = savedToken;

      // Hydrate user from cached storage first for instant non-blocking UI load
      if (cachedUserJson != null && cachedUserJson.isNotEmpty) {
        try {
          final Map<String, dynamic> userMap = jsonDecode(cachedUserJson);
          _user = UserModel.fromJson(userMap);
          _isMerchantAccount = _user!.isMerchant || _user!.isAdmin;
          _activeView = _isMerchantAccount ? 'merchant' : 'customer';
          notifyListeners();
        } catch (_) {}
      }

      // Background validation against Laravel Server API
      try {
        final response = await _apiClient.dio.get('/customer/profile');
        if (response.statusCode == 200 && response.data != null && response.data['user'] != null) {
          _user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
          _isMerchantAccount = _user!.isMerchant || _user!.isAdmin;
          _activeView = _isMerchantAccount ? 'merchant' : 'customer';

          // Refresh cached user storage
          await AuthStorage.saveUserData(jsonEncode(_user!.toJson()));
          notifyListeners();
          return;
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          // Token explicitly revoked by server -> clear session
          await logout();
        }
      } catch (_) {
        // Keep cached session if offline
      }
    }
  }

  /// Authenticates user credentials strictly against Laravel DB
  Future<bool> login({
    required String phone,
    required String password,
    bool rememberMe = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _rememberMe = rememberMe;
    notifyListeners();

    final cleanInput = phone.trim();

    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'login': cleanInput,
          'email': cleanInput,
          'phone': cleanInput,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        _token = data['access_token'] as String?;

        if (data['user'] != null) {
          _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
          _isMerchantAccount = _user!.isMerchant || _user!.isAdmin;
          _activeView = _isMerchantAccount ? 'merchant' : 'customer';
        }

        if (_rememberMe && _token != null && _token!.isNotEmpty) {
          await AuthStorage.saveToken(_token!);
          await AuthStorage.saveRememberMe(true);
          if (_user != null) {
            await AuthStorage.saveUserData(jsonEncode(_user!.toJson()));
          }
        } else {
          await AuthStorage.saveRememberMe(false);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Invalid credentials.';
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          _errorMessage = data['message'].toString();
        } else {
          _errorMessage = 'Invalid email/phone or password.';
        }
      } else {
        _errorMessage = 'Unable to connect to Candela server. Please check your connection.';
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
    }

    _token = null;
    _user = null;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Registers a new customer strictly in Laravel Database
  Future<bool> register({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'name': name.trim(),
          'phone': phone.trim(),
          'password': password,
          if (email != null && email.isNotEmpty) 'email': email.trim(),
        },
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        _token = data['access_token'] as String?;

        if (data['user'] != null) {
          _user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
          _isMerchantAccount = _user!.isMerchant || _user!.isAdmin;
          _activeView = 'customer';
        }

        if (_token != null && _token!.isNotEmpty) {
          await AuthStorage.saveToken(_token!);
          await AuthStorage.saveRememberMe(true);
          if (_user != null) {
            await AuthStorage.saveUserData(jsonEncode(_user!.toJson()));
          }
        }

        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.data['message'] ?? 'Registration failed.';
      }
    } on DioException catch (e) {
      if (e.response != null && e.response?.data != null) {
        final data = e.response?.data;
        if (data is Map && data.containsKey('message')) {
          _errorMessage = data['message'].toString();
        } else {
          _errorMessage = 'Registration failed. Please check your inputs.';
        }
      } else {
        _errorMessage = 'Unable to connect to Candela server. Please check your connection.';
      }
    } catch (e) {
      _errorMessage = 'An unexpected error occurred: ${e.toString()}';
    }

    _token = null;
    _user = null;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  /// Switches active UI view between 'merchant' and 'customer'
  void switchRole(String targetRole) {
    if (_user == null) return;
    _activeView = targetRole.toLowerCase() == 'merchant' ? 'merchant' : 'customer';
    notifyListeners();
  }

  Future<void> logout() async {
    await AuthStorage.clearSession();
    _token = null;
    _user = null;
    _activeView = 'customer';
    _isMerchantAccount = false;
    notifyListeners();
  }
}
