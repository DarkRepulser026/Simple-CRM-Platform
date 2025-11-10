import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../models/organization.dart';
import '../../models/user.dart';
import '../storage/secure_storage.dart';
import 'auth_service.dart';

/// Mock authentication service for development and testing
/// Provides hardcoded user/org data without real authentication
class AuthServiceMock implements AuthService {
  final SecureStorage _storage;

  User? _currentUser;
  String? _jwtToken;
  Organization? _selectedOrganization;

  AuthServiceMock(this._storage);

  @override
  Future<void> initialize() async {
    try {
      // Load persisted auth data (same as real impl for consistency)
      final token = await _storage.readToken();
      final userJson = await _storage.readUser();
      final orgJson = await _storage.readOrganization();

      if (token != null && userJson != null) {
        _jwtToken = token;
        _currentUser = User.fromJson(jsonDecode(userJson));
      }

      if (orgJson != null) {
        _selectedOrganization = Organization.fromJson(jsonDecode(orgJson));
      }

      debugPrint('AuthServiceMock initialized: loggedIn=$isLoggedIn, hasOrg=$hasSelectedOrganization');
    } catch (e) {
      debugPrint('Error initializing mock auth service: $e');
      await _storage.clearAll();
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('AuthServiceMock.signInWithGoogle called');

      // Simulate network delay
      await Future.delayed(const Duration(seconds: 1));

      // Return hardcoded demo user
      _jwtToken = 'mock-jwt-token-${DateTime.now().millisecondsSinceEpoch}';
      _currentUser = const User(
        id: 'mock-user-id',
        email: 'demo@mock.com',
        name: 'Mock Demo User',
        profileImage: 'https://via.placeholder.com/150',
      );

      // Persist auth data
      await _storage.saveToken(_jwtToken!);
      await _storage.saveUser(jsonEncode(_currentUser!.toJson()));

      debugPrint('Mock sign-in successful: ${_currentUser!.email}');
      return true;
    } catch (e) {
      debugPrint('Mock sign-in failed: $e');
      return false;
    }
  }

  @override
  Future<void> selectOrganization(String organizationId) async {
    debugPrint('AuthServiceMock.selectOrganization called with: $organizationId');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    // Create mock organization
    _selectedOrganization = Organization(
      id: organizationId,
      name: 'Mock Organization $organizationId',
      role: 'Admin',
    );

    // Persist selection
    await _storage.saveOrganization(jsonEncode(_selectedOrganization!.toJson()));

    debugPrint('Mock organization selected: $organizationId');
  }

  @override
  Future<void> logout() async {
    debugPrint('AuthServiceMock.logout called');

    // Simulate cleanup delay
    await Future.delayed(const Duration(milliseconds: 300));

    // Clear local state
    _currentUser = null;
    _jwtToken = null;
    _selectedOrganization = null;

    // Clear persisted data
    await _storage.clearAll();

    debugPrint('Mock logout completed');
  }

  @override
  bool get isLoggedIn => _currentUser != null && _jwtToken != null;

  @override
  bool get hasSelectedOrganization => _selectedOrganization != null;

  @override
  String? get jwtToken => _jwtToken;

  @override
  User? get currentUser => _currentUser;

  @override
  Organization? get selectedOrganization => _selectedOrganization;

  @override
  bool get isAuthenticated => isLoggedIn;

  @override
  String? get accessToken => jwtToken;

  @override
  String? get selectedOrganizationId => _selectedOrganization?.id;
}