import 'package:flutter/foundation.dart';
import '../../models/customer_auth.dart';
import '../api/api_exceptions.dart';
import '../auth/customer_auth_service.dart';

/// Provider for customer authentication state
class CustomerAuthProvider extends ChangeNotifier {
  final CustomerAuthService _authService;

  bool _isLoading = false;
  String? _error;

  CustomerAuthProvider({required CustomerAuthService authService})
      : _authService = authService;

  /// Check if customer is authenticated
  bool get isAuthenticated => _authService.isAuthenticated;

  /// Get current customer
  CustomerUser? get currentCustomer => _authService.currentCustomer;

  /// Check if currently loading
  bool get isLoading => _isLoading;

  /// Get current error message
  String? get error => _error;

  /// Initialize authentication state
  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authService.init();
    } catch (e) {
      _error = 'Failed to initialize authentication';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Register new customer
  Future<bool> register({
    required String email,
    required String password,
    required String name,
    String? companyName,
    String? phone,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        email: email,
        password: password,
        name: name,
        companyName: companyName,
        phone: phone,
      );

      final result = await _authService.register(request);

      if (result.isSuccess) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = _getErrorMessage(result.error);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Registration failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Login customer
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = LoginRequest(
        email: email,
        password: password,
      );

      final result = await _authService.login(request);

      if (result.isSuccess) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = _getErrorMessage(result.error);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Login failed: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Logout customer
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (e) {
      debugPrint('Logout error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get user-friendly error message
  String _getErrorMessage(ApiError error) {
    if (error is HttpError) {
      switch (error.statusCode) {
        case 400:
          return 'Invalid input. Please check your details.';
        case 401:
          return 'Invalid email or password.';
        case 409:
          return 'An account with this email already exists.';
        case 429:
          return 'Too many attempts. Please try again later.';
        default:
          return error.message;
      }
    } else if (error is NetworkError) {
      return 'Network error. Please check your connection.';
    } else if (error is TimeoutError) {
      return 'Request timeout. Please try again.';
    }
    return error.message;
  }

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }
}
