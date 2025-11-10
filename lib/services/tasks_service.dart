import '../models/pagination.dart';
import '../models/task.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'auth/auth_service.dart';

/// Response wrapper for paginated tasks
class TasksResponse {
  final List<Task> tasks;
  final Pagination? pagination;

  const TasksResponse({
    required this.tasks,
    this.pagination,
  });

  factory TasksResponse.fromJson(Map<String, dynamic> json) {
    return TasksResponse(
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((taskJson) => Task.fromJson(taskJson as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Service for managing tasks operations
class TasksService {
  final ApiClient _apiClient;
  final AuthService _authService;

  TasksService({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  /// Get paginated list of tasks
  Future<Result<TasksResponse, ApiError>> getTasks({
    int page = 1,
    int limit = 20,
    String? status,
    String? priority,
    String? ownerId,
    String? accountId,
    String? contactId,
    String? leadId,
    bool? overdue,
  }) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (priority != null && priority.isNotEmpty) {
      queryParams['priority'] = priority;
    }
    if (ownerId != null && ownerId.isNotEmpty) {
      queryParams['ownerId'] = ownerId;
    }
    if (accountId != null && accountId.isNotEmpty) {
      queryParams['accountId'] = accountId;
    }
    if (contactId != null && contactId.isNotEmpty) {
      queryParams['contactId'] = contactId;
    }
    if (leadId != null && leadId.isNotEmpty) {
      queryParams['leadId'] = leadId;
    }
    if (overdue != null) {
      queryParams['overdue'] = overdue.toString();
    }

    final uri = Uri.parse(ApiConfig.tasks).replace(queryParameters: queryParams);

    return _apiClient.get<TasksResponse>(
      uri.toString(),
      headers: await _getAuthHeaders(),
      fromJson: TasksResponse.fromJson,
    );
  }

  /// Get a single task by ID
  Future<Result<Task, ApiError>> getTask(String taskId) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tasks}/$taskId';

    return _apiClient.get<Task>(
      url,
      headers: await _getAuthHeaders(),
      fromJson: Task.fromJson,
    );
  }

  /// Create a new task
  Future<Result<Task, ApiError>> createTask(Task task) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final taskData = task.toJson();
    // Remove read-only fields
    taskData.remove('id');
    taskData.remove('createdAt');
    taskData.remove('updatedAt');

    return _apiClient.post<Task>(
      ApiConfig.tasks,
      headers: await _getAuthHeaders(),
      body: taskData,
      fromJson: Task.fromJson,
    );
  }

  /// Update an existing task
  Future<Result<Task, ApiError>> updateTask(Task task) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tasks}/${task.id}';
    final taskData = task.toJson();
    // Remove read-only fields
    taskData.remove('id');
    taskData.remove('createdAt');
    taskData.remove('updatedAt');

    return _apiClient.put<Task>(
      url,
      headers: await _getAuthHeaders(),
      body: taskData,
      fromJson: Task.fromJson,
    );
  }

  /// Delete a task
  Future<Result<void, ApiError>> deleteTask(String taskId) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tasks}/$taskId';

    final result = await _apiClient.delete(
      url,
      headers: await _getAuthHeaders(),
    );

    return result.isSuccess
        ? Result.success(null)
        : Result.error(result.error);
  }

  /// Mark task as completed
  Future<Result<Task, ApiError>> completeTask(String taskId) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tasks}/$taskId/complete';

    return _apiClient.post<Task>(
      url,
      headers: await _getAuthHeaders(),
      fromJson: Task.fromJson,
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