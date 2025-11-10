/// Message type enumeration for ticket messages
enum MessageType {
  customer('Customer'),
  agent('Agent'),
  system('System'),
  internal('Internal Note');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String value) {
    return MessageType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => MessageType.customer,
    );
  }
}

/// TicketMessage model representing individual messages in a ticket conversation
class TicketMessage {
  final String id;
  final String ticketId;
  final String content;
  final MessageType messageType;
  final String? senderId;
  final String? senderName;
  final String? senderEmail;
  final bool isInternal; // Internal notes not visible to customer
  final List<String>? attachments; // File URLs or paths
  final String organizationId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TicketMessage({
    required this.id,
    required this.ticketId,
    required this.content,
    required this.messageType,
    this.senderId,
    this.senderName,
    this.senderEmail,
    this.isInternal = false,
    this.attachments,
    required this.organizationId,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Computed property to check if message is from customer
  bool get isFromCustomer => messageType == MessageType.customer;

  /// Computed property to check if message is from agent
  bool get isFromAgent => messageType == MessageType.agent;

  /// Computed property to check if message is visible to customer
  bool get isVisibleToCustomer => !isInternal && messageType != MessageType.internal;

  /// Factory constructor to create TicketMessage from JSON
  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] ?? '',
      ticketId: json['ticketId'] ?? '',
      content: json['content'] ?? '',
      messageType: MessageType.fromString(json['messageType'] ?? 'Customer'),
      senderId: json['senderId'],
      senderName: json['senderName'],
      senderEmail: json['senderEmail'],
      isInternal: json['isInternal'] ?? false,
      attachments: json['attachments'] != null
          ? List<String>.from(json['attachments'])
          : null,
      organizationId: json['organizationId'] ?? '',
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert TicketMessage to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ticketId': ticketId,
      'content': content,
      'messageType': messageType.value,
      'senderId': senderId,
      'senderName': senderName,
      'senderEmail': senderEmail,
      'isInternal': isInternal,
      'attachments': attachments,
      'organizationId': organizationId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of TicketMessage with modified fields
  TicketMessage copyWith({
    String? id,
    String? ticketId,
    String? content,
    MessageType? messageType,
    String? senderId,
    String? senderName,
    String? senderEmail,
    bool? isInternal,
    List<String>? attachments,
    String? organizationId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TicketMessage(
      id: id ?? this.id,
      ticketId: ticketId ?? this.ticketId,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderEmail: senderEmail ?? this.senderEmail,
      isInternal: isInternal ?? this.isInternal,
      attachments: attachments ?? this.attachments,
      organizationId: organizationId ?? this.organizationId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TicketMessage && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TicketMessage(id: $id, ticketId: $ticketId, type: ${messageType.value}, sender: $senderName)';
  }
}