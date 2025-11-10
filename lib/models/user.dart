class User {
  final String id;
  final String email;
  final String name;
  final String? profileImage;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.profileImage,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      name: json['name'] as String? ?? '',
      profileImage: json['profileImage'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      if (profileImage != null) 'profileImage': profileImage,
    };
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, profileImage: $profileImage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User &&
        other.id == id &&
        other.email == email &&
        other.name == name &&
        other.profileImage == profileImage;
  }

  @override
  int get hashCode {
    return id.hashCode ^ email.hashCode ^ name.hashCode ^ profileImage.hashCode;
  }
}