import '../models/account.dart';
import '../models/pagination.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'auth/auth_service.dart';

class AccountsResponse {
  final List<Account> accounts;
  final Pagination? pagination;

  const AccountsResponse({
    required this.accounts,
    this.pagination,
  });

  factory AccountsResponse.fromJson(Map<String, dynamic> json) {
    return AccountsResponse(
      accounts: (json['accounts'] as List<dynamic>?)
              ?.map((a) => Account.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AccountsService {
  final ApiClient _apiClient;
  final AuthService _authService;

  AccountsService({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  Future<Result<AccountsResponse, ApiError>> getAccounts({
    int page = 1,
    int limit = 20,
    String? organizationId,
    String? search,
  }) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final queryParams = <String, String>{'page': page.toString(), 'limit': limit.toString()};
    if (organizationId != null) queryParams['organizationId'] = organizationId;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final uri = Uri.parse(ApiConfig.accounts).replace(queryParameters: queryParams);

    return _apiClient.get<AccountsResponse>(
      uri.toString(),
      headers: await _getAuthHeaders(),
      fromJson: AccountsResponse.fromJson,
    );
  }

  Future<Result<Account, ApiError>> getAccount(String id) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final url = ApiConfig.accountById(id);
    return _apiClient.get<Account>(url, headers: await _getAuthHeaders(), fromJson: Account.fromJson);
  }

  Future<Result<Account, ApiError>> createAccount(Account account) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final data = account.toJson();
    data.remove('id');
    return _apiClient.post<Account>(ApiConfig.accounts, headers: await _getAuthHeaders(), body: data, fromJson: Account.fromJson);
  }

  Future<Result<Account, ApiError>> updateAccount(Account account) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final url = ApiConfig.accountById(account.id);
    final data = account.toJson();
    data.remove('id');
    return _apiClient.put<Account>(url, headers: await _getAuthHeaders(), body: data, fromJson: Account.fromJson);
  }

  Future<Result<void, ApiError>> deleteAccount(String id) async {
    if (!_authService.isAuthenticated) return Result.error(ApiError.unauthorized());
    final url = ApiConfig.accountById(id);
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

  /// Batch get multiple accounts by IDs
  Future<Result<List<Account>, ApiError>> getAccountsByIds(List<String> accountIds) async {
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    if (accountIds.isEmpty) {
      return Result.success([]);
    }

    final accounts = <Account>[];
    for (final accountId in accountIds) {
      final res = await getAccount(accountId);
      if (res.isSuccess) {
        accounts.add(res.value);
      }
    }
    return Result.success(accounts);
  }

  /// Search accounts
  Future<Result<List<Account>, ApiError>> searchAccounts(
    String query, {
    int limit = 100,
  }) async {
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final result = await getAccounts(limit: limit, search: query);
    if (result.isError) return Result.error(result.error);
    return Result.success(result.value.accounts);
  }

  /// Get account activity log
  Future<Result<List<Map<String, dynamic>>, ApiError>> getAccountActivityLog({
    required String accountId,
    int page = 1,
    int limit = 20,
  }) async {
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final url = '${ApiConfig.accounts}/$accountId/activities';
    final uri = Uri.parse(url).replace(queryParameters: queryParams);

    final result = await _apiClient.get<Map<String, dynamic>>(
      uri.toString(),
      headers: await _getAuthHeaders(),
      fromJson: (json) => json,
    );

    if (result.isError) {
      return Result.error(result.error);
    }

    try {
      final activities = (result.value['activities'] as List<dynamic>?)
              ?.map((a) => a as Map<String, dynamic>)
              .toList() ??
          [];
      return Result.success(activities);
    } catch (e) {
      return Result.error(ApiError.parsing('Failed to parse activities: $e'));
    }
  }
}
