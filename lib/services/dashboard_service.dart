import '../models/dashboard_metrics.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'auth/auth_service.dart';

/// Service for managing dashboard operations
class DashboardService {
  final ApiClient _apiClient;
  final AuthService _authService;

  DashboardService({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  /// Get dashboard metrics
  Future<Result<DashboardMetrics, ApiError>> getDashboardMetrics() async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    // Check if organization is selected
    if (!_authService.hasSelectedOrganization) {
      return Result.error(ApiError.unauthorized('Organization not selected'));
    }

    return _apiClient.get<DashboardMetrics>(
      ApiConfig.dashboard,
      headers: await _getAuthHeaders(),
      fromJson: DashboardMetrics.fromJson,
    );
  }

  /// Get authentication headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = _authService.jwtToken;
    final orgId = _authService.selectedOrganizationId;

    final headers = <String, String>{};

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    if (orgId != null) {
      headers['X-Organization-ID'] = orgId;
    }

    return headers;
  }
}