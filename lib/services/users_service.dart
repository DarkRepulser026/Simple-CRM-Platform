import '../models/user.dart';
import '../models/pagination.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'auth/auth_service.dart';

class UsersResponse {
  final List<User> users;
  final Pagination? pagination;

  UsersResponse({required this.users, this.pagination});

  factory UsersResponse.fromJson(Map<String, dynamic> json) {
    return UsersResponse(
      users: (json['users'] as List<dynamic>?)
              ?.map((u) => User.fromJson(u as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>) : null,
    );
  }
}

class UsersService {
  final ApiClient _apiClient;
  final AuthService _authService;

  UsersService({required ApiClient apiClient, required AuthService authService})
      : _apiClient = apiClient,
        _authService = authService;

  Future<Result<UsersResponse, ApiError>> getUsers({int page = 1, int limit = 20, String? search}) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final queryParams = <String, String>{'page': page.toString(), 'limit': limit.toString()};
    if (search != null && search.isNotEmpty) queryParams['search'] = search;
    final uri = Uri.parse(ApiConfig.users).replace(queryParameters: queryParams);
    return _apiClient.get<UsersResponse>(uri.toString(), headers: await _getAuthHeaders(), fromJson: UsersResponse.fromJson);
  }

  Future<Result<User, ApiError>> getUser(String id) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final url = ApiConfig.userById(id);
    return _apiClient.get<User>(url, headers: await _getAuthHeaders(), fromJson: User.fromJson);
  }

  Future<Result<User, ApiError>> createUser(User user) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final data = user.toJson();
    data.remove('id');
    return _apiClient.post<User>(ApiConfig.users, headers: await _getAuthHeaders(), body: data, fromJson: User.fromJson);
  }

  Future<Result<User, ApiError>> updateUser(User user) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final url = ApiConfig.userById(user.id);
    final data = user.toJson();
    data.remove('id');
    return _apiClient.put<User>(url, headers: await _getAuthHeaders(), body: data, fromJson: User.fromJson);
  }

  Future<Result<void, ApiError>> deleteUser(String id) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final url = ApiConfig.userById(id);
    final result = await _apiClient.delete(url, headers: await _getAuthHeaders());
    return result.isSuccess ? Result.success(null) : Result.error(result.error);
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
