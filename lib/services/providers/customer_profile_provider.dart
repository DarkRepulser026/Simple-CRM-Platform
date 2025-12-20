import 'package:flutter/foundation.dart';
import '../../models/customer_profile.dart';
import '../api/api_exceptions.dart';
import '../customer_api_service.dart';

/// Provider for customer profile state
class CustomerProfileProvider extends ChangeNotifier {
  final CustomerApiService _apiService;

  CustomerProfile? _profile;
  bool _isLoading = false;
  String? _error;

  CustomerProfileProvider({required CustomerApiService apiService})
      : _apiService = apiService;

  /// Get customer profile
  CustomerProfile? get profile => _profile;

  /// Check if currently loading
  bool get isLoading => _isLoading;

  /// Get current error message
  String? get error => _error;

  /// Load customer profile
  Future<void> loadProfile() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _apiService.getProfile();

      if (result.isSuccess) {
        _profile = result.value;
        _error = null;
      } else {
        _error = _getErrorMessage(result.error);
      }
    } catch (e) {
      _error = 'Failed to load profile: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update customer profile
  Future<bool> updateProfile({
    String? name,
    String? phone,
    String? companyName,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? country,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = UpdateProfileRequest(
        name: name,
        phone: phone,
        companyName: companyName,
        address: address,
        city: city,
        state: state,
        postalCode: postalCode,
        country: country,
      );

      final result = await _apiService.updateProfile(request);

      if (result.isSuccess) {
        _profile = result.value;
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
      _error = 'Failed to update profile: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Change password
  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = ChangePasswordRequest(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      final result = await _apiService.changePassword(request);

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
      _error = 'Failed to change password: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Refresh profile
  Future<void> refreshProfile() async {
    await loadProfile();
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
          return 'Current password is incorrect.';
        case 403:
          return 'You do not have permission to perform this action.';
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
}
