import 'package:flutter/foundation.dart';
import '../../models/customer_ticket.dart';
import '../api/api_exceptions.dart';
import '../customer_api_service.dart';

/// Provider for customer tickets state
class CustomerTicketsProvider extends ChangeNotifier {
  final CustomerApiService _apiService;

  List<CustomerTicket> _tickets = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  bool _hasMore = true;
  String? _statusFilter;

  CustomerTicketsProvider({required CustomerApiService apiService})
      : _apiService = apiService;

  /// Get list of tickets
  List<CustomerTicket> get tickets => _tickets;

  /// Check if currently loading
  bool get isLoading => _isLoading;

  /// Get current error message
  String? get error => _error;

  /// Check if more tickets available
  bool get hasMore => _hasMore;

  /// Get current status filter
  String? get statusFilter => _statusFilter;

  /// Load tickets with optional status filter
  Future<void> loadTickets({String? status, bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _tickets = [];
      _hasMore = true;
    }

    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    _statusFilter = status;
    notifyListeners();

    try {
      final result = await _apiService.getTickets(
        status: status,
        page: _currentPage,
        limit: 20,
      );

      if (result.isSuccess) {
        if (refresh) {
          _tickets = result.value.tickets;
        } else {
          _tickets.addAll(result.value.tickets);
        }

        _hasMore = result.value.pagination.hasNext;
        _currentPage = result.value.pagination.page + 1;
        _error = null;
      } else {
        _error = _getErrorMessage(result.error);
      }
    } catch (e) {
      _error = 'Failed to load tickets: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh tickets (reload from page 1)
  Future<void> refreshTickets() async {
    await loadTickets(status: _statusFilter, refresh: true);
  }

  /// Create new ticket
  Future<bool> createTicket({
    required String subject,
    required String description,
    String priority = 'NORMAL',
    String? category,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = CreateTicketRequest(
        subject: subject,
        description: description,
        priority: priority,
        category: category,
      );

      final result = await _apiService.createTicket(request);

      if (result.isSuccess) {
        // Add new ticket to beginning of list
        _tickets.insert(0, result.value);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = _getErrorMessage(result.error);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to create ticket: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update ticket
  Future<bool> updateTicket({
    required String ticketId,
    String? subject,
    String? description,
    String? priority,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final request = UpdateTicketRequest(
        subject: subject,
        description: description,
        priority: priority,
      );

      final result = await _apiService.updateTicket(ticketId, request);

      if (result.isSuccess) {
        // Update ticket in list
        final index = _tickets.indexWhere((t) => t.id == ticketId);
        if (index != -1) {
          _tickets[index] = result.value;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = _getErrorMessage(result.error);
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to update ticket: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Get ticket detail by ID
  Future<TicketDetail?> getTicketDetail(String ticketId) async {
    try {
      final result = await _apiService.getTicketDetail(ticketId);

      if (result.isSuccess) {
        return result.value;
      } else {
        _error = _getErrorMessage(result.error);
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Failed to load ticket detail: $e';
      notifyListeners();
      return null;
    }
  }

  /// Add message to ticket
  Future<bool> addMessage({
    required String ticketId,
    required String content,
  }) async {
    try {
      final request = MessageRequest(content: content);
      final result = await _apiService.addMessage(ticketId, request);

      if (result.isSuccess) {
        // Update ticket's message count in list
        final index = _tickets.indexWhere((t) => t.id == ticketId);
        if (index != -1) {
          final ticket = _tickets[index];
          _tickets[index] = CustomerTicket(
            id: ticket.id,
            number: ticket.number,
            subject: ticket.subject,
            description: ticket.description,
            status: ticket.status,
            priority: ticket.priority,
            category: ticket.category,
            customerId: ticket.customerId,
            assignedToId: ticket.assignedToId,
            messageCount: ticket.messageCount + 1,
            createdAt: ticket.createdAt,
            updatedAt: DateTime.now(),
          );
        }
        notifyListeners();
        return true;
      } else {
        _error = _getErrorMessage(result.error);
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get user-friendly error message
  String _getErrorMessage(ApiError error) {
    if (error is HttpError) {
      switch (error.statusCode) {
        case 400:
          return 'Invalid request. Please check your input.';
        case 403:
          return 'You do not have permission to perform this action.';
        case 404:
          return 'Ticket not found.';
        default:
          return error.message;
      }
    } else if (error is NetworkError) {
      return 'Network error. Please check your connection.';
    } else if (error is TimeoutError) {
      return 'Request timeout. Please try again.';
    }
    return error.message;
  }
}
