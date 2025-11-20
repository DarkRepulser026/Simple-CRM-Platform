import 'dart:io';

/// Configuration for API client
class ApiConfig {
  // Base URLs for different environments
  static const String _developmentUrl = 'http://localhost:3001';
  static const String _productionUrl = 'https://api.mock.io';

  // Get base URL based on debug mode (can be overridden for testing)
  static String get baseUrl {
    if (const bool.hasEnvironment('API_BASE_URL')) {
      return const String.fromEnvironment('API_BASE_URL');
    }
    // Use development URL in debug mode, production otherwise
    return const bool.fromEnvironment('dart.vm.product') ? _productionUrl : _developmentUrl;
  }

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
  static String get authGoogle => '$baseUrl/auth/google';
  static String get authGoogleCallback => '$baseUrl/auth/google/callback';
  static String get authMe => '$baseUrl/auth/me';
  static String get logout => '$baseUrl/auth/logout';

  static String get contacts => '$baseUrl/contacts';
  static String contactById(String id) => '$baseUrl/contacts/$id';

  static String get leads => '$baseUrl/leads';
  static String leadById(String id) => '$baseUrl/leads/$id';

  static String get tasks => '$baseUrl/tasks';
  static String taskById(String id) => '$baseUrl/tasks/$id';

  static String get tickets => '$baseUrl/tickets';
  static String ticketById(String id) => '$baseUrl/tickets/$id';

  static String get organizations => '$baseUrl/organizations';
  static String organizationById(String id) => '$baseUrl/organizations/$id';

  static String get accounts => '$baseUrl/accounts';
  static String accountById(String id) => '$baseUrl/accounts/$id';
  static String get users => '$baseUrl/users';
  static String userById(String id) => '$baseUrl/users/$id';
  static String get userRoles => '$baseUrl/user_roles';
  static String userRoleById(String id) => '$baseUrl/user_roles/$id';
  static String get activityLogs => '$baseUrl/activity_logs';
  static String get interactions => '$baseUrl/interactions';
  static String get attachments => '$baseUrl/attachments';
  static String attachmentById(String id) => '$baseUrl/attachments/$id';

  static String get dashboard => '$baseUrl/dashboard';
}