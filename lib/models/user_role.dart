/// User role enumeration
enum UserRoleType {
  admin('Admin'),
  manager('Manager'),
  agent('Agent'),
  viewer('Viewer');

  const UserRoleType(this.value);
  final String value;

  static UserRoleType fromString(String value) {
    return UserRoleType.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRoleType.viewer,
    );
  }
}

/// Permission enumeration for granular access control
enum Permission {
  // Contact permissions
  viewContacts('view_contacts'),
  createContacts('create_contacts'),
  editContacts('edit_contacts'),
  deleteContacts('delete_contacts'),

  // Lead permissions
  viewLeads('view_leads'),
  createLeads('create_leads'),
  editLeads('edit_leads'),
  deleteLeads('delete_leads'),
  convertLeads('convert_leads'),

  // Ticket permissions
  viewTickets('view_tickets'),
  createTickets('create_tickets'),
  editTickets('edit_tickets'),
  deleteTickets('delete_tickets'),
  assignTickets('assign_tickets'),
  resolveTickets('resolve_tickets'),

  // Task permissions
  viewTasks('view_tasks'),
  createTasks('create_tasks'),
  editTasks('edit_tasks'),
  deleteTasks('delete_tasks'),
  assignTasks('assign_tasks'),

  // Dashboard permissions
  viewDashboard('view_dashboard'),
  viewReports('view_reports'),

  // Admin permissions
  manageUsers('manage_users'),
  manageRoles('manage_roles'),
  manageOrganization('manage_organization'),
  viewAuditLogs('view_audit_logs');

  const Permission(this.value);
  final String value;

  static Permission fromString(String value) {
    return Permission.values.firstWhere(
      (permission) => permission.value == value,
      orElse: () => Permission.viewContacts,
    );
  }
}

/// UserRole model representing user roles and their permissions
class UserRole {
  final String id;
  final String name;
  final String? description;
  final UserRoleType roleType;
  final List<Permission> permissions;
  final String organizationId;
  final bool isDefault; // Whether this is the default role for new users
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserRole({
    required this.id,
    required this.name,
    this.description,
    required this.roleType,
    required this.permissions,
    required this.organizationId,
    this.isDefault = false,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Computed property to check if role has a specific permission
  bool hasPermission(Permission permission) {
    return permissions.contains(permission);
  }

  /// Computed property to check if role has any of the specified permissions
  bool hasAnyPermission(List<Permission> permissions) {
    return permissions.any((permission) => hasPermission(permission));
  }

  /// Computed property to check if role has all of the specified permissions
  bool hasAllPermissions(List<Permission> permissions) {
    return permissions.every((permission) => hasPermission(permission));
  }

  /// Get default permissions for a role type
  static List<Permission> getDefaultPermissions(UserRoleType roleType) {
    switch (roleType) {
      case UserRoleType.admin:
        return Permission.values; // All permissions
      case UserRoleType.manager:
        return [
          // Contact permissions
          Permission.viewContacts,
          Permission.createContacts,
          Permission.editContacts,
          Permission.deleteContacts,
          // Lead permissions
          Permission.viewLeads,
          Permission.createLeads,
          Permission.editLeads,
          Permission.convertLeads,
          // Ticket permissions
          Permission.viewTickets,
          Permission.createTickets,
          Permission.editTickets,
          Permission.assignTickets,
          Permission.resolveTickets,
          // Task permissions
          Permission.viewTasks,
          Permission.createTasks,
          Permission.editTasks,
          Permission.assignTasks,
          // Dashboard permissions
          Permission.viewDashboard,
          Permission.viewReports,
          // Limited admin permissions
          Permission.manageUsers,
        ];
      case UserRoleType.agent:
        return [
          // Contact permissions
          Permission.viewContacts,
          Permission.createContacts,
          Permission.editContacts,
          // Lead permissions
          Permission.viewLeads,
          Permission.createLeads,
          Permission.editLeads,
          Permission.convertLeads,
          // Ticket permissions
          Permission.viewTickets,
          Permission.createTickets,
          Permission.editTickets,
          Permission.resolveTickets,
          // Task permissions
          Permission.viewTasks,
          Permission.createTasks,
          Permission.editTasks,
          // Dashboard permissions
          Permission.viewDashboard,
        ];
      case UserRoleType.viewer:
        return [
          // Read-only permissions
          Permission.viewContacts,
          Permission.viewLeads,
          Permission.viewTickets,
          Permission.viewTasks,
          Permission.viewDashboard,
        ];
    }
  }

  /// Factory constructor to create UserRole from JSON
  factory UserRole.fromJson(Map<String, dynamic> json) {
    return UserRole(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      roleType: UserRoleType.fromString(json['roleType'] ?? 'Viewer'),
      permissions: json['permissions'] != null
          ? (json['permissions'] as List<dynamic>)
              .map((p) => Permission.fromString(p as String))
              .toList()
          : [],
      organizationId: json['organizationId'] ?? '',
      isDefault: json['isDefault'] ?? false,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  /// Convert UserRole to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'roleType': roleType.value,
      'permissions': permissions.map((p) => p.value).toList(),
      'organizationId': organizationId,
      'isDefault': isDefault,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Create a copy of UserRole with modified fields
  UserRole copyWith({
    String? id,
    String? name,
    String? description,
    UserRoleType? roleType,
    List<Permission>? permissions,
    String? organizationId,
    bool? isDefault,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserRole(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      roleType: roleType ?? this.roleType,
      permissions: permissions ?? this.permissions,
      organizationId: organizationId ?? this.organizationId,
      isDefault: isDefault ?? this.isDefault,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserRole && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserRole(id: $id, name: $name, type: ${roleType.value}, permissions: ${permissions.length})';
  }
}