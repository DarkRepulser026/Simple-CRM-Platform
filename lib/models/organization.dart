class Organization {
  final String id;
  final String name;
  final String? domain;
  final String? logo;
  final String? website;
  final String? industry;
  final String? description;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? role;

  const Organization({
    required this.id,
    required this.name,
    this.domain,
    this.logo,
    this.website,
    this.industry,
    this.description,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
    this.role,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      domain: json['domain'] as String?,
      logo: json['logo'] as String?,
      website: json['website'] as String?,
      industry: json['industry'] as String?,
      description: json['description'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : DateTime.now(),
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (domain != null) 'domain': domain,
      if (logo != null) 'logo': logo,
      if (website != null) 'website': website,
      if (industry != null) 'industry': industry,
      if (description != null) 'description': description,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (role != null) 'role': role,
    };
  }

  @override
  String toString() {
    return 'Organization(id: $id, name: $name, domain: $domain, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Organization &&
      other.id == id &&
      other.name == name &&
      other.domain == domain &&
      other.logo == logo &&
      other.website == website &&
      other.industry == industry &&
      other.description == description &&
      other.isActive == isActive &&
      other.createdAt == createdAt &&
      other.updatedAt == updatedAt &&
      other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ domain.hashCode ^ logo.hashCode ^ website.hashCode ^ industry.hashCode ^ description.hashCode ^ isActive.hashCode ^ (createdAt?.hashCode ?? 0) ^ (updatedAt?.hashCode ?? 0) ^ role.hashCode;
  }
}