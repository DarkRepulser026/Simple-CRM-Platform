import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage service for JWT tokens and organization data
/// Wraps SharedPreferences for persistent storage
class SecureStorage {
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'current_user';
  static const String _organizationKey = 'selected_organization';

  final SharedPreferences _prefs;

  SecureStorage(this._prefs);

  /// Create instance with initialized SharedPreferences
  static Future<SecureStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return SecureStorage(prefs);
  }

  /// Save JWT token
  Future<void> saveToken(String token) async {
    await _prefs.setString(_tokenKey, token);
  }

  /// Read JWT token
  Future<String?> readToken() async {
    return _prefs.getString(_tokenKey);
  }

  /// Clear JWT token
  Future<void> clearToken() async {
    await _prefs.remove(_tokenKey);
  }

  /// Save current user data as JSON string
  Future<void> saveUser(String userJson) async {
    await _prefs.setString(_userKey, userJson);
  }

  /// Read current user data as JSON string
  Future<String?> readUser() async {
    return _prefs.getString(_userKey);
  }

  /// Clear current user data
  Future<void> clearUser() async {
    await _prefs.remove(_userKey);
  }

  /// Save selected organization data as JSON string
  Future<void> saveOrganization(String organizationJson) async {
    await _prefs.setString(_organizationKey, organizationJson);
  }

  /// Read selected organization data as JSON string
  Future<String?> readOrganization() async {
    return _prefs.getString(_organizationKey);
  }

  /// Clear selected organization data
  Future<void> clearOrganization() async {
    await _prefs.remove(_organizationKey);
  }

  /// Clear all auth-related data
  Future<void> clearAll() async {
    await clearToken();
    await clearUser();
    await clearOrganization();
  }
}