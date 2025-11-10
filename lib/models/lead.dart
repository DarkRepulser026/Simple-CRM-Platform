/// Lead status enumeration
enum LeadStatus {
  newLead('NEW'),
  pending('PENDING'),
  contacted('CONTACTED'),
  qualified('QUALIFIED'),
  unqualified('UNQUALIFIED'),
  converted('CONVERTED');

  const LeadStatus(this.value);
  final String value;

  static LeadStatus fromString(String value) {
    return LeadStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => LeadStatus.newLead,
    );
  }
}

/// Lead source enumeration
enum LeadSource {
  web('WEB'),
  phoneInquiry('PHONE_INQUIRY'),
  partnerReferral('PARTNER_REFERRAL'),
  coldCall('COLD_CALL'),
  tradeShow('TRADE_SHOW'),
  employeeReferral('EMPLOYEE_REFERRAL'),
  advertisement('ADVERTISEMENT'),
  other('OTHER');

  const LeadSource(this.value);
  final String value;

  static LeadSource fromString(String value) {
    return LeadSource.values.firstWhere(
      (source) => source.value == value,
      orElse: () => LeadSource.web,
    );
  }
}

/// Lead model representing a CRM lead
class Lead {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? company;
  final String? title;
  final LeadStatus status;
  final LeadSource leadSource;
  final String? industry;
  final String? rating;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? ownerId;
  final String organizationId;
  final bool isConverted;
  final DateTime? convertedAt;
  final String? convertedAccountId;
  final String? convertedContactId;
  final String? convertedOpportunityId;
  final String? contactId;

  const Lead({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.company,
    this.title,
    required this.status,
    required this.leadSource,
    this.industry,
    this.rating,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.ownerId,
    required this.organizationId,
    required this.isConverted,
    this.convertedAt,
    this.convertedAccountId,
    this.convertedContactId,
    this.convertedOpportunityId,
    this.contactId,
  });

  /// Computed property for full name
  String get fullName => '$firstName $lastName'.trim();

  /// Check if lead is overdue (example business logic)
  bool get isOverdue {
    if (isConverted) return false;
    final now = DateTime.now();
    final daysSinceCreated = now.difference(createdAt).inDays;
    return daysSinceCreated > 30; // Consider overdue after 30 days
  }

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      company: json['company'] as String?,
      title: json['title'] as String?,
      status: LeadStatus.fromString(json['status'] as String? ?? 'NEW'),
      leadSource: LeadSource.fromString(json['leadSource'] as String? ?? ''),
      industry: json['industry'] as String?,
      rating: json['rating'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      ownerId: json['ownerId'] as String?,
      organizationId: json['organizationId'] as String? ?? '',
      isConverted: json['isConverted'] as bool? ?? false,
      convertedAt: json['convertedAt'] != null ? DateTime.parse(json['convertedAt'] as String) : null,
      convertedAccountId: json['convertedAccountId'] as String?,
      convertedContactId: json['convertedContactId'] as String?,
      convertedOpportunityId: json['convertedOpportunityId'] as String?,
      contactId: json['contactId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (company != null) 'company': company,
      if (title != null) 'title': title,
      'status': status.value,
      'leadSource': leadSource.value,
      if (industry != null) 'industry': industry,
      if (rating != null) 'rating': rating,
      if (description != null) 'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (ownerId != null) 'ownerId': ownerId,
      'organizationId': organizationId,
      'isConverted': isConverted,
      if (convertedAt != null) 'convertedAt': convertedAt!.toIso8601String(),
      if (convertedAccountId != null) 'convertedAccountId': convertedAccountId,
      if (convertedContactId != null) 'convertedContactId': convertedContactId,
      if (convertedOpportunityId != null) 'convertedOpportunityId': convertedOpportunityId,
      if (contactId != null) 'contactId': contactId,
    };
  }

  @override
  String toString() {
    return 'Lead(id: $id, fullName: $fullName, company: $company, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Lead &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.email == email &&
        other.phone == phone &&
        other.company == company &&
        other.title == title &&
        other.status == status &&
        other.leadSource == leadSource &&
        other.industry == industry &&
        other.rating == rating &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.ownerId == ownerId &&
        other.organizationId == organizationId &&
        other.isConverted == isConverted &&
        other.convertedAt == convertedAt &&
        other.convertedAccountId == convertedAccountId &&
        other.convertedContactId == convertedContactId &&
        other.convertedOpportunityId == convertedOpportunityId &&
        other.contactId == contactId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        company.hashCode ^
        title.hashCode ^
        status.hashCode ^
        leadSource.hashCode ^
        industry.hashCode ^
        rating.hashCode ^
        description.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        ownerId.hashCode ^
        organizationId.hashCode ^
        isConverted.hashCode ^
        convertedAt.hashCode ^
        convertedAccountId.hashCode ^
        convertedContactId.hashCode ^
        convertedOpportunityId.hashCode ^
        contactId.hashCode;
  }
}