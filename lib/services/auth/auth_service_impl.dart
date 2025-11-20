import 'dart:convert';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/organization.dart';
import '../../models/user.dart';
import '../api/api_client.dart';
import '../api/api_config.dart';
import '../storage/secure_storage.dart';
import 'auth_service.dart';

/// Real authentication service implementation using Google Sign-In
class AuthServiceImpl implements AuthService {
  final SecureStorage _storage;
  final ApiClient _apiClient;

  User? _currentUser;
  String? _jwtToken;
  Organization? _selectedOrganization;

  // Use the plugin instance
  GoogleSignIn get _googleSignIn => GoogleSignIn.instance;

  AuthServiceImpl(this._storage, this._apiClient);

  @override
  Future<void> initialize() async {
    try {
      // No side-effectful listeners required for now.
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
      await _storage.clearAll();
    }
  }

  // No custom _handleAuthenticationEvent required

  @override
  Future<bool> signInWithGoogle() async {
    try {
      debugPrint('AuthServiceImpl.signInWithGoogle called');

      // Explicit sign-in (triggers popup on platforms where plugin supports it)
      // Use dynamic invocation to avoid analyzer issues with plugin API versions
      final dynamic googleSignInDynamic = _googleSignIn as dynamic;
      final GoogleSignInAccount? googleUser = await googleSignInDynamic.signIn();

      if (googleUser == null) {
        debugPrint('Google sign-in cancelled');
        return false;
      }

      return await _processGoogleSignIn(googleUser);
    } catch (e) {
      debugPrint('Sign-in error: $e');
      return false;
    }
  }

  /// Helper method to process Google sign-in authentication
  Future<bool> _processGoogleSignIn(GoogleSignInAccount googleUser) async {
    try {
      // Get ID token for backend
      final GoogleSignInAuthentication auth = await googleUser.authentication;

      // Exchange with backend
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.authGoogle,
        body: {
          'idToken': auth.idToken,
          'email': googleUser.email,
          'name': googleUser.displayName,
          'googleId': googleUser.id,
        },
      );

      if (response.isError) {
        debugPrint('Backend auth failed: ${response.error}');
        return false;
      }

      final authData = response.value;
      _jwtToken = authData['token'] as String;
      _currentUser = User.fromJson(authData['user'] as Map<String, dynamic>);

      await _storage.saveToken(_jwtToken!);
      await _storage.saveUser(jsonEncode(_currentUser!.toJson()));

      debugPrint('Sign-in success: ${_currentUser!.email}');
      return true;
    } catch (e) {
      debugPrint('Sign-in processing error: $e');
      return false;
    }
  }

  @override
  Future<void> logout() async {
    try {
      // 🔹 Full disconnect (clears local + Google session)
      await _googleSignIn.disconnect();

      _currentUser = null;
      _jwtToken = null;
      _selectedOrganization = null;
      await _storage.clearAll();

      debugPrint('Logged out successfully');
    } catch (e) {
      debugPrint('Logout error: $e');
      // Still clear local state
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

  @override
  Future<void> selectOrganization(String organizationId) async {
    _selectedOrganization = Organization(
      id: organizationId,
      name: 'Organization $organizationId',
    );
    await _storage.saveOrganization(jsonEncode(_selectedOrganization!.toJson()));
    debugPrint('Selected organization: $organizationId');
  }

  @override
  Future<bool> signInWithGoogleIdToken(String idToken) async {
    try {
      // Decode the ID token to extract basic profile info for the backend
      String? email;
      String? name;
      String? googleId;
      try {
        final decoded = JwtDecoder.decode(idToken);
        email = decoded['email'] as String?;
        name = decoded['name'] as String?;
        googleId = decoded['sub'] as String?;
      } catch (_) {
        // ignore - backend can still handle when only idToken is provided
      }

      // Exchange the ID token with the backend for a JWT and user info
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.authGoogle,
        body: {
          'idToken': idToken,
          if (email != null) 'email': email,
          if (name != null) 'name': name,
          if (googleId != null) 'googleId': googleId,
        },
      );
      if (response.isError) {
        debugPrint('Backend auth failed (web): \\${response.error}');
        return false;
      }
      final authData = response.value;
      _jwtToken = authData['token'] as String;
      _currentUser = User.fromJson(authData['user'] as Map<String, dynamic>);
      await _storage.saveToken(_jwtToken!);
      await _storage.saveUser(jsonEncode(_currentUser!.toJson()));
      debugPrint('Web sign-in success: \\${_currentUser!.email}');
      return true;
    } catch (e) {
      debugPrint('Web sign-in error: \\${e.toString()}');
      return false;
    }
  }
}