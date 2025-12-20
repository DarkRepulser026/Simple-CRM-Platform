import 'pagination.dart';

/// Customer ticket models for API

class CustomerTicket {
  final String id;
  final String number;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String? category;
  final String customerId;
  final String? assignedToId;
  final int messageCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerTicket({
    required this.id,
    required this.number,
    required this.subject,
    required this.description,
    required this.status,
    required this.priority,
    this.category,
    required this.customerId,
    this.assignedToId,
    this.messageCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerTicket.fromJson(Map<String, dynamic> json) {
    return CustomerTicket(
      id: json['id'] as String,
      number: json['number'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      category: json['category'] as String?,
      customerId: json['customerId'] as String,
      assignedToId: json['assignedToId'] as String?,
      messageCount: json['messageCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'number': number,
        'subject': subject,
        'description': description,
        'status': status,
        'priority': priority,
        if (category != null) 'category': category,
        'customerId': customerId,
        if (assignedToId != null) 'assignedToId': assignedToId,
        'messageCount': messageCount,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class PaginatedTickets {
  final List<CustomerTicket> tickets;
  final Pagination pagination;

  const PaginatedTickets({
    required this.tickets,
    required this.pagination,
  });

  factory PaginatedTickets.fromJson(Map<String, dynamic> json) {
    return PaginatedTickets(
      tickets: (json['tickets'] as List<dynamic>)
          .map((e) => CustomerTicket.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class CreateTicketRequest {
  final String subject;
  final String description;
  final String priority;
  final String? category;
  final List<String>? attachmentIds;

  const CreateTicketRequest({
    required this.subject,
    required this.description,
    this.priority = 'NORMAL',
    this.category,
    this.attachmentIds,
  });

  Map<String, dynamic> toJson() => {
        'subject': subject,
        'description': description,
        'priority': priority,
        if (category != null) 'category': category,
        if (attachmentIds != null) 'attachmentIds': attachmentIds,
      };
}

class UpdateTicketRequest {
  final String? subject;
  final String? description;
  final String? priority;

  const UpdateTicketRequest({
    this.subject,
    this.description,
    this.priority,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (subject != null) map['subject'] = subject;
    if (description != null) map['description'] = description;
    if (priority != null) map['priority'] = priority;
    return map;
  }
}

class TicketDetail extends CustomerTicket {
  final List<TicketMessage> messages;
  final List<TicketAttachment> attachments;

  const TicketDetail({
    required super.id,
    required super.number,
    required super.subject,
    required super.description,
    required super.status,
    required super.priority,
    super.category,
    required super.customerId,
    super.assignedToId,
    super.messageCount,
    required super.createdAt,
    required super.updatedAt,
    required this.messages,
    required this.attachments,
  });

  factory TicketDetail.fromJson(Map<String, dynamic> json) {
    return TicketDetail(
      id: json['id'] as String,
      number: json['number'] as String,
      subject: json['subject'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      category: json['category'] as String?,
      customerId: json['customerId'] as String,
      assignedToId: json['assignedToId'] as String?,
      messageCount: json['messageCount'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => TicketAttachment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TicketMessage {
  final String id;
  final String ticketId;
  final String content;
  final String senderId;
  final String senderName;
  final bool isFromCustomer;
  final bool isInternal;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TicketMessage({
    required this.id,
    required this.ticketId,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.isFromCustomer,
    this.isInternal = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as String,
      ticketId: json['ticketId'] as String,
      content: json['content'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      isFromCustomer: json['isFromCustomer'] as bool,
      isInternal: json['isInternal'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticketId': ticketId,
        'content': content,
        'senderId': senderId,
        'senderName': senderName,
        'isFromCustomer': isFromCustomer,
        'isInternal': isInternal,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}

class PaginatedMessages {
  final List<TicketMessage> messages;
  final Pagination pagination;

  const PaginatedMessages({
    required this.messages,
    required this.pagination,
  });

  factory PaginatedMessages.fromJson(Map<String, dynamic> json) {
    return PaginatedMessages(
      messages: (json['messages'] as List<dynamic>)
          .map((e) => TicketMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: Pagination.fromJson(json['pagination'] as Map<String, dynamic>),
    );
  }
}

class MessageRequest {
  final String content;
  final List<String>? attachmentIds;

  const MessageRequest({
    required this.content,
    this.attachmentIds,
  });

  Map<String, dynamic> toJson() => {
        'content': content,
        if (attachmentIds != null) 'attachmentIds': attachmentIds,
      };
}

class UpdateMessageRequest {
  final String content;

  const UpdateMessageRequest({required this.content});

  Map<String, dynamic> toJson() => {
        'content': content,
      };
}

class TicketAttachment {
  final String id;
  final String ticketId;
  final String fileName;
  final String filePath;
  final String mimeType;
  final int fileSize;
  final String uploadedBy;
  final DateTime createdAt;

  const TicketAttachment({
    required this.id,
    required this.ticketId,
    required this.fileName,
    required this.filePath,
    required this.mimeType,
    required this.fileSize,
    required this.uploadedBy,
    required this.createdAt,
  });

  factory TicketAttachment.fromJson(Map<String, dynamic> json) {
    return TicketAttachment(
      id: json['id'] as String,
      ticketId: json['ticketId'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      mimeType: json['mimeType'] as String,
      fileSize: json['fileSize'] as int,
      uploadedBy: json['uploadedBy'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'ticketId': ticketId,
        'fileName': fileName,
        'filePath': filePath,
        'mimeType': mimeType,
        'fileSize': fileSize,
        'uploadedBy': uploadedBy,
        'createdAt': createdAt.toIso8601String(),
      };
}
