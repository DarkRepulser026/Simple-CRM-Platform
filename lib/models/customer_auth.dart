/// Customer authentication request and response models

class RegisterRequest {
  final String email;
  final String password;
  final String name;
  final String? companyName;
  final String? phone;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
    this.companyName,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
        'name': name,
        if (companyName != null) 'companyName': companyName,
        if (phone != null) 'phone': phone,
      };
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class AuthResponse {
  final String userId;
  final String token;
  final String? refreshToken;
  final CustomerUser user;

  const AuthResponse({
    required this.userId,
    required this.token,
    this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['userId'] as String? ?? json['user']['id'] as String,
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String?,
      user: CustomerUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class RefreshTokenRequest {
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {
        'refreshToken': refreshToken,
      };
}

class RefreshTokenResponse {
  final String token;

  const RefreshTokenResponse({required this.token});

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      token: json['token'] as String,
    );
  }
}

class VerifyTokenResponse {
  final bool isValid;
  final CustomerUser? user;

  const VerifyTokenResponse({
    required this.isValid,
    this.user,
  });

  factory VerifyTokenResponse.fromJson(Map<String, dynamic> json) {
    return VerifyTokenResponse(
      isValid: json['isValid'] as bool,
      user: json['user'] != null
          ? CustomerUser.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class CustomerUser {
  final String id;
  final String email;
  final String name;
  final String? companyName;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerUser({
    required this.id,
    required this.email,
    required this.name,
    this.companyName,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerUser.fromJson(Map<String, dynamic> json) {
    return CustomerUser(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String,
      companyName: json['companyName'] as String?,
      phone: json['phone'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'name': name,
        if (companyName != null) 'companyName': companyName,
        if (phone != null) 'phone': phone,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
