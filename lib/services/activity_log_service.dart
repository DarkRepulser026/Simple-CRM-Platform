import '../models/activity_log.dart';
import '../models/pagination.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'auth/auth_service.dart';

class ActivityLogsResponse {
  final List<ActivityLog> logs;
  final Pagination? pagination;

  ActivityLogsResponse({required this.logs, this.pagination});

  factory ActivityLogsResponse.fromJson(Map<String, dynamic> json) {
    return ActivityLogsResponse(
      logs: (json['logs'] as List<dynamic>?)
              ?.map((l) => ActivityLog.fromJson(l as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>) : null,
    );
  }
}

class ActivityLogService {
  final ApiClient _apiClient;
  final AuthService _authService;

  ActivityLogService({required ApiClient apiClient, required AuthService authService})
      : _apiClient = apiClient,
        _authService = authService;

  Future<Result<ActivityLogsResponse, ApiError>> getActivityLogs({
    int page = 1,
    int limit = 20,
    String? entityType,
    String? entityId,
    String? userId,
    String? search,
  }) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final queryParams = <String, String>{'page': page.toString(), 'limit': limit.toString()};
    if (entityType != null && entityType.isNotEmpty) queryParams['entityType'] = entityType;
    if (entityId != null && entityId.isNotEmpty) queryParams['entityId'] = entityId;
    if (userId != null && userId.isNotEmpty) queryParams['userId'] = userId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    final uri = Uri.parse(ApiConfig.baseUrl + '/activity_logs').replace(queryParameters: queryParams);
    return _apiClient.get<ActivityLogsResponse>(uri.toString(), headers: await _getAuthHeaders(), fromJson: ActivityLogsResponse.fromJson);
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final token = _authService.jwtToken;
    final orgId = _authService.selectedOrganizationId;
    final headers = <String, String>{};
    if (token != null) headers['Authorization'] = 'Bearer $token';
    if (orgId != null) headers['X-Organization-ID'] = orgId;
    return headers;
  }
}
