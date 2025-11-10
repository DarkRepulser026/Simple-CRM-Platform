import 'package:flutter_test/flutter_test.dart';
import 'package:main_project/models/contact.dart';

void main() {
  group('Contact Model', () {
    test('should create Contact from JSON', () {
      final json = {
        'id': '123',
        'firstName': 'John',
        'lastName': 'Doe',
        'email': 'john.doe@example.com',
        'phone': '+1234567890',
        'title': 'Manager',
        'department': 'Sales',
        'street': '123 Main St',
        'city': 'Anytown',
        'state': 'CA',
        'postalCode': '12345',
        'country': 'USA',
        'organizationId': 'org123',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-02T00:00:00.000Z',
      };

      final contact = Contact.fromJson(json);

      expect(contact.id, '123');
      expect(contact.firstName, 'John');
      expect(contact.lastName, 'Doe');
      expect(contact.email, 'john.doe@example.com');
      expect(contact.phone, '+1234567890');
      expect(contact.title, 'Manager');
      expect(contact.department, 'Sales');
      expect(contact.street, '123 Main St');
      expect(contact.city, 'Anytown');
      expect(contact.state, 'CA');
      expect(contact.postalCode, '12345');
      expect(contact.country, 'USA');
      expect(contact.organizationId, 'org123');
      expect(contact.createdAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
      expect(contact.updatedAt, DateTime.parse('2023-01-02T00:00:00.000Z'));
    });

    test('should handle null values in JSON', () {
      final json = {
        'id': '123',
        'firstName': 'John',
        'lastName': 'Doe',
        'organizationId': 'org123',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-02T00:00:00.000Z',
      };

      final contact = Contact.fromJson(json);

      expect(contact.email, isNull);
      expect(contact.phone, isNull);
      expect(contact.title, isNull);
      expect(contact.department, isNull);
      expect(contact.street, isNull);
      expect(contact.city, isNull);
      expect(contact.state, isNull);
      expect(contact.postalCode, isNull);
      expect(contact.country, isNull);
    });

    test('should convert Contact to JSON', () {
      final contact = Contact(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john.doe@example.com',
        phone: '+1234567890',
        title: 'Manager',
        department: 'Sales',
        street: '123 Main St',
        city: 'Anytown',
        state: 'CA',
        postalCode: '12345',
        country: 'USA',
        organizationId: 'org123',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
      );

      final json = contact.toJson();

      expect(json['id'], '123');
      expect(json['firstName'], 'John');
      expect(json['lastName'], 'Doe');
      expect(json['email'], 'john.doe@example.com');
      expect(json['phone'], '+1234567890');
      expect(json['title'], 'Manager');
      expect(json['department'], 'Sales');
      expect(json['street'], '123 Main St');
      expect(json['city'], 'Anytown');
      expect(json['state'], 'CA');
      expect(json['postalCode'], '12345');
      expect(json['country'], 'USA');
      expect(json['organizationId'], 'org123');
      expect(json['createdAt'], '2023-01-01T00:00:00.000Z');
      expect(json['updatedAt'], '2023-01-02T00:00:00.000Z');
    });

    test('should return correct fullName', () {
      final contact = Contact(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        organizationId: 'org123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(contact.fullName, 'John Doe');
    });

    test('should return correct fullAddress', () {
      final contact = Contact(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        street: '123 Main St',
        city: 'Anytown',
        state: 'CA',
        postalCode: '12345',
        country: 'USA',
        organizationId: 'org123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(contact.fullAddress, '123 Main St, Anytown, CA, 12345, USA');
    });

    test('should return partial address when some fields are null', () {
      final contact = Contact(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        street: '123 Main St',
        city: 'Anytown',
        organizationId: 'org123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(contact.fullAddress, '123 Main St, Anytown');
    });

    test('should return empty string for address when no address fields', () {
      final contact = Contact(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        organizationId: 'org123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(contact.fullAddress, '');
    });

    test('should implement equality correctly', () {
      final contact1 = Contact(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        organizationId: 'org123',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
      );

      final contact2 = Contact(
        id: '123',
        firstName: 'John',
        lastName: 'Doe',
        organizationId: 'org123',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
      );

      final contact3 = Contact(
        id: '456',
        firstName: 'John',
        lastName: 'Doe',
        organizationId: 'org123',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
      );

      expect(contact1 == contact2, true);
      expect(contact1 == contact3, false);
      expect(contact1.hashCode == contact2.hashCode, true);
      expect(contact1.hashCode == contact3.hashCode, false);
    });
  });
}