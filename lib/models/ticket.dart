/// Ticket status enumeration
enum TicketStatus {
  open('Open'),
  pending('Pending'),
  inProgress('In Progress'),
  resolved('Resolved'),
  closed('Closed'),
  cancelled('Cancelled');

  const TicketStatus(this.value);
  final String value;

  static TicketStatus fromString(String value) {
    return TicketStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => TicketStatus.open,
    );
  }
}

/// Ticket priority enumeration
enum TicketPriority {
  low('Low'),
  normal('Normal'),
  high('High'),
  urgent('Urgent'),
  critical('Critical');

  const TicketPriority(this.value);
  final String value;

  static TicketPriority fromString(String value) {
    return TicketPriority.values.firstWhere(
      (priority) => priority.value == value,
      orElse: () => TicketPriority.normal,
    );
  }
}

/// Ticket type enumeration
enum TicketType {
  question('Question'),
  incident('Incident'),
  problem('Problem'),
  featureRequest('Feature Request'),
  complaint('Complaint'),
  refund('Refund'),
  technicalSupport('Technical Support'),
  billing('Billing'),
  other('Other');

  const TicketType(this.value);
  final String value;

  static TicketType fromString(String value) {
    return TicketType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => TicketType.question,
    );
  }
}

/// Ticket model representing a customer support ticket
class Ticket {
  final String id;
  final String subject;
  final String? description;
  final TicketStatus status;
  final TicketPriority priority;
  final TicketType type;
  final String? customerId;
  final String? contactId;
  final String? accountId;
  final String? assignedToId;
  final String? createdById;
  final String organizationId;
  final DateTime? dueDate;
  final DateTime? resolvedAt;
  final DateTime? closedAt;
  final int? satisfactionRating; // 1-5 scale
  final String? satisfactionFeedback;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ticket({
    required this.id,
    required this.subject,
    this.description,
    required this.status,
    required this.priority,
    required this.type,
    this.customerId,
    this.contactId,
    this.accountId,
    this.assignedToId,
    this.createdById,
    required this.organizationId,
    this.dueDate,
    this.resolvedAt,
    this.closedAt,
    this.satisfactionRating,
    this.satisfactionFeedback,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Computed property to check if ticket is overdue
  bool get isOverdue =>
      dueDate != null &&
      dueDate!.isBefore(DateTime.now()) &&
      status != TicketStatus.resolved &&
      status != TicketStatus.closed;

  /// Computed property to check if ticket is resolved
  bool get isResolved =>
      status == TicketStatus.resolved || status == TicketStatus.closed;

  /// Computed property to get resolution time in hours
  Duration? get resolutionTime {
    if (resolvedAt == null) return null;
    return resolvedAt!.difference(createdAt);
  }

  /// Computed property to get age in days
  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  /// Factory constructor to create Ticket from JSON
  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'],
      status: TicketStatus.fromString(json['status'] ?? 'Open'),
      priority: TicketPriority.fromString(json['priority'] ?? 'Normal'),
      type: TicketType.fromString(json['type'] ?? 'Question'),
      customerId: json['customerId'],
      contactId: json['contactId'],
      accountId: json['accountId'],
      assignedToId: json['assignedToId'],
      createdById: json['createdById'],
      organizationId: json['organizationId'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : null,
      resolvedAt: json['resolvedAt'] != null ? DateTime.parse(json['resolvedAt']) : null,
      closedAt: json['closedAt'] != null ? DateTime.parse(json['closedAt']) : null,
      satisfactionRating: json['satisfactionRating'],
      satisfactionFeedback: json['satisfactionFeedback'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert Ticket to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'description': description,
      'status': status.value,
      'priority': priority.value,
      'type': type.value,
      'customerId': customerId,
      'contactId': contactId,
      'accountId': accountId,
      'assignedToId': assignedToId,
      'createdById': createdById,
      'organizationId': organizationId,
      'dueDate': dueDate?.toIso8601String(),
      'resolvedAt': resolvedAt?.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'satisfactionRating': satisfactionRating,
      'satisfactionFeedback': satisfactionFeedback,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Ticket with modified fields
  Ticket copyWith({
    String? id,
    String? subject,
    String? description,
    TicketStatus? status,
    TicketPriority? priority,
    TicketType? type,
    String? customerId,
    String? contactId,
    String? accountId,
    String? assignedToId,
    String? createdById,
    String? organizationId,
    DateTime? dueDate,
    DateTime? resolvedAt,
    DateTime? closedAt,
    int? satisfactionRating,
    String? satisfactionFeedback,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      type: type ?? this.type,
      customerId: customerId ?? this.customerId,
      contactId: contactId ?? this.contactId,
      accountId: accountId ?? this.accountId,
      assignedToId: assignedToId ?? this.assignedToId,
      createdById: createdById ?? this.createdById,
      organizationId: organizationId ?? this.organizationId,
      dueDate: dueDate ?? this.dueDate,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      closedAt: closedAt ?? this.closedAt,
      satisfactionRating: satisfactionRating ?? this.satisfactionRating,
      satisfactionFeedback: satisfactionFeedback ?? this.satisfactionFeedback,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Ticket && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Ticket(id: $id, subject: $subject, status: ${status.value}, priority: ${priority.value})';
  }
}