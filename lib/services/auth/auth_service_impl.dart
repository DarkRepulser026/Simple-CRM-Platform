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
import '../service_locator.dart';
import '../organizations_service.dart';

/// Real authentication service implementation using Google Sign-In
class AuthServiceImpl implements AuthService {
  final SecureStorage _storage;
  final ApiClient _apiClient;

  User? _currentUser;
  String? _jwtToken;
  bool _isImpersonating = false;
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

      // If logged in with only one organization, select it automatically
      if (_jwtToken != null && _selectedOrganization == null) {
        try {
          final orgService = locator<OrganizationsService>();
          final res = await orgService.getOrganizations(page: 1, limit: 10);
          if (res.isSuccess && res.value.organizations.length == 1) {
            await selectOrganization(res.value.organizations.first.id);
          }
        } catch (e) {
          debugPrint('Failed to auto-select organization: $e');
          // ignore - optional behavior
        }
      }
      // If we had a selectedOrganization from storage but it is missing a 'role', attempt to refresh it
      if (_selectedOrganization != null && (_selectedOrganization?.role == null || _selectedOrganization?.role?.isEmpty == true)) {
        try {
          await selectOrganization(_selectedOrganization!.id);
        } catch (_) {
          // ignore - optional refresh
        }
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
  Future<bool> impersonateWithToken(String token) async {
    try {
      // Save current token as original if not already impersonating
      final current = _jwtToken;
      if (current != null) await _storage.saveOriginalToken(current);
      // Set new token
      _jwtToken = token;
      // Ask backend for user
      final me = await _apiClient.get<Map<String, dynamic>>(ApiConfig.authMe);
      if (me.isError) {
        // revert to original token if failed
        final orig = await _storage.readOriginalToken();
        if (orig != null) {
          _jwtToken = orig;
        }
        return false;
      }
      _currentUser = User.fromJson(me.value);
      await _storage.saveToken(_jwtToken!);
      await _storage.saveUser(jsonEncode(_currentUser!.toJson()));
      _isImpersonating = true;
      debugPrint('Impersonation started: ${_currentUser!.email}');
      return true;
    } catch (e) {
      debugPrint('Impersonation error: $e');
      return false;
    }
  }

  @override
  Future<bool> stopImpersonation() async {
    try {
      final orig = await _storage.readOriginalToken();
      if (orig == null) return false;
      _jwtToken = orig;
      final me = await _apiClient.get<Map<String, dynamic>>(ApiConfig.authMe);
      if (me.isError) return false;
      _currentUser = User.fromJson(me.value);
      await _storage.saveToken(_jwtToken!);
      await _storage.saveUser(jsonEncode(_currentUser!.toJson()));
      await _storage.clearOriginalToken();
      _isImpersonating = false;
      debugPrint('Impersonation stopped; restored: ${_currentUser!.email}');
      return true;
    } catch (e) {
      debugPrint('Stop impersonation error: $e');
      return false;
    }
  }

  @override
  bool get isLoggedIn => _currentUser != null && _jwtToken != null;

  @override
  bool get isImpersonating => _isImpersonating;

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
  @override
  bool get isAdmin => _selectedOrganization?.role?.trim().toUpperCase() == 'ADMIN';

  @override
  bool get isManagerOrAdmin {
    final r = _selectedOrganization?.role?.trim().toUpperCase();
    return r == 'ADMIN' || r == 'MANAGER';
  }

  @override
  Future<void> selectOrganization(String organizationId) async {
    try {
      final orgService = locator<OrganizationsService>();
      final res = await orgService.getOrganization(organizationId);
      if (!res.isError) {
        _selectedOrganization = res.value;
      } else {
        _selectedOrganization = Organization(id: organizationId, name: 'Organization $organizationId');
      }
    } catch (e) {
      _selectedOrganization = Organization(id: organizationId, name: 'Organization $organizationId');
    }
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

  @override
  Future<bool> signInWithInviteToken(String token, {String? name}) async {
    try {
      final body = {'token': token};
      if (name != null) body['name'] = name;
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.inviteAccept,
        body: body,
      );

      if (response.isError) {
        debugPrint('Invite accept failed: ${response.error}');
        return false;
      }

      final authData = response.value; // { token: 'jwt', user: {..}, organization: {id,name} }
      _jwtToken = authData['token'] as String;
      _currentUser = User.fromJson(authData['user'] as Map<String, dynamic>);
      await _storage.saveToken(_jwtToken!);
      await _storage.saveUser(jsonEncode(_currentUser!.toJson()));
      // If server returned organization info (invite target), auto-select it
      try {
        final org = authData['organization'] as Map<String, dynamic>?;
        if (org != null && org['id'] != null) {
          await selectOrganization(org['id'] as String);
        }
      } catch (_) {
        // ignore - selection is optional
      }
      debugPrint('Invite accept sign-in success: ${_currentUser!.email}');
      return true;
    } catch (e) {
      debugPrint('Invite sign-in error: $e');
      return false;
    }
  }

  /// Helper for other methods to construct auth headers using current JWT and selected org
  Future<Map<String, String>> _getAuthHeaders() async {
    final headers = <String, String>{};
    if (_jwtToken != null) headers['Authorization'] = 'Bearer $_jwtToken';
    if (_selectedOrganization != null && _selectedOrganization!.id.isNotEmpty) headers['X-Organization-ID'] = _selectedOrganization!.id;
    return headers;
  }

  @override
  Future<bool> acceptInviteTokenAsCurrentUser(String token, {String? name}) async {
    try {
      if (!isAuthenticated) return false;
      final body = {'token': token};
      if (name != null) body['name'] = name;
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.inviteAccept,
        headers: await _getAuthHeaders(),
        body: body,
      );

      if (response.isError) {
        debugPrint('Accept invite as current user failed: ${response.error}');
        return false;
      }

      // If the server returned an organization, auto-select it (but do not replace the current JWT or user)
      final authData = response.value;
      try {
        final org = authData['organization'] as Map<String, dynamic>?;
        if (org != null && org['id'] != null) {
          await selectOrganization(org['id'] as String);
        }
      } catch (_) {}

      debugPrint('Invite accepted for current user');
      return true;
    } catch (e) {
      debugPrint('Accept invite as current user error: $e');
      return false;
    }
  }

  @override
  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      // Debug endpoint for development/testing
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConfig.debugLogin,
        body: {
          'email': email,
          'password': password,
        },
      );

      if (response.isError) {
        debugPrint('Debug login failed: ${response.error}');
        return false;
      }

      final authData = response.value;
      final token = authData['token'] as String?;
      final userJson = authData['user'] as Map<String, dynamic>?;
      final orgJson = authData['organization'] as Map<String, dynamic>?;

      if (token == null || userJson == null) {
        debugPrint('Invalid debug login response');
        return false;
      }

      // Store auth data
      _jwtToken = token;
      _currentUser = User.fromJson(userJson);
      if (orgJson != null) {
        _selectedOrganization = Organization.fromJson(orgJson);
      }

      // Persist
      await _storage.saveToken(token);
      await _storage.saveUser(jsonEncode(_currentUser!.toJson()));
      if (_selectedOrganization != null) {
        await _storage.saveOrganization(jsonEncode(_selectedOrganization!.toJson()));
      }

      debugPrint('Debug login successful for $email');
      return true;
    } catch (e) {
      debugPrint('Debug login error: $e');
      return false;
    }
  }
}