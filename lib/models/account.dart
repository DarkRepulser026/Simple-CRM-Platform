/// Account model representing a CRM account/company
class Account {
  final String id;
  final String name;
  final String type;
  final String? website;
  final String? phone;

  const Account({
    required this.id,
    required this.name,
    required this.type,
    this.website,
    this.phone,
  });

  /// Factory constructor to create Account from JSON
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      website: json['website'],
      phone: json['phone'],
    );
  }

  /// Convert Account to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'website': website,
      'phone': phone,
    };
  }

  /// Create a copy of Account with modified fields
  Account copyWith({
    String? id,
    String? name,
    String? type,
    Object? website = Object, // Special sentinel value
    Object? phone = Object, // Special sentinel value
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      website: website == Object ? this.website : website as String?,
      phone: phone == Object ? this.phone : phone as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Account &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.website == website &&
        other.phone == phone;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        type.hashCode ^
        website.hashCode ^
        phone.hashCode;
  }
}