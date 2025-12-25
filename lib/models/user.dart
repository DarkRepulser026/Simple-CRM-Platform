class User {
  final String id;
  final String email;
  final String name;
  final String? profileImage;
  final String? googleId;
  final bool isActive;
  final int tokenVersion;
  final String? role;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
    this.googleId,
    this.isActive = true,
    this.tokenVersion = 0,
    this.role,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
      googleId: json['googleId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      tokenVersion: json['tokenVersion'] as int? ?? 0,
      role: json['role'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (profileImage != null) 'profileImage': profileImage,
      if (googleId != null) 'googleId': googleId,
      'isActive': isActive,
      'tokenVersion': tokenVersion,
      if (role != null) 'role': role,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, profileImage: $profileImage, googleId: $googleId, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.profileImage == profileImage &&
        other.googleId == googleId &&
        other.isActive == isActive &&
        other.tokenVersion == tokenVersion &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ name.hashCode ^ profileImage.hashCode ^ googleId.hashCode ^ isActive.hashCode ^ tokenVersion.hashCode ^ (createdAt?.hashCode ?? 0) ^ (updatedAt?.hashCode ?? 0);
  }
}