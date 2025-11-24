import '../models/pagination.dart';
import '../models/ticket.dart';
import '../models/ticket_message.dart';
import '../utils/result.dart';
import 'api/api_client.dart';
import 'api/api_config.dart';
import 'api/api_exceptions.dart';
import 'auth/auth_service.dart';

/// Response wrapper for paginated tickets
class TicketsResponse {
  final List<Ticket> tickets;
  final Pagination? pagination;

  const TicketsResponse({
    required this.tickets,
    this.pagination,
  });

  factory TicketsResponse.fromJson(Map<String, dynamic> json) {
    return TicketsResponse(
      tickets: (json['tickets'] as List<dynamic>?)
              ?.map((ticketJson) => Ticket.fromJson(ticketJson as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Response wrapper for paginated ticket messages
class TicketMessagesResponse {
  final List<TicketMessage> messages;
  final Pagination? pagination;

  const TicketMessagesResponse({
    required this.messages,
    this.pagination,
  });

  factory TicketMessagesResponse.fromJson(Map<String, dynamic> json) {
    return TicketMessagesResponse(
      messages: (json['messages'] as List<dynamic>?)
              ?.map((messageJson) => TicketMessage.fromJson(messageJson as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: json['pagination'] != null
          ? Pagination.fromJson(json['pagination'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Service for managing tickets operations
class TicketsService {
  final ApiClient _apiClient;
  final AuthService _authService;

  TicketsService({
    required ApiClient apiClient,
    required AuthService authService,
  })  : _apiClient = apiClient,
        _authService = authService;

  /// Get paginated list of tickets
  Future<Result<TicketsResponse, ApiError>> getTickets({
    int page = 1,
    int limit = 20,
    String? status,
    String? priority,
    String? type,
    String? assignedToId,
    String? customerId,
    bool? overdue,
    String? search,
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
    if (type != null && type.isNotEmpty) {
      queryParams['type'] = type;
    }
    if (assignedToId != null && assignedToId.isNotEmpty) {
      queryParams['assignedToId'] = assignedToId;
    }
    if (customerId != null && customerId.isNotEmpty) {
      queryParams['customerId'] = customerId;
    }
    if (overdue != null) {
      queryParams['overdue'] = overdue.toString();
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    final uri = Uri.parse(ApiConfig.tickets).replace(queryParameters: queryParams);

    final res = await _apiClient.get(uri.toString(), headers: await _getAuthHeaders());
    if (res.isError) return Result.error(res.error);
    final jsonList = res.value as List<dynamic>;
    final tickets = jsonList.map((t) => Ticket.fromJson(t as Map<String, dynamic>)).toList();
    return Result.success(TicketsResponse(tickets: tickets));
  }

  /// Get a single ticket by ID
  Future<Result<Ticket, ApiError>> getTicket(String ticketId) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tickets}/$ticketId';

    return _apiClient.get<Ticket>(
      url,
      headers: await _getAuthHeaders(),
      fromJson: Ticket.fromJson,
    );
  }

  /// Create a new ticket
  Future<Result<Ticket, ApiError>> createTicket(Map<String, dynamic> ticketData) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    return _apiClient.post<Ticket>(
      ApiConfig.tickets,
      headers: await _getAuthHeaders(),
      body: ticketData,
      fromJson: Ticket.fromJson,
    );
  }

  /// Update an existing ticket
  Future<Result<Ticket, ApiError>> updateTicket(String ticketId, Map<String, dynamic> ticketData) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tickets}/$ticketId';

    return _apiClient.put<Ticket>(
      url,
      headers: await _getAuthHeaders(),
      body: ticketData,
      fromJson: Ticket.fromJson,
    );
  }

  /// Delete a ticket
  Future<Result<void, ApiError>> deleteTicket(String ticketId) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tickets}/$ticketId';

    final result = await _apiClient.delete(
      url,
      headers: await _getAuthHeaders(),
    );

    return result.isSuccess
        ? Result.success(null)
        : Result.error(result.error);
  }

  /// Assign ticket to agent
  Future<Result<Ticket, ApiError>> assignTicket(String ticketId, String agentId) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tickets}/$ticketId/assign';

    return _apiClient.post<Ticket>(
      url,
      headers: await _getAuthHeaders(),
      body: {'assignedToId': agentId},
      fromJson: Ticket.fromJson,
    );
  }

  /// Resolve ticket
  Future<Result<Ticket, ApiError>> resolveTicket(String ticketId, {String? resolution}) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tickets}/$ticketId/resolve';

    return _apiClient.post<Ticket>(
      url,
      headers: await _getAuthHeaders(),
      body: resolution != null ? {'resolution': resolution} : {},
      fromJson: Ticket.fromJson,
    );
  }

  /// Close ticket
  Future<Result<Ticket, ApiError>> closeTicket(String ticketId) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tickets}/$ticketId/close';

    return _apiClient.post<Ticket>(
      url,
      headers: await _getAuthHeaders(),
      fromJson: Ticket.fromJson,
    );
  }

  /// Reopen ticket
  Future<Result<Ticket, ApiError>> reopenTicket(String ticketId) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tickets}/$ticketId/reopen';

    return _apiClient.post<Ticket>(
      url,
      headers: await _getAuthHeaders(),
      fromJson: Ticket.fromJson,
    );
  }

  /// Add satisfaction rating to ticket
  Future<Result<Ticket, ApiError>> addSatisfactionRating(String ticketId, int rating, {String? feedback}) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tickets}/$ticketId/satisfaction';

    return _apiClient.post<Ticket>(
      url,
      headers: await _getAuthHeaders(),
      body: {
        'rating': rating,
        if (feedback != null) 'feedback': feedback,
      },
      fromJson: Ticket.fromJson,
    );
  }

  /// Get ticket messages
  Future<Result<TicketMessagesResponse, ApiError>> getTicketMessages(
    String ticketId, {
    int page = 1,
    int limit = 50,
  }) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    final uri = Uri.parse('${ApiConfig.tickets}/$ticketId/messages').replace(queryParameters: queryParams);

    return _apiClient.get<TicketMessagesResponse>(
      uri.toString(),
      headers: await _getAuthHeaders(),
      fromJson: TicketMessagesResponse.fromJson,
    );
  }

  /// Add message to ticket
  Future<Result<TicketMessage, ApiError>> addTicketMessage(
    String ticketId,
    Map<String, dynamic> messageData,
  ) async {
    // Check authentication
    if (!_authService.isAuthenticated) {
      return Result.error(ApiError.unauthorized());
    }

    final url = '${ApiConfig.tickets}/$ticketId/messages';

    return _apiClient.post<TicketMessage>(
      url,
      headers: await _getAuthHeaders(),
      body: messageData,
      fromJson: TicketMessage.fromJson,
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