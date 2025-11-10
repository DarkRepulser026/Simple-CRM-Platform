/// Interaction type enumeration
enum InteractionType {
  phoneCall('Phone Call'),
  email('Email'),
  chat('Chat'),
  meeting('Meeting'),
  note('Note'),
  socialMedia('Social Media'),
  website('Website'),
  other('Other');

  const InteractionType(this.value);
  final String value;

  static InteractionType fromString(String value) {
    return InteractionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => InteractionType.note,
    );
  }
}

/// Interaction direction enumeration
enum InteractionDirection {
  inbound('Inbound'),
  outbound('Outbound');

  const InteractionDirection(this.value);
  final String value;

  static InteractionDirection fromString(String value) {
    return InteractionDirection.values.firstWhere(
      (direction) => direction.value == value,
      orElse: () => InteractionDirection.inbound,
    );
  }
}

/// Interaction model representing customer interactions and communications
class Interaction {
  final String id;
  final InteractionType type;
  final InteractionDirection direction;
  final String? subject;
  final String? description;
  final String? contactId;
  final String? accountId;
  final String? leadId;
  final String? ticketId;
  final String? userId; // Agent who handled the interaction
  final String organizationId;
  final DateTime? startTime;
  final DateTime? endTime;
  final Duration? duration;
  final String? outcome; // Result of the interaction
  final int? satisfactionRating; // 1-5 scale if applicable
  final List<String>? tags; // Categorization tags
  final Map<String, dynamic>? metadata; // Additional custom data
  final DateTime createdAt;
  final DateTime updatedAt;

  const Interaction({
    required this.id,
    required this.type,
    required this.direction,
    this.subject,
    this.description,
    this.contactId,
    this.accountId,
    this.leadId,
    this.ticketId,
    this.userId,
    required this.organizationId,
    this.startTime,
    this.endTime,
    this.duration,
    this.outcome,
    this.satisfactionRating,
    this.tags,
    this.metadata,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Computed property to get duration from start/end times if not provided
  Duration? get calculatedDuration {
    if (duration != null) return duration;
    if (startTime != null && endTime != null) {
      return endTime!.difference(startTime!);
    }
    return null;
  }

  /// Computed property to check if interaction is completed
  bool get isCompleted => endTime != null;

  /// Computed property to get formatted duration
  String? get formattedDuration {
    final dur = calculatedDuration;
    if (dur == null) return null;

    if (dur.inHours > 0) {
      return '${dur.inHours}h ${dur.inMinutes % 60}m';
    } else if (dur.inMinutes > 0) {
      return '${dur.inMinutes}m ${dur.inSeconds % 60}s';
    } else {
      return '${dur.inSeconds}s';
    }
  }

  /// Factory constructor to create Interaction from JSON
  factory Interaction.fromJson(Map<String, dynamic> json) {
    return Interaction(
      id: json['id'] ?? '',
      type: InteractionType.fromString(json['type'] ?? 'Note'),
      direction: InteractionDirection.fromString(json['direction'] ?? 'Inbound'),
      subject: json['subject'],
      description: json['description'],
      contactId: json['contactId'],
      accountId: json['accountId'],
      leadId: json['leadId'],
      ticketId: json['ticketId'],
      userId: json['userId'],
      organizationId: json['organizationId'] ?? '',
      startTime: json['startTime'] != null ? DateTime.parse(json['startTime']) : null,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'])
          : null,
      outcome: json['outcome'],
      satisfactionRating: json['satisfactionRating'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
      metadata: json['metadata'],
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert Interaction to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'direction': direction.value,
      'subject': subject,
      'description': description,
      'contactId': contactId,
      'accountId': accountId,
      'leadId': leadId,
      'ticketId': ticketId,
      'userId': userId,
      'organizationId': organizationId,
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'duration': duration?.inSeconds,
      'outcome': outcome,
      'satisfactionRating': satisfactionRating,
      'tags': tags,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of Interaction with modified fields
  Interaction copyWith({
    String? id,
    InteractionType? type,
    InteractionDirection? direction,
    String? subject,
    String? description,
    String? contactId,
    String? accountId,
    String? leadId,
    String? ticketId,
    String? userId,
    String? organizationId,
    DateTime? startTime,
    DateTime? endTime,
    Duration? duration,
    String? outcome,
    int? satisfactionRating,
    List<String>? tags,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Interaction(
      id: id ?? this.id,
      type: type ?? this.type,
      direction: direction ?? this.direction,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      contactId: contactId ?? this.contactId,
      accountId: accountId ?? this.accountId,
      leadId: leadId ?? this.leadId,
      ticketId: ticketId ?? this.ticketId,
      userId: userId ?? this.userId,
      organizationId: organizationId ?? this.organizationId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      duration: duration ?? this.duration,
      outcome: outcome ?? this.outcome,
      satisfactionRating: satisfactionRating ?? this.satisfactionRating,
      tags: tags ?? this.tags,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Interaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Interaction(id: $id, type: ${type.value}, direction: ${direction.value}, subject: $subject)';
  }
}