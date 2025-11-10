class Organization {
  final String id;
  final String name;
  final String? role;

  const Organization({
    required this.id,
    required this.name,
    this.role,
  });

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (role != null) 'role': role,
    };
  }

  @override
  String toString() {
    return 'Organization(id: $id, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Organization &&
        other.id == id &&
        other.name == name &&
        other.role == role;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ role.hashCode;
  }
}