import '../../models/customer_auth.dart';
import '../../utils/result.dart';
import '../api/api_exceptions.dart';
import '../customer_api_service.dart';
import '../storage/secure_storage.dart';

/// Customer authentication service
/// Manages customer login/logout and authentication state
class CustomerAuthService {
  final CustomerApiService _apiService;
  final SecureStorage _storage;

  CustomerUser? _currentCustomer;
  bool _isAuthenticated = false;

  CustomerAuthService({
    required CustomerApiService apiService,
    required SecureStorage storage,
  })  : _apiService = apiService,
        _storage = storage;

  /// Check if customer is authenticated
  bool get isAuthenticated => _isAuthenticated;

  /// Get current customer
  CustomerUser? get currentCustomer => _currentCustomer;

  /// Initialize auth state from storage
  Future<void> init() async {
    final token = await _storage.readToken();
    if (token != null) {
      // Verify token is still valid
      final result = await _apiService.verifyToken();
      if (result.isSuccess && result.value.isValid) {
        _currentCustomer = result.value.user;
        _isAuthenticated = true;
      } else {
        // Token invalid, clear it
        await _clearAuth();
      }
    }
  }

  /// Register new customer
  Future<Result<CustomerUser, ApiError>> register(RegisterRequest request) async {
    final result = await _apiService.register(request);
    
    if (result.isSuccess) {
      _currentCustomer = result.value.user;
      _isAuthenticated = true;
      await _saveCustomerData(result.value.user);
      return Result.success(result.value.user);
    }

    return Result.error(result.error);
  }

  /// Login customer
  Future<Result<CustomerUser, ApiError>> login(LoginRequest request) async {
    final result = await _apiService.login(request);
    
    if (result.isSuccess) {
      _currentCustomer = result.value.user;
      _isAuthenticated = true;
      await _saveCustomerData(result.value.user);
      return Result.success(result.value.user);
    }

    return Result.error(result.error);
  }

  /// Logout customer
  Future<void> logout() async {
    await _apiService.logout();
    await _clearAuth();
  }

  /// Refresh access token
  Future<Result<String, ApiError>> refreshToken() async {
    return await _apiService.refreshAccessToken();
  }

  /// Save customer data to storage
  Future<void> _saveCustomerData(CustomerUser customer) async {
    // Optionally save customer data as JSON
    // await _storage.saveUser(jsonEncode(customer.toJson()));
  }

  /// Clear authentication state
  Future<void> _clearAuth() async {
    _currentCustomer = null;
    _isAuthenticated = false;
    await _storage.clearToken();
    await _storage.clearUser();
  }

  /// Dispose resources
  void dispose() {
    _apiService.dispose();
  }
}
