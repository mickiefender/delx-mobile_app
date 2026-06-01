import 'package:flutter/foundation.dart';
import 'package:delx/config/api_config.dart';
import 'package:delx/services/api_service.dart';

/// Authentication service for communicating with Django auth API.
class AuthService extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  bool _isLoggedIn = false;
  String? _token;
  int? _userId;
  String? _userEmail;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _isLoggedIn;
  bool get isCustomer => _isLoggedIn && !isAdmin;
  bool get isAdmin =>
      _user != null && ((_user!['is_staff'] == true) || (_user!['is_superuser'] == true));
  String? get token => _token;
  int? get userId => _userId;
  String? get userEmail => _userEmail;
  Map<String, dynamic>? get user => _user;

  String get displayName {
    final firstName = (_user?['first_name'] ?? '').toString().trim();
    final lastName = (_user?['last_name'] ?? '').toString().trim();
    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;

    final username = (_user?['username'] ?? '').toString().trim();
    if (username.isNotEmpty) return username;

    return _userEmail ?? 'Customer';
  }

  /// Initialize auth service and check for existing session.
  Future<void> init() async {
    await apiService.init();
    _token = apiService.token;
    _userId = apiService.userId != null ? int.tryParse(apiService.userId!) : null;
    _isLoggedIn = apiService.isAuthenticated;

    if (_isLoggedIn) {
      await loadProfile();
    } else {
      _clearUserState();
    }

    notifyListeners();
  }

  /// Login with email and password.
  Future<bool> login(String email, String password) async {
    return _authenticate(
      endpoint: ApiConfig.customerLogin,
      body: {
        'email': email.trim(),
        'password': password,
      },
    );
  }

  /// Register a new customer account.
  Future<bool> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
    required String username,
  }) async {
    return _authenticate(
      endpoint: ApiConfig.customerRegister,
      body: {
        'email': email.trim(),
        'username': username.trim(),
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'phone_number': phone?.trim(),
        'password': password,
        'password2': password,
      },
    );
  }

  Future<bool> _authenticate({
    required String endpoint,
    required Map<String, dynamic> body,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await apiService.post(endpoint, body: body);
      final user = response['user'] as Map<String, dynamic>?;
      final token = response['token'] as String?;

      if (user == null || token == null || token.isEmpty) {
        _error = 'Authentication failed';
        return false;
      }

      if (_isAdminUser(user)) {
        await apiService.clearAuth();
        _clearUserState();
        _error = 'Admin accounts are not allowed in the mobile app. Please use the website.';
        return false;
      }

      await _applySession(token: token, user: user);
      return true;
    } catch (e) {
      _error = e.toString();
      debugPrint('Authentication failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  bool _isAdminUser(Map<String, dynamic> user) {
    return user['is_staff'] == true || user['is_superuser'] == true;
  }

  Future<void> _applySession({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    await apiService.setAuthToken(token);

    final userIdValue = user['id'];
    final parsedUserId = userIdValue is int
        ? userIdValue
        : int.tryParse(userIdValue?.toString() ?? '');

    if (parsedUserId != null) {
      await apiService.setUserId(parsedUserId.toString());
    }

    _token = token;
    _userId = parsedUserId;
    _userEmail = user['email']?.toString();
    _user = user;
    _isLoggedIn = true;
  }

  /// Load the current user profile from the backend.
  Future<bool> loadProfile() async {
    if (!apiService.isAuthenticated) {
      return false;
    }

    try {
      final response = await apiService.get(
        ApiConfig.customerProfile,
        requiresAuth: true,
      );

      if (_isAdminUser(response)) {
        await logout();
        _error = 'Admin accounts are not allowed in the mobile app.';
        return false;
      }

      _user = response;
      _userEmail = response['email']?.toString();
      final userIdValue = response['id'];
      _userId = userIdValue is int ? userIdValue : int.tryParse(userIdValue?.toString() ?? '');
      _isLoggedIn = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Failed to load profile: $e');
      return false;
    }
  }

  /// Logout and clear session.
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (apiService.isAuthenticated) {
        await apiService.post(
          ApiConfig.customerLogout,
          requiresAuth: true,
        );
      }
      await apiService.clearAuth();
    } finally {
      _clearUserState();
      _isLoading = false;
      notifyListeners();
    }
  }

void _clearUserState() {
    _token = null;
    _userId = null;
    _userEmail = null;
    _user = null;
    _isLoggedIn = false;
  }

  /// Clear any error messages.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}

/// Global auth service instance.
final authService = AuthService();
