class Contact {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? title;
  final String? department;
  final String? street;
  final String? city;
  final String? state;
  final String? postalCode;
  final String? country;
  final double? latitude;
  final double? longitude;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? ownerId;
  final String organizationId;

  const Contact({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.title,
    this.department,
    this.street,
    this.city,
    this.state,
    this.postalCode,
    this.country,
    this.latitude,
    this.longitude,
    this.description,
    required this.createdAt,
    required this.updatedAt,
    this.ownerId,
    required this.organizationId,
  });

  /// Computed property for full name
  String get fullName => '$firstName $lastName'.trim();

  /// Computed property for full address
  String get fullAddress {
    final parts = [
      street,
      city,
      state,
      postalCode,
      country,
    ].where((part) => part != null && part.isNotEmpty).toList();
    return parts.join(', ');
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      title: json['title'] as String?,
      department: json['department'] as String?,
      street: json['street'] as String?,
      city: json['city'] as String?,
      state: json['state'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String?,
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      description: json['description'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] as String? ?? DateTime.now().toIso8601String()),
      ownerId: json['ownerId'] as String?,
      organizationId: json['organizationId'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'firstName': firstName,
      'lastName': lastName,
      if (email != null) 'email': email,
      if (phone != null) 'phone': phone,
      if (title != null) 'title': title,
      if (department != null) 'department': department,
      if (street != null) 'street': street,
      if (city != null) 'city': city,
      if (state != null) 'state': state,
      if (postalCode != null) 'postalCode': postalCode,
      if (country != null) 'country': country,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (description != null) 'description': description,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (ownerId != null) 'ownerId': ownerId,
      'organizationId': organizationId,
    };
  }

  @override
  String toString() {
    return 'Contact(id: $id, fullName: $fullName, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Contact &&
        other.id == id &&
        other.firstName == firstName &&
        other.lastName == lastName &&
        other.email == email &&
        other.phone == phone &&
        other.title == title &&
        other.department == department &&
        other.street == street &&
        other.city == city &&
        other.state == state &&
        other.postalCode == postalCode &&
        other.country == country &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt &&
        other.ownerId == ownerId &&
        other.organizationId == organizationId;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        firstName.hashCode ^
        lastName.hashCode ^
        email.hashCode ^
        phone.hashCode ^
        title.hashCode ^
        department.hashCode ^
        street.hashCode ^
        city.hashCode ^
        state.hashCode ^
        postalCode.hashCode ^
        country.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        description.hashCode ^
        createdAt.hashCode ^
        updatedAt.hashCode ^
        ownerId.hashCode ^
        organizationId.hashCode;
  }
}