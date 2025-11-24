class Invitation {
  final String id;
  final String email;
  final String role;
  final String organizationId;
  final DateTime? expiresAt;
  final DateTime? acceptedAt;
  final DateTime? revokedAt;
  final DateTime createdAt;
  final String? createdBy;

  Invitation({
    required this.id,
    required this.email,
    required this.role,
    required this.organizationId,
    required this.createdAt,
    this.expiresAt,
    this.acceptedAt,
    this.revokedAt,
    this.createdBy,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) => Invitation(
        id: json['id'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        organizationId: json['organizationId'] as String,
        expiresAt: json['expiresAt'] != null ? DateTime.parse(json['expiresAt'] as String) : null,
        acceptedAt: json['acceptedAt'] != null ? DateTime.parse(json['acceptedAt'] as String) : null,
        revokedAt: json['revokedAt'] != null ? DateTime.parse(json['revokedAt'] as String) : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        createdBy: json['createdBy'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'role': role,
        'organizationId': organizationId,
        'expiresAt': expiresAt?.toIso8601String(),
        'acceptedAt': acceptedAt?.toIso8601String(),
        'revokedAt': revokedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'createdBy': createdBy,
      };
}
