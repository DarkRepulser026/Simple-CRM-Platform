/// Activity type enumeration
enum ActivityType {
  // User activities
  login('Login'),
  logout('Logout'),
  passwordChange('Password Change'),

  // Contact activities
  contactCreated('Contact Created'),
  contactUpdated('Contact Updated'),
  contactDeleted('Contact Deleted'),

  // Lead activities
  leadCreated('Lead Created'),
  leadUpdated('Lead Updated'),
  leadDeleted('Lead Deleted'),
  leadConverted('Lead Converted'),

  // Ticket activities
  ticketCreated('Ticket Created'),
  ticketUpdated('Ticket Updated'),
  ticketDeleted('Ticket Deleted'),
  ticketAssigned('Ticket Assigned'),
  ticketResolved('Ticket Resolved'),
  ticketClosed('Ticket Closed'),
  ticketReopened('Ticket Reopened'),

  // Task activities
  taskCreated('Task Created'),
  taskUpdated('Task Updated'),
  taskDeleted('Task Deleted'),
  taskAssigned('Task Assigned'),
  taskCompleted('Task Completed'),

  // System activities
  userCreated('User Created'),
  userUpdated('User Updated'),
  userDeleted('User Deleted'),
  roleCreated('Role Created'),
  roleUpdated('Role Updated'),
  roleDeleted('Role Deleted'),
  organizationUpdated('Organization Updated'),

  // Other activities
  fileUploaded('File Uploaded'),
  fileDownloaded('File Downloaded'),
  emailSent('Email Sent'),
  noteAdded('Note Added'),
  other('Other');

  const ActivityType(this.value);
  final String value;

  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ActivityType.other,
    );
  }
}

/// ActivityLog model for tracking system activities and audit trail
class ActivityLog {
  final String id;
  final ActivityType activityType;
  final String? action; // raw action string returned by backend (e.g., INVITE_ACCEPTED)
  final String description;
  final String? userId; // User who performed the activity
  final String? userName; // Cached user name for display
  final String? entityId; // ID of the entity being acted upon (contact, lead, etc.)
  final String? entityType; // Type of entity (Contact, Lead, Ticket, etc.)
  final String? entityName; // Cached entity name for display
  final String organizationId;
  final Map<String, dynamic>? oldValues; // Previous values for updates
  final Map<String, dynamic>? newValues; // New values for updates/creates
  final String? ipAddress;
  final String? userAgent;
  final Map<String, dynamic>? metadata; // Additional context data
  final DateTime createdAt;

  const ActivityLog({
    required this.id,
    required this.activityType,
    required this.description,
    this.action,
    this.userId,
    this.userName,
    this.entityId,
    this.entityType,
    this.entityName,
    required this.organizationId,
    this.oldValues,
    this.newValues,
    this.ipAddress,
    this.userAgent,
    this.metadata,
    required this.createdAt,
  });

  /// Computed property to check if this is a system activity (no user)
  bool get isSystemActivity => userId == null;

  /// Computed property to check if this activity involves an entity
  bool get hasEntity => entityId != null && entityType != null;

  /// Computed property to check if this is an update activity
  bool get isUpdate => oldValues != null && newValues != null;

  /// Computed property to get activity summary for display
  String get summary {
    if (userName != null) {
      return '$userName ${activityType.value.toLowerCase()}';
    } else {
      return 'System ${activityType.value.toLowerCase()}';
    }
  }

  /// Factory constructor to create ActivityLog from JSON
  factory ActivityLog.fromJson(Map<String, dynamic> json) {
    final activityTypeStr = json['activityType'] ?? json['action'] ?? 'Other';
    return ActivityLog(
      id: json['id'] ?? '',
      activityType: ActivityType.fromString(activityTypeStr),
      action: (json['action'] as String?) ?? (json['activityType'] as String?),
      description: json['description'] ?? '',
      userId: json['userId'],
      userName: json['userName'] ?? (json['user'] != null ? (json['user']['name'] ?? json['user']['email']) : null),
      entityId: json['entityId'],
      entityType: json['entityType'],
      entityName: json['entityName'],
      organizationId: json['organizationId'] ?? '',
      oldValues: json['oldValues'] ?? (json['metadata'] != null && (json['metadata'] as Map<String, dynamic>).containsKey('oldValues') ? (json['metadata'] as Map<String, dynamic>)['oldValues'] : null),
      newValues: json['newValues'] ?? (json['metadata'] != null && (json['metadata'] as Map<String, dynamic>).containsKey('newValues') ? (json['metadata'] as Map<String, dynamic>)['newValues'] : null),
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  /// Convert ActivityLog to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'activityType': activityType.value,
      'action': action,
      'description': description,
      'userId': userId,
      'userName': userName,
      'entityId': entityId,
      'entityType': entityType,
      'entityName': entityName,
      'organizationId': organizationId,
      'oldValues': oldValues,
      'newValues': newValues,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Create a copy of ActivityLog with modified fields
  ActivityLog copyWith({
    String? id,
    ActivityType? activityType,
    String? action,
    String? description,
    String? userId,
    String? userName,
    String? entityId,
    String? entityType,
    String? entityName,
    String? organizationId,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    String? ipAddress,
    String? userAgent,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      activityType: activityType ?? this.activityType,
      action: action ?? this.action,
      description: description ?? this.description,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      entityName: entityName ?? this.entityName,
      organizationId: organizationId ?? this.organizationId,
      oldValues: oldValues ?? this.oldValues,
      newValues: newValues ?? this.newValues,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ActivityLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'ActivityLog(id: $id, type: ${activityType.value}, user: $userName, entity: $entityType:$entityId)';
  }
}