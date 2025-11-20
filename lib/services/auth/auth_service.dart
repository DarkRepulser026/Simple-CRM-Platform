import '../../models/organization.dart';
import '../../models/user.dart';

/// Abstract authentication service interface
/// Provides pluggable authentication with Google Sign-In, JWT storage, and org selection
abstract class AuthService {
  /// Initialize the auth service (load persisted tokens/org)
  Future<void> initialize();

  /// Sign in with Google and obtain JWT token
  Future<bool> signInWithGoogle();

  /// Sign in with Google using an ID token (for web)
  Future<bool> signInWithGoogleIdToken(String idToken);

  /// Select an organization for the current user
  Future<void> selectOrganization(String organizationId);

  /// Logout and clear all persisted state
  Future<void> logout();

  /// Whether the user is currently logged in
  bool get isLoggedIn;

  /// Whether the user has selected an organization
  bool get hasSelectedOrganization;

  /// Current JWT token (null if not logged in)
  String? get jwtToken;

  /// Current user information (null if not logged in)
  User? get currentUser;

  /// Currently selected organization (null if not selected)
  Organization? get selectedOrganization;

  /// Whether the user is authenticated (alias for isLoggedIn)
  bool get isAuthenticated => isLoggedIn;

  /// Get the access token (alias for jwtToken)
  String? get accessToken => jwtToken;

  /// Get the selected organization ID
  String? get selectedOrganizationId => selectedOrganization?.id;
}