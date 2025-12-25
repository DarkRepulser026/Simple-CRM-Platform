import '../models/dashboard_metrics.dart';
import '../models/activity_log.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'auth/auth_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Dashboard summary data with role-based metrics
class DashboardSummary {
  final String userRole;
  final Map<String, dynamic> metrics;
  final List<String> widgets;

  DashboardSummary({
    required this.userRole,
    required this.metrics,
    required this.widgets,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      userRole: json['userRole'] as String? ?? 'AGENT',
      metrics: json['metrics'] as Map<String, dynamic>? ?? {},
      widgets: (json['widgets'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

/// Work queue item (ticket or task)
class WorkQueueItem {
  final String id;
  final String type; // 'ticket' or 'task'
  final String title;
  final String status;
  final String? priority;
  final DateTime? dueDate;
  final String? assignedTo;
  final String? accountName;

  WorkQueueItem({
    required this.id,
    required this.type,
    required this.title,
    required this.status,
    this.priority,
    this.dueDate,
    this.assignedTo,
    this.accountName,
  });

  factory WorkQueueItem.fromJson(Map<String, dynamic> json) {
    return WorkQueueItem(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String?,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      assignedTo: json['assignedTo'] as String?,
      accountName: json['accountName'] as String?,
    );
  }
}

/// Service for managing dashboard operations
class DashboardService {
  final ApiClient _apiClient;
  final AuthService _authService;

  DashboardService({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  /// Get dashboard metrics (legacy method, kept for backward compatibility)
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

  /// Get dashboard summary with role-based KPIs
  /// Agent: My work stats
  /// Manager: Team overview, SLA metrics
  /// Admin: System health, organization stats
  Future<Result<DashboardSummary, ApiError>> getSummary() async {
    if (!_authService.isAuthenticated || !_authService.hasSelectedOrganization) {
      return Result.error(ApiError.unauthorized());
    }

    return _apiClient.get<DashboardSummary>(
      '/crm/dashboard/summary',
      headers: await _getAuthHeaders(),
      fromJson: DashboardSummary.fromJson,
    );
  }

  /// Get user's assigned work queue (tickets + tasks)
  Future<Result<List<WorkQueueItem>, ApiError>> getMyWork() async {
    if (!_authService.isAuthenticated || !_authService.hasSelectedOrganization) {
      return Result.error(ApiError.unauthorized());
    }

    final headers = await _getAuthHeaders();
    if (kDebugMode) {
      print('🔑 My Work Headers: $headers');
      print('👤 User ID: ${_authService.currentUser?.id}');
      print('🏢 Org ID: ${_authService.selectedOrganizationId}');
    }

    try {
      final result = await _apiClient.get<dynamic>(
        '/crm/dashboard/my-work',
        headers: headers,
      );

      if (!result.isSuccess) {
        return Result.error(result.error);
      }

      if (kDebugMode) {
        print('📦 My Work Response: ${result.value}');
        print('📦 Response Type: ${result.value.runtimeType}');
      }
      
      // Handle the response
      final responseData = result.value;
      
      if (responseData is! List) {
        if (kDebugMode) {
          print('❌ Expected List but got ${responseData.runtimeType}');
        }
        return Result.error(ApiError.parsing('Expected List but got ${responseData.runtimeType}'));
      }
      
      final items = (responseData as List<dynamic>)
          .map((item) => WorkQueueItem.fromJson(item as Map<String, dynamic>))
          .toList();
      
      if (kDebugMode) {
        print('✅ Parsed ${items.length} work items');
      }
      
      return Result.success(items);
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ getMyWork error: $e');
        print('Stack trace: $stackTrace');
      }
      return Result.error(ApiError.parsing('Failed to parse work items: $e'));
    }
  }

  /// Get team work queue (Manager+ only) - unassigned and at-risk items
  Future<Result<Map<String, dynamic>, ApiError>> getTeamWork() async {
    if (!_authService.isAuthenticated || !_authService.hasSelectedOrganization) {
      return Result.error(ApiError.unauthorized());
    }

    return _apiClient.get<Map<String, dynamic>>(
      '/crm/dashboard/team-work',
      headers: await _getAuthHeaders(),
      fromJson: (json) => json,
    );
  }

  /// Get recent activity feed
  Future<Result<List<ActivityLog>, ApiError>> getActivity({int limit = 20}) async {
    if (!_authService.isAuthenticated || !_authService.hasSelectedOrganization) {
      return Result.error(ApiError.unauthorized());
    }

    return _apiClient.get<List<ActivityLog>>(
      '/crm/dashboard/activity?limit=$limit',
      headers: await _getAuthHeaders(),
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => ActivityLog.fromJson(item))
          .toList(),
    );
  }

  /// Get upcoming tasks due today/tomorrow
  Future<Result<Map<String, dynamic>, ApiError>> getUpcomingTasks() async {
    if (!_authService.isAuthenticated || !_authService.hasSelectedOrganization) {
      return Result.error(ApiError.unauthorized());
    }

    if (kDebugMode) {
      print('🔜 Fetching upcoming tasks...');
    }

    final result = await _apiClient.get<Map<String, dynamic>>(
      '/crm/dashboard/upcoming-tasks',
      headers: await _getAuthHeaders(),
      fromJson: (json) => json,
    );

    if (kDebugMode) {
      if (result.isSuccess) {
        print('🔜 Upcoming Tasks Response: ${result.value}');
      } else {
        print('❌ Upcoming Tasks Error: ${result.error.message}');
      }
    }

    return result;
  }

  /// Get system-wide activity (Admin only)
  Future<Result<List<ActivityLog>, ApiError>> getSystemActivity({int limit = 50}) async {
    if (!_authService.isAuthenticated || !_authService.hasSelectedOrganization) {
      return Result.error(ApiError.unauthorized());
    }

    return _apiClient.get<List<ActivityLog>>(
      '/crm/dashboard/system-activity?limit=$limit',
      headers: await _getAuthHeaders(),
      fromJson: (json) => (json as List<dynamic>)
          .map((item) => ActivityLog.fromJson(item))
          .toList(),
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

/// Task item model for upcoming tasks
class TaskItem {
  final String id;
  final String title;
  final String? description;
  final DateTime? dueDate;
  final bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isCompleted = false,
  });

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? json['subject'] as String? ?? '',
      description: json['description'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? json['status'] == 'COMPLETED',
    );
  }
}