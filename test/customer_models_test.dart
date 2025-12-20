import 'package:flutter_test/flutter_test.dart';

import 'package:main_project/models/customer_auth.dart';
import 'package:main_project/models/customer_ticket.dart';
import 'package:main_project/models/customer_profile.dart';
import 'package:main_project/models/pagination.dart';

void main() {
  group('CustomerAuth Model Tests', () {
    test('RegisterRequest should serialize to JSON correctly', () {
      final request = RegisterRequest(
        email: 'test@example.com',
        password: 'Test123!@#',
        name: 'Test User',
        companyName: 'Test Company',
        phone: '+1234567890',
      );

      final json = request.toJson();

      expect(json['email'], 'test@example.com');
      expect(json['password'], 'Test123!@#');
      expect(json['name'], 'Test User');
      expect(json['companyName'], 'Test Company');
      expect(json['phone'], '+1234567890');
    });

    test('LoginRequest should serialize to JSON correctly', () {
      final request = LoginRequest(
        email: 'test@example.com',
        password: 'Test123!@#',
      );

      final json = request.toJson();

      expect(json['email'], 'test@example.com');
      expect(json['password'], 'Test123!@#');
    });

    test('AuthResponse should deserialize from JSON correctly', () {
      final json = {
        'userId': 'user-123',
        'token': 'access-token',
        'refreshToken': 'refresh-token',
        'user': {
          'id': 'user-123',
          'email': 'test@example.com',
          'name': 'Test User',
        }
      };

      final response = AuthResponse.fromJson(json);

      expect(response.userId, 'user-123');
      expect(response.token, 'access-token');
      expect(response.refreshToken, 'refresh-token');
      expect(response.user.email, 'test@example.com');
    });

    test('CustomerUser should deserialize correctly', () {
      final json = {
        'id': 'user-123',
        'email': 'test@example.com',
        'name': 'Test User',
      };

      final user = CustomerUser.fromJson(json);

      expect(user.id, 'user-123');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
    });

    test('RefreshTokenRequest should serialize correctly', () {
      final request = RefreshTokenRequest(refreshToken: 'refresh-token-abc');

      final json = request.toJson();

      expect(json['refreshToken'], 'refresh-token-abc');
    });

    test('RefreshTokenResponse should deserialize correctly', () {
      final json = {'token': 'new-access-token'};

      final response = RefreshTokenResponse.fromJson(json);

      expect(response.token, 'new-access-token');
    });

    test('VerifyTokenResponse should deserialize with valid token', () {
      final json = {
        'isValid': true,
        'user': {
          'id': 'user-123',
          'email': 'test@example.com',
          'name': 'Test User',
        }
      };

      final response = VerifyTokenResponse.fromJson(json);

      expect(response.isValid, true);
      expect(response.user, isNotNull);
      expect(response.user!.email, 'test@example.com');
    });

    test('VerifyTokenResponse should deserialize with invalid token', () {
      final json = {'isValid': false};

      final response = VerifyTokenResponse.fromJson(json);

      expect(response.isValid, false);
      expect(response.user, isNull);
    });
  });

  group('CustomerTicket Model Tests', () {
    test('CustomerTicket should deserialize from JSON', () {
      final json = {
        'id': 'ticket-123',
        'number': 'TKT-001',
        'subject': 'Test Ticket',
        'description': 'This is a test ticket',
        'status': 'OPEN',
        'priority': 'NORMAL',
        'customerId': 'user-123',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final ticket = CustomerTicket.fromJson(json);

      expect(ticket.id, 'ticket-123');
      expect(ticket.number, 'TKT-001');
      expect(ticket.subject, 'Test Ticket');
      expect(ticket.status, 'OPEN');
      expect(ticket.priority, 'NORMAL');
    });

    test('CreateTicketRequest should serialize correctly', () {
      final request = CreateTicketRequest(
        subject: 'New Issue',
        description: 'Detailed description',
        priority: 'HIGH',
        category: 'TECHNICAL',
      );

      final json = request.toJson();

      expect(json['subject'], 'New Issue');
      expect(json['description'], 'Detailed description');
      expect(json['priority'], 'HIGH');
      expect(json['category'], 'TECHNICAL');
    });

    test('UpdateTicketRequest should serialize with partial data', () {
      final request = UpdateTicketRequest(
        subject: 'Updated Subject',
        priority: 'URGENT',
      );

      final json = request.toJson();

      expect(json['subject'], 'Updated Subject');
      expect(json['priority'], 'URGENT');
      expect(json.containsKey('description'), false);
    });

    test('TicketDetail should deserialize with messages', () {
      final json = {
        'id': 'ticket-123',
        'number': 'TKT-001',
        'subject': 'Test',
        'description': 'Test desc',
        'status': 'OPEN',
        'priority': 'NORMAL',
        'customerId': 'user-123',
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
        'messages': [
          {
            'id': 'msg-1',
            'content': 'Test message',
            'ticketId': 'ticket-123',
            'isFromCustomer': true,
            'isInternal': false,
            'createdAt': '2024-01-01T00:00:00.000Z',
          }
        ],
      };

      final detail = TicketDetail.fromJson(json);

      expect(detail.id, 'ticket-123');
      expect(detail.messages.length, 1);
      expect(detail.messages.first.content, 'Test message');
      expect(detail.messages.first.isFromCustomer, true);
    });

    test('MessageRequest should serialize correctly', () {
      final request = MessageRequest(content: 'This is my message');

      final json = request.toJson();

      expect(json['content'], 'This is my message');
    });

    test('PaginatedTickets should deserialize correctly', () {
      final json = {
        'tickets': [
          {
            'id': 'ticket-1',
            'number': 'TKT-001',
            'subject': 'Ticket 1',
            'description': 'Desc 1',
            'status': 'OPEN',
            'priority': 'NORMAL',
            'customerId': 'user-123',
            'createdAt': '2024-01-01T00:00:00.000Z',
            'updatedAt': '2024-01-01T00:00:00.000Z',
          },
        ],
        'pagination': {
          'page': 1,
          'limit': 10,
          'totalPages': 1,
          'totalItems': 1,
          'hasNext': false,
        }
      };

      final paginated = PaginatedTickets.fromJson(json);

      expect(paginated.tickets.length, 1);
      expect(paginated.pagination.page, 1);
      expect(paginated.pagination.hasNext, false);
    });
  });

  group('CustomerProfile Model Tests', () {
    test('CustomerProfile should deserialize from JSON', () {
      final json = {
        'id': 'profile-123',
        'userId': 'user-123',
        'email': 'customer@example.com',
        'name': 'John Doe',
        'companyName': 'Acme Corp',
        'phone': '+1234567890',
        'address': '123 Main St',
        'city': 'New York',
        'state': 'NY',
        'postalCode': '10001',
        'country': 'USA',
        'isActive': true,
        'createdAt': '2024-01-01T00:00:00.000Z',
        'updatedAt': '2024-01-01T00:00:00.000Z',
      };

      final profile = CustomerProfile.fromJson(json);

      expect(profile.id, 'profile-123');
      expect(profile.email, 'customer@example.com');
      expect(profile.name, 'John Doe');
      expect(profile.companyName, 'Acme Corp');
      expect(profile.phone, '+1234567890');
      expect(profile.isActive, true);
    });

    test('UpdateProfileRequest should serialize with all fields', () {
      final request = UpdateProfileRequest(
        name: 'Jane Smith',
        companyName: 'New Company',
        phone: '+9876543210',
        address: '456 Oak Ave',
        city: 'Los Angeles',
        state: 'CA',
        postalCode: '90001',
        country: 'USA',
      );

      final json = request.toJson();

      expect(json['name'], 'Jane Smith');
      expect(json['companyName'], 'New Company');
      expect(json['phone'], '+9876543210');
      expect(json['address'], '456 Oak Ave');
      expect(json['city'], 'Los Angeles');
      expect(json['state'], 'CA');
      expect(json['postalCode'], '90001');
      expect(json['country'], 'USA');
    });

    test('UpdateProfileRequest should serialize with partial fields', () {
      final request = UpdateProfileRequest(
        name: 'Updated Name',
        phone: '+1111111111',
      );

      final json = request.toJson();

      expect(json['name'], 'Updated Name');
      expect(json['phone'], '+1111111111');
      expect(json.containsKey('address'), false);
    });

    test('ChangePasswordRequest should serialize correctly', () {
      final request = ChangePasswordRequest(
        currentPassword: 'OldPassword123',
        newPassword: 'NewPassword456',
      );

      final json = request.toJson();

      expect(json['currentPassword'], 'OldPassword123');
      expect(json['newPassword'], 'NewPassword456');
    });

    test('TicketsSummary should deserialize correctly', () {
      final json = {
        'openCount': 3,
        'resolvedCount': 6,
        'totalCount': 15,
        'avgResponseTime': 24.5,
      };

      final summary = TicketsSummary.fromJson(json);

      expect(summary.openCount, 3);
      expect(summary.resolvedCount, 6);
      expect(summary.totalCount, 15);
      expect(summary.avgResponseTime, 24.5);
    });
  });

  group('Pagination Model Tests', () {
    test('Pagination should deserialize from JSON', () {
      final json = {
        'page': 2,
        'limit': 20,
        'totalPages': 5,
        'total': 95,
        'hasNext': true,
        'hasPrev': true,
      };

      final pagination = Pagination.fromJson(json);

      expect(pagination.page, 2);
      expect(pagination.limit, 20);
      expect(pagination.totalPages, 5);
      expect(pagination.total, 95);
      expect(pagination.hasNext, true);
      expect(pagination.hasPrev, true);
    });

    test('Pagination hasNext should be false on last page', () {
      final json = {
        'page': 5,
        'limit': 20,
        'totalPages': 5,
        'total': 95,
        'hasNext': false,
        'hasPrev': true,
      };

      final pagination = Pagination.fromJson(json);

      expect(pagination.page, pagination.totalPages);
      expect(pagination.hasNext, false);
    });
  });
}
