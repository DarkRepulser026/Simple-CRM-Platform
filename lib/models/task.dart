/// Task status enumeration
enum TaskStatus {
  notStarted('Not Started'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  const TaskStatus(this.value);
  final String value;

  static TaskStatus fromString(String value) {
    return TaskStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TaskStatus.notStarted,
    );
  }

  // Backward compatibility getter
  static TaskStatus get toDo => TaskStatus.notStarted;
}

/// Task priority enumeration
enum TaskPriority {
  high('High'),
  normal('Normal'),
  low('Low');

  const TaskPriority(this.value);
  final String value;

  static TaskPriority fromString(String value) {
    return TaskPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => TaskPriority.normal,
    );
  }
}

/// Task model representing a CRM task
class Task {
  final String id;
  final String subject;
  final String? description;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final String? ownerId;
  final String? createdById;
  final String? accountId;
  final String? contactId;
  final String? leadId;
  final String? opportunityId;
  final String? caseId;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.subject,
    this.description,
    required this.status,
    required this.priority,
    this.dueDate,
    this.ownerId,
    this.createdById,
    this.accountId,
    this.contactId,
    this.leadId,
    this.opportunityId,
    this.caseId,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Backward compatibility getter
  String get title => subject;

  /// Computed property to check if task is overdue
  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != TaskStatus.completed;

  /// Factory constructor to create Task from JSON
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] ?? '',
      subject: json['subject'] ?? json['title'] ?? '',
      description: json['description'],
      status: TaskStatus.fromString(json['status'] ?? 'Not Started'),
      priority: TaskPriority.fromString(json['priority'] ?? 'Normal'),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      ownerId: json['ownerId'],
      createdById: json['createdById'],
      accountId: json['accountId'],
      contactId: json['contactId'],
      leadId: json['leadId'],
      opportunityId: json['opportunityId'],
      caseId: json['caseId'],
      organizationId: json['organizationId'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'description': description,
      'status': status.value,
      'priority': priority.value,
      'dueDate': dueDate?.toIso8601String(),
      'ownerId': ownerId,
      'createdById': createdById,
      'accountId': accountId,
      'contactId': contactId,
      'leadId': leadId,
      'opportunityId': opportunityId,
      'caseId': caseId,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Task with modified fields
  Task copyWith({
    String? id,
    String? subject,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    DateTime? dueDate,
    String? ownerId,
    String? createdById,
    String? accountId,
    String? contactId,
    String? leadId,
    String? opportunityId,
    String? caseId,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      ownerId: ownerId ?? this.ownerId,
      createdById: createdById ?? this.createdById,
      accountId: accountId ?? this.accountId,
      contactId: contactId ?? this.contactId,
      leadId: leadId ?? this.leadId,
      opportunityId: opportunityId ?? this.opportunityId,
      caseId: caseId ?? this.caseId,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Task &&
        other.id == id &&
        other.subject == subject &&
        other.description == description &&
        other.status == status &&
        other.priority == priority &&
        other.dueDate == dueDate &&
        other.ownerId == ownerId &&
        other.createdById == createdById &&
        other.accountId == accountId &&
        other.contactId == contactId &&
        other.leadId == leadId &&
        other.opportunityId == opportunityId &&
        other.caseId == caseId &&
        other.organizationId == organizationId &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        subject.hashCode ^
        description.hashCode ^
        status.hashCode ^
        priority.hashCode ^
        dueDate.hashCode ^
        ownerId.hashCode ^
        createdById.hashCode ^
        accountId.hashCode ^
        contactId.hashCode ^
        leadId.hashCode ^
        opportunityId.hashCode ^
        caseId.hashCode ^
        organizationId.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode;
  }
}