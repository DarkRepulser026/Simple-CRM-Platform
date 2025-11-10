import 'package:flutter_test/flutter_test.dart';
import 'package:main_project/models/task.dart';

void main() {
  group('Task Model', () {
    test('should create Task from JSON', () {
      final json = {
        'id': '123',
        'subject': 'Follow up with client',
        'description': 'Call the client to discuss project requirements',
        'status': 'In Progress',
        'priority': 'High',
        'dueDate': '2023-01-15T00:00:00.000Z',
        'ownerId': 'owner123',
        'createdById': 'creator123',
        'accountId': 'account123',
        'contactId': 'contact123',
        'leadId': 'lead123',
        'opportunityId': 'opp123',
        'caseId': 'case123',
        'organizationId': 'org123',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-02T00:00:00.000Z',
      };

      final task = Task.fromJson(json);

      expect(task.id, '123');
      expect(task.subject, 'Follow up with client');
      expect(task.description, 'Call the client to discuss project requirements');
      expect(task.status, TaskStatus.inProgress);
      expect(task.priority, TaskPriority.high);
      expect(task.dueDate, DateTime.parse('2023-01-15T00:00:00.000Z'));
      expect(task.ownerId, 'owner123');
      expect(task.createdById, 'creator123');
      expect(task.accountId, 'account123');
      expect(task.contactId, 'contact123');
      expect(task.leadId, 'lead123');
      expect(task.opportunityId, 'opp123');
      expect(task.caseId, 'case123');
      expect(task.organizationId, 'org123');
      expect(task.createdAt, DateTime.parse('2023-01-01T00:00:00.000Z'));
      expect(task.updatedAt, DateTime.parse('2023-01-02T00:00:00.000Z'));
    });

    test('should handle null values in JSON', () {
      final json = {
        'id': '123',
        'subject': 'Simple task',
        'status': 'Not Started',
        'priority': 'Normal',
        'organizationId': 'org123',
        'createdAt': '2023-01-01T00:00:00.000Z',
        'updatedAt': '2023-01-02T00:00:00.000Z',
      };

      final task = Task.fromJson(json);

      expect(task.description, isNull);
      expect(task.dueDate, isNull);
      expect(task.ownerId, isNull);
      expect(task.createdById, isNull);
      expect(task.accountId, isNull);
      expect(task.contactId, isNull);
      expect(task.leadId, isNull);
      expect(task.opportunityId, isNull);
      expect(task.caseId, isNull);
    });

    test('should convert Task to JSON', () {
      final task = Task(
        id: '123',
        subject: 'Follow up with client',
        description: 'Call the client to discuss project requirements',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
        dueDate: DateTime.parse('2023-01-15T00:00:00.000Z'),
        ownerId: 'owner123',
        createdById: 'creator123',
        accountId: 'account123',
        contactId: 'contact123',
        leadId: 'lead123',
        opportunityId: 'opp123',
        caseId: 'case123',
        organizationId: 'org123',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
      );

      final json = task.toJson();

      expect(json['id'], '123');
      expect(json['subject'], 'Follow up with client');
      expect(json['description'], 'Call the client to discuss project requirements');
      expect(json['status'], 'In Progress');
      expect(json['priority'], 'High');
      expect(json['dueDate'], '2023-01-15T00:00:00.000Z');
      expect(json['ownerId'], 'owner123');
      expect(json['createdById'], 'creator123');
      expect(json['accountId'], 'account123');
      expect(json['contactId'], 'contact123');
      expect(json['leadId'], 'lead123');
      expect(json['opportunityId'], 'opp123');
      expect(json['caseId'], 'case123');
      expect(json['organizationId'], 'org123');
      expect(json['createdAt'], '2023-01-01T00:00:00.000Z');
      expect(json['updatedAt'], '2023-01-02T00:00:00.000Z');
    });

    test('should return correct title (backward compatibility)', () {
      final task = Task(
        id: '123',
        subject: 'Follow up with client',
        status: TaskStatus.notStarted,
        priority: TaskPriority.normal,
        organizationId: 'org123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(task.title, 'Follow up with client');
    });

    test('should return correct isOverdue', () {
      final pastDate = DateTime.now().subtract(const Duration(days: 1));

      final overdueTask = Task(
        id: '123',
        subject: 'Overdue task',
        status: TaskStatus.inProgress,
        priority: TaskPriority.normal,
        dueDate: pastDate,
        organizationId: 'org123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final completedTask = Task(
        id: '456',
        subject: 'Completed task',
        status: TaskStatus.completed,
        priority: TaskPriority.normal,
        dueDate: pastDate,
        organizationId: 'org123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final futureTask = Task(
        id: '789',
        subject: 'Future task',
        status: TaskStatus.notStarted,
        priority: TaskPriority.normal,
        dueDate: DateTime.now().add(const Duration(days: 1)),
        organizationId: 'org123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(overdueTask.isOverdue, true);
      expect(completedTask.isOverdue, false);
      expect(futureTask.isOverdue, false);
    });

    test('should create copy with modified fields', () {
      final task = Task(
        id: '123',
        subject: 'Original task',
        description: 'Original description',
        status: TaskStatus.notStarted,
        priority: TaskPriority.normal,
        organizationId: 'org123',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updatedTask = task.copyWith(
        subject: 'Updated task',
        status: TaskStatus.inProgress,
        priority: TaskPriority.high,
      );

      expect(updatedTask.subject, 'Updated task');
      expect(updatedTask.status, TaskStatus.inProgress);
      expect(updatedTask.priority, TaskPriority.high);
      expect(updatedTask.description, 'Original description'); // unchanged
      expect(updatedTask.id, '123'); // unchanged
    });

    test('should implement equality correctly', () {
      final task1 = Task(
        id: '123',
        subject: 'Test task',
        status: TaskStatus.notStarted,
        priority: TaskPriority.normal,
        organizationId: 'org123',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
      );

      final task2 = Task(
        id: '123',
        subject: 'Test task',
        status: TaskStatus.notStarted,
        priority: TaskPriority.normal,
        organizationId: 'org123',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
      );

      final task3 = Task(
        id: '456',
        subject: 'Test task',
        status: TaskStatus.notStarted,
        priority: TaskPriority.normal,
        organizationId: 'org123',
        createdAt: DateTime.parse('2023-01-01T00:00:00.000Z'),
        updatedAt: DateTime.parse('2023-01-02T00:00:00.000Z'),
      );

      expect(task1 == task2, true);
      expect(task1 == task3, false);
      expect(task1.hashCode == task2.hashCode, true);
      expect(task1.hashCode == task3.hashCode, false);
    });
  });

  group('TaskStatus Enum', () {
    test('should parse string values correctly', () {
      expect(TaskStatus.fromString('Not Started'), TaskStatus.notStarted);
      expect(TaskStatus.fromString('In Progress'), TaskStatus.inProgress);
      expect(TaskStatus.fromString('Completed'), TaskStatus.completed);
      expect(TaskStatus.fromString('Cancelled'), TaskStatus.cancelled);
      expect(TaskStatus.fromString('INVALID'), TaskStatus.notStarted); // default
    });

    test('should return correct string values', () {
      expect(TaskStatus.notStarted.value, 'Not Started');
      expect(TaskStatus.inProgress.value, 'In Progress');
      expect(TaskStatus.completed.value, 'Completed');
      expect(TaskStatus.cancelled.value, 'Cancelled');
    });

    test('should have backward compatibility getter', () {
      expect(TaskStatus.toDo, TaskStatus.notStarted);
    });
  });

  group('TaskPriority Enum', () {
    test('should parse string values correctly', () {
      expect(TaskPriority.fromString('High'), TaskPriority.high);
      expect(TaskPriority.fromString('Normal'), TaskPriority.normal);
      expect(TaskPriority.fromString('Low'), TaskPriority.low);
      expect(TaskPriority.fromString('INVALID'), TaskPriority.normal); // default
    });

    test('should return correct string values', () {
      expect(TaskPriority.high.value, 'High');
      expect(TaskPriority.normal.value, 'Normal');
      expect(TaskPriority.low.value, 'Low');
    });
  });
}