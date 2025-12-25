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

/// Enhanced activity log service with caching and batch operations
class ActivityLogService {
  final ApiClient _apiClient;
  final AuthService _authService;

  // Simple in-memory cache for recent activity logs
  final Map<String, ActivityLogsResponse> _cache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  static const Duration _cacheDuration = Duration(minutes: 5);

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
    bool ignoreCache = false,
  }) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());

    // Check cache first
    if (!ignoreCache) {
      final cacheKey = _buildCacheKey(entityType, entityId, userId, page, limit);
      final cached = _cache[cacheKey];
      final timestamp = _cacheTimestamps[cacheKey];

      if (cached != null && timestamp != null) {
        if (DateTime.now().difference(timestamp) < _cacheDuration) {
          return Result.success(cached);
        }
      }
    }

    final queryParams = <String, String>{'page': page.toString(), 'limit': limit.toString()};
    if (entityType != null && entityType.isNotEmpty) queryParams['entityType'] = entityType;
    if (entityId != null && entityId.isNotEmpty) queryParams['entityId'] = entityId;
    if (userId != null && userId.isNotEmpty) queryParams['userId'] = userId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    final uri = Uri.parse(ApiConfig.activityLogs).replace(queryParameters: queryParams);

    final res = await _apiClient.get<dynamic>(uri.toString(), headers: await _getAuthHeaders());
    if (res.isError) return Result.error(res.error);

    final val = res.value;
    late final ActivityLogsResponse response;

    if (val is List) {
      // Raw list of logs returned
      final logs = val.map((l) => ActivityLog.fromJson(l as Map<String, dynamic>)).toList();
      response = ActivityLogsResponse(logs: logs);
    } else if (val is Map<String, dynamic>) {
      response = ActivityLogsResponse.fromJson(val);
    } else {
      return Result.error(ApiError.parsing('Unexpected response shape for activity logs'));
    }

    // Cache the result
    final cacheKey = _buildCacheKey(entityType, entityId, userId, page, limit);
    _cache[cacheKey] = response;
    _cacheTimestamps[cacheKey] = DateTime.now();

    return Result.success(response);
  }

  /// Get activity logs for a specific entity with automatic pagination
  Future<Result<List<ActivityLog>, ApiError>> getEntityActivityLog(
    String entityId,
    String entityType, {
    int limit = 20,
  }) async {
    final result = await getActivityLogs(
      entityId: entityId,
      entityType: entityType,
      limit: limit,
    );

    if (result.isError) return Result.error(result.error);
    return Result.success(result.value.logs);
  }

  /// Get activity logs for multiple entities (batch operation)
  Future<Result<Map<String, List<ActivityLog>>, ApiError>> getMultipleEntityActivityLogs(
    List<String> entityIds,
    String entityType, {
    int limit = 20,
  }) async {
    if (entityIds.isEmpty) {
      return Result.success({});
    }

    final results = <String, List<ActivityLog>>{};

    for (final entityId in entityIds) {
      final result = await getEntityActivityLog(
        entityId,
        entityType,
        limit: limit,
      );

      if (result.isSuccess) {
        results[entityId] = result.value;
      }
    }

    return Result.success(results);
  }

  /// Get recent activity logs (last N days)
  Future<Result<List<ActivityLog>, ApiError>> getRecentActivity({
    int days = 7,
    int limit = 100,
  }) async {
    final result = await getActivityLogs(limit: limit);
    if (result.isError) return Result.error(result.error);

    final cutoff = DateTime.now().subtract(Duration(days: days));
    final recent = result.value.logs.where((log) => log.createdAt.isAfter(cutoff)).toList();

    return Result.success(recent);
  }

  /// Get activity by action type
  Future<Result<List<ActivityLog>, ApiError>> getActivityByActionType(
    String actionType, {
    int limit = 50,
  }) async {
    final result = await getActivityLogs(search: actionType, limit: limit);
    if (result.isError) return Result.error(result.error);

    final filtered = result.value.logs
        .where((log) => log.activityType.value.toLowerCase().contains(actionType.toLowerCase()))
        .toList();

    return Result.success(filtered);
  }

  /// Get activity by user
  Future<Result<List<ActivityLog>, ApiError>> getActivityByUser(
    String userId, {
    int limit = 50,
  }) async {
    final result = await getActivityLogs(userId: userId, limit: limit);
    if (result.isError) return Result.error(result.error);
    return Result.success(result.value.logs);
  }

  /// Clear the activity log cache (useful after bulk operations)
  void clearCache() {
    _cache.clear();
    _cacheTimestamps.clear();
  }

  /// Clear cache for a specific entity
  void clearCacheForEntity(String entityId) {
    _cache.removeWhere((key, _) => key.contains(entityId));
    _cacheTimestamps.removeWhere((key, _) => key.contains(entityId));
  }

  /// Build a cache key from query parameters
  String _buildCacheKey(String? entityType, String? entityId, String? userId, int page, int limit) {
    return '${entityType ?? 'all'}_${entityId ?? 'all'}_${userId ?? 'all'}_${page}_$limit';
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
