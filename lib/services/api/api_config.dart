import 'dart:io';

/// Configuration for API client
class ApiConfig {
  // Base URLs for different environments
  static const String _developmentServerUrl = 'http://localhost:3001';
  static const String _productionServerUrl = 'https://api.mock.io';

  // Get server URL (without /api)
  static String get serverUrl {
    if (const bool.hasEnvironment('API_BASE_URL')) {
      final url = const String.fromEnvironment('API_BASE_URL');
      return url.endsWith('/api') ? url.substring(0, url.length - 4) : url;
    }
    return const bool.fromEnvironment('dart.vm.product') ? _productionServerUrl : _developmentServerUrl;
  }

  // Get base API URL (with /api)
  static String get baseUrl => '$serverUrl/api';

  // Timeout durations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 15);
  static const Duration sendTimeout = Duration(seconds: 10);

  // Retry configuration
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(milliseconds: 500);

  // Default headers
  static const Map<String, String> defaultHeaders = {
    HttpHeaders.contentTypeHeader: 'application/json',
    HttpHeaders.acceptHeader: 'application/json',
  };

  // Google OAuth configuration
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '194465876624-sgk7baou344vam0gcdsvn0rdvdk2crek.apps.googleusercontent.com',
  );

  // API endpoints
  static String get authGoogle => '$baseUrl/auth/staff/google';
  static String get authGoogleCallback => '$baseUrl/auth/staff/google/callback';
  static String get authMe => '$baseUrl/auth/staff/me';
  static String get logout => '$baseUrl/auth/staff/logout';
  static String get debugLogin => '$baseUrl/auth/staff/debug-login';

  static String get contacts => '$baseUrl/crm/contacts';
  static String contactById(String id) => '$baseUrl/crm/contacts/$id';

  static String get leads => '$baseUrl/crm/leads';
  static String leadById(String id) => '$baseUrl/crm/leads/$id';

  static String get tasks => '$baseUrl/crm/tasks';
  static String taskById(String id) => '$baseUrl/crm/tasks/$id';

  static String get tickets => '$baseUrl/tickets/staff';
  static String ticketById(String id) => '$baseUrl/tickets/staff/$id';

  static String get organizations => '$baseUrl/admin/organizations';
  static String organizationInvite(String orgId) => '$baseUrl/auth/invites/organizations/$orgId/invite';
  static String organizationInvites(String orgId) => '$baseUrl/auth/invites/organizations/$orgId/invitations';
  static String organizationById(String id) => '$baseUrl/admin/organizations/$id';

  static String get accounts => '$baseUrl/crm/accounts';
  static String accountById(String id) => '$baseUrl/crm/accounts/$id';
  static String get users => '$baseUrl/admin/users';
  static String userById(String id) => '$baseUrl/admin/users/$id';
  static String get userRoles => '$baseUrl/admin/roles';
  static String userRoleById(String id) => '$baseUrl/admin/roles/$id';
  static String get activityLogs => '$baseUrl/activity_logs';
  static String get interactions => '$baseUrl/interactions';
  static String get attachments => '$baseUrl/attachments';
  static String attachmentById(String id) => '$baseUrl/attachments/$id';

  static String get dashboard => '$baseUrl/dashboard';
  static String get external => '$baseUrl/external';
  static String get inviteAccept => '$baseUrl/auth/invites/accept';
  static String adminRevokeInvitation(String inviteId) => '$baseUrl/auth/invites/admin/invitations/$inviteId/revoke';
  static String adminViewAs(String userId) => '$baseUrl/admin/users/view-as/$userId';
}