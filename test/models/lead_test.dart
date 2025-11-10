import 'package:flutter_test/flutter_test.dart';
import 'package:main_project/models/lead.dart';

void main() {
  group('Lead Model', () {
    test('should create Lead from JSON', () {
      final json = {
        'id': '123',
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john.doe@example.com',
        'phone': '+1234567890',
        'company': 'ABC Corp',
        'title': 'CEO',
        'status': 'CONTACTED',
        'leadSource': 'WEB',
        'industry': 'Technology',
        'rating': 'Hot',
        'description': 'Potential client',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-02T00:00:00.000Z',
        'ownerId': 'owner123',
        'organizationId': 'org123',
        'isConverted': false,
        'convertedAt': null,
      };

      final lead = Lead.fromJson(json);

      expect(lead.id, '123');
      expect(lead.firstName, 'John');
      expect(lead.lastName, 'Doe');
      expect(lead.email, 'john.doe@example.com');
      expect(lead.phone, '+1234567890');
      expect(lead.company, 'ABC Corp');
      expect(lead.title, 'CEO');
      expect(lead.status, LeadStatus.contacted);
      expect(lead.leadSource, LeadSource.web);
      expect(lead.industry, 'Technology');
      expect(lead.rating, 'Hot');
      expect(lead.description, 'Potential client');
      expect(lead.createdAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
      expect(lead.updatedAt, DateTime.parse('2023-01-02T00:00:00.000Z'));
      expect(lead.ownerId, 'owner123');
      expect(lead.organizationId, 'org123');
      expect(lead.isConverted, false);
      expect(lead.convertedAt, null);
    });

    test('should handle null values in JSON', () {
      final json = {
        'id': '123',
        'firstName': 'John',
        'lastName': 'Doe',
        'status': 'NEW',
        'leadSource': 'PHONE_INQUIRY',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-02T00:00:00.000Z',
        'organizationId': 'org123',
        'isConverted': true,
        'convertedAt': '2023-01-03T00:00:00.000Z',
      };

      final lead = Lead.fromJson(json);

      expect(lead.email, isNull);
      expect(lead.phone, isNull);
      expect(lead.company, isNull);
      expect(lead.title, isNull);
      expect(lead.industry, isNull);
      expect(lead.rating, isNull);
      expect(lead.description, isNull);
      expect(lead.ownerId, isNull);
      expect(lead.isConverted, true);
      expect(lead.convertedAt, DateTime.parse('2023-01-03T00:00:00.000Z'));
    });

    test('should convert Lead to JSON', () {
      final lead = Lead(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phone: '+1234567890',
        company: 'ABC Corp',
        title: 'CEO',
        status: LeadStatus.contacted,
        leadSource: LeadSource.web,
        industry: 'Technology',
        rating: 'Hot',
        description: 'Potential client',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
        ownerId: 'owner123',
        organizationId: 'org123',
        isConverted: false,
        convertedAt: null,
      );

      final json = lead.toJson();

      expect(json['id'], '123');
      expect(json['firstName'], 'John');
      expect(json['lastName'], 'Doe');
      expect(json['email'], 'john.doe@example.com');
      expect(json['phone'], '+1234567890');
      expect(json['company'], 'ABC Corp');
      expect(json['title'], 'CEO');
      expect(json['status'], 'CONTACTED');
      expect(json['leadSource'], 'WEB');
      expect(json['industry'], 'Technology');
      expect(json['rating'], 'Hot');
      expect(json['description'], 'Potential client');
      expect(json['createdAt'], '2023-01-01T00:00:00.000Z');
      expect(json['updatedAt'], '2023-01-02T00:00:00.000Z');
      expect(json['ownerId'], 'owner123');
      expect(json['organizationId'], 'org123');
      expect(json['isConverted'], false);
      expect(json['convertedAt'], null);
    });

    test('should return correct fullName', () {
      final lead = Lead(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        status: LeadStatus.newLead,
        leadSource: LeadSource.web,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        organizationId: 'org123',
        isConverted: false,
      );

      expect(lead.fullName, 'John Doe');
    });

    test('should return correct isOverdue', () {
      final oldDate = DateTime.now().subtract(const Duration(days: 31)); // More than 30 days ago

      final overdueLead = Lead(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        status: LeadStatus.contacted,
        leadSource: LeadSource.web,
        createdAt: oldDate,
        updatedAt: oldDate,
        organizationId: 'org123',
        isConverted: false,
      );

      final convertedLead = Lead(
        id: '456',
        firstName: 'Jane',
        lastName: 'Smith',
        status: LeadStatus.converted,
        leadSource: LeadSource.web,
        createdAt: oldDate,
        updatedAt: oldDate,
        organizationId: 'org123',
        isConverted: true,
      );

      final recentLead = Lead(
        id: '789',
        firstName: 'Bob',
        lastName: 'Johnson',
        status: LeadStatus.newLead,
        leadSource: LeadSource.web,
        createdAt: DateTime.now().subtract(const Duration(days: 10)), // Less than 30 days
        updatedAt: DateTime.now(),
        organizationId: 'org123',
        isConverted: false,
      );

      expect(overdueLead.isOverdue, true);
      expect(convertedLead.isOverdue, false);
      expect(recentLead.isOverdue, false);
    });

    test('should implement equality correctly', () {
      final lead1 = Lead(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        status: LeadStatus.newLead,
        leadSource: LeadSource.web,
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
        organizationId: 'org123',
        isConverted: false,
      );

      final lead2 = Lead(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        status: LeadStatus.newLead,
        leadSource: LeadSource.web,
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
        organizationId: 'org123',
        isConverted: false,
      );

      final lead3 = Lead(
        id: '456',
        firstName: 'John',
        lastName: 'Doe',
        status: LeadStatus.newLead,
        leadSource: LeadSource.web,
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
        organizationId: 'org123',
        isConverted: false,
      );

      expect(lead1 == lead2, true);
      expect(lead1 == lead3, false);
      expect(lead1.hashCode == lead2.hashCode, true);
      expect(lead1.hashCode == lead3.hashCode, false);
    });
  });

  group('LeadStatus Enum', () {
    test('should parse string values correctly', () {
      expect(LeadStatus.fromString('NEW'), LeadStatus.newLead);
      expect(LeadStatus.fromString('CONTACTED'), LeadStatus.contacted);
      expect(LeadStatus.fromString('QUALIFIED'), LeadStatus.qualified);
      expect(LeadStatus.fromString('CONVERTED'), LeadStatus.converted);
      expect(LeadStatus.fromString('INVALID'), LeadStatus.newLead); // default
    });

    test('should return correct string values', () {
      expect(LeadStatus.newLead.value, 'NEW');
      expect(LeadStatus.contacted.value, 'CONTACTED');
      expect(LeadStatus.qualified.value, 'QUALIFIED');
      expect(LeadStatus.converted.value, 'CONVERTED');
    });
  });

  group('LeadSource Enum', () {
    test('should parse string values correctly', () {
      expect(LeadSource.fromString('WEB'), LeadSource.web);
      expect(LeadSource.fromString('PHONE_INQUIRY'), LeadSource.phoneInquiry);
      expect(LeadSource.fromString('TRADE_SHOW'), LeadSource.tradeShow);
      expect(LeadSource.fromString('ADVERTISEMENT'), LeadSource.advertisement);
      expect(LeadSource.fromString('INVALID'), LeadSource.web); // default
    });

    test('should return correct string values', () {
      expect(LeadSource.web.value, 'WEB');
      expect(LeadSource.phoneInquiry.value, 'PHONE_INQUIRY');
      expect(LeadSource.tradeShow.value, 'TRADE_SHOW');
      expect(LeadSource.advertisement.value, 'ADVERTISEMENT');
    });
  });
}