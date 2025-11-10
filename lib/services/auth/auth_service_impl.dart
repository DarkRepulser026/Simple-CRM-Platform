import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../../models/organization.dart';
import '../../models/user.dart';
import '../storage/secure_storage.dart';
import 'auth_service.dart';

/// Real authentication service implementation using Google Sign-In
class AuthServiceImpl implements AuthService {
  final SecureStorage _storage;

  User? _currentUser;
  String? _jwtToken;
  Organization? _selectedOrganization;

  AuthServiceImpl(this._storage);

  @override
  Future<void> initialize() async {
    try {
      // Load persisted auth data
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

      debugPrint('AuthService initialized: loggedIn=$isLoggedIn, hasOrg=$hasSelectedOrganization');
    } catch (e) {
      debugPrint('Error initializing auth service: $e');
      // Clear corrupted data
      await _storage.clearAll();
    }
  }

  @override
  Future<bool> signInWithGoogle() async {
    try {
      // TODO: Implement real Google Sign-In
      // For now, simulate successful sign-in
      debugPrint('AuthServiceImpl.signInWithGoogle called (placeholder)');

      // Simulate user data
      _jwtToken = 'fake-jwt-token-${DateTime.now().millisecondsSinceEpoch}';
      _currentUser = const User(
        id: 'demo-user-id',
        email: 'demo@example.com',
        name: 'Demo User',
        profileImage: null,
      );

      // Persist auth data
      await _storage.saveToken(_jwtToken!);
      await _storage.saveUser(jsonEncode(_currentUser!.toJson()));

      debugPrint('Successfully signed in (placeholder): ${_currentUser!.email}');
      return true;
    } catch (e) {
      debugPrint('Sign-In failed: $e');
      return false;
    }
  }

  @override
  Future<void> selectOrganization(String organizationId) async {
    // TODO: Fetch organization details from API
    // For now, create placeholder organization
    _selectedOrganization = Organization(
      id: organizationId,
      name: 'Organization $organizationId', // TODO: Get from API
    );

    // Persist selection
    await _storage.saveOrganization(jsonEncode(_selectedOrganization!.toJson()));

    debugPrint('Selected organization: $organizationId');
  }

  @override
  Future<void> logout() async {
    try {
      // Sign out from Google
      //await _googleSignIn.signOut();

      // Clear local state
      _currentUser = null;
      _jwtToken = null;
      _selectedOrganization = null;

      // Clear persisted data
      await _storage.clearAll();

      debugPrint('Successfully logged out');
    } catch (e) {
      debugPrint('Error during logout: $e');
      // Still clear local state even if Google sign out fails
      _currentUser = null;
      _jwtToken = null;
      _selectedOrganization = null;
      await _storage.clearAll();
    }
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