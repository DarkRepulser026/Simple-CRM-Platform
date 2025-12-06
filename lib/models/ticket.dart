/// Ticket status enumeration
enum TicketStatus {
  open('Open'),
  inProgress('In Progress'),
  resolved('Resolved'),
  closed('Closed');

  const TicketStatus(this.value);
  final String value;

  static TicketStatus fromString(String value) {
    return TicketStatus.values.firstWhere(
      (status) => status.name == value.toLowerCase(),
      orElse: () => TicketStatus.open,
    );
  }
}

/// Ticket priority enumeration
enum TicketPriority {
  low('Low'),
  normal('Normal'),
  high('High'),
  urgent('Urgent');

  const TicketPriority(this.value);
  final String value;

  static TicketPriority fromString(String value) {
    return TicketPriority.values.firstWhere(
      (priority) => priority.name == value.toLowerCase(),
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
  final String? category;
  final String? ownerId;
  final String? ownerName;
  final String? ownerEmail;
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ticket({
    required this.id,
    required this.subject,
    this.description,
    required this.status,
    required this.priority,
    this.category,
    this.ownerId,
    this.ownerName,
    this.ownerEmail,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Computed property to get age in days
  int get ageInDays => DateTime.now().difference(createdAt).inDays;

  /// Factory constructor to create Ticket from JSON
  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] ?? '',
      subject: json['subject'] ?? '',
      description: json['description'],
      status: TicketStatus.fromString(json['status'] ?? 'OPEN'),
      priority: TicketPriority.fromString(json['priority'] ?? 'NORMAL'),
      category: json['category'],
      ownerId: json['ownerId'],
      ownerName: json['owner'] != null ? json['owner']['name'] : null,
      ownerEmail: json['owner'] != null ? json['owner']['email'] : null,
      organizationId: json['organizationId'] ?? '',
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
      'category': category,
      'ownerId': ownerId,
      'organizationId': organizationId,
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
    String? category,
    String? ownerId,
    String? ownerName,
    String? ownerEmail,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Ticket(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      organizationId: organizationId ?? this.organizationId,
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
    return 'Ticket(id: $id, subject: $subject, status: ${status.value})';
  }
}