/// Customer profile models

class CustomerProfile {
  final String id;
  final String userId;
  final String name;
  final String email;
  final String? organizationId;
  final String? organizationName;
  final String? companyName;
  final String? phone;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final bool isActive;
  final DateTime? assignedAt;
  final String? assignedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerProfile({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    this.organizationId,
    this.organizationName,
    this.companyName,
    this.phone,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.isActive = true,
    this.assignedAt,
    this.assignedBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      organizationId: json['organizationId'] as String?,
      organizationName: json['organizationName'] as String?,
      companyName: json['companyName'] as String?,
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'] as String)
          : null,
      assignedBy: json['assignedBy'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'email': email,
        if (organizationId != null) 'organizationId': organizationId,
        if (organizationName != null) 'organizationName': organizationName,
        if (companyName != null) 'companyName': companyName,
        if (phone != null) 'phone': phone,
        if (address != null) 'address': address,
        if (city != null) 'city': city,
        if (state != null) 'state': state,
        if (postalCode != null) 'postalCode': postalCode,
        if (country != null) 'country': country,
        'isActive': isActive,
        if (assignedAt != null) 'assignedAt': assignedAt!.toIso8601String(),
        if (assignedBy != null) 'assignedBy': assignedBy,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  bool get isAssignedToOrganization => organizationId != null;
  String get displayCompany =>
      organizationName ?? companyName ?? 'No Company';
}

class UpdateProfileRequest {
  final String? name;
  final String? phone;
  final String? companyName;
  final String? address;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;

  const UpdateProfileRequest({
    this.name,
    this.phone,
    this.companyName,
    this.address,
    this.city,
    this.state,
    this.postalCode,
    this.country,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (name != null) map['name'] = name;
    if (phone != null) map['phone'] = phone;
    if (companyName != null) map['companyName'] = companyName;
    if (address != null) map['address'] = address;
    if (city != null) map['city'] = city;
    if (state != null) map['state'] = state;
    if (postalCode != null) map['postalCode'] = postalCode;
    if (country != null) map['country'] = country;
    return map;
  }
}

class ChangePasswordRequest {
  final String currentPassword;
  final String newPassword;

  const ChangePasswordRequest({
    required this.currentPassword,
    required this.newPassword,
  });

  Map<String, dynamic> toJson() => {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };
}

class TicketsSummary {
  final int openCount;
  final int resolvedCount;
  final int totalCount;
  final double? avgResponseTime;

  const TicketsSummary({
    required this.openCount,
    required this.resolvedCount,
    required this.totalCount,
    this.avgResponseTime,
  });

  factory TicketsSummary.fromJson(Map<String, dynamic> json) {
    return TicketsSummary(
      openCount: json['openCount'] as int,
      resolvedCount: json['resolvedCount'] as int,
      totalCount: json['totalCount'] as int,
      avgResponseTime: json['avgResponseTime'] as double?,
    );
  }

  Map<String, dynamic> toJson() => {
        'openCount': openCount,
        'resolvedCount': resolvedCount,
        'totalCount': totalCount,
        if (avgResponseTime != null) 'avgResponseTime': avgResponseTime,
      };
}
