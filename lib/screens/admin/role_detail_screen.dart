import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../services/service_locator.dart';
import '../../services/roles_service.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/role_visibility.dart';
import '../../screens/access_denied_redirect_screen.dart';

/// Role detail screen - view comprehensive role information and permissions
class RoleDetailScreen extends StatefulWidget {
  final String roleId;

  const RoleDetailScreen({
    super.key,
    required this.roleId,
  });

  @override
  State<RoleDetailScreen> createState() => _RoleDetailScreenState();
}

class _RoleDetailScreenState extends State<RoleDetailScreen> {
  late final RolesService _rolesService;
  UserRole? _role;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rolesService = locator<RolesService>();
    _loadRole();
  }

  Future<void> _loadRole() async {
    try {
      setState(() => _isLoading = true);
      // Note: You may need to add a getRoleById method to RolesService
      // For now, we'll fetch all roles and find the one matching
      final res = await _rolesService.getRoles(page: 1, limit: 1000);
      if (res.isSuccess) {
        final role =
            res.value.roles.firstWhere((r) => r.id == widget.roleId, orElse: () => res.value.roles.first);
        setState(() => _role = role);
      } else {
        setState(() => _errorMessage = res.error.message);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load role: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showEditRoleDialog() async {
    if (_role == null) return;
    
    final role = _role!;
    final nameCtrl = TextEditingController(text: role.name);
    final descCtrl = TextEditingController(text: role.description ?? '');
    UserRoleType currentType = role.roleType;
    Set<Permission> selected = role.permissions.toSet();
    final formKey = GlobalKey<FormState>();
    final myOrgRole = locator<AuthService>().selectedOrganization?.role?.toUpperCase();
    final canEdit = myOrgRole == 'ADMIN';
    final isDefaultRole = role.isDefault;
    final allowEdit = canEdit && !isDefaultRole;

    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setStateDialog) {
            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Edit role',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.of(ctx2).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Name
                        TextFormField(
                          controller: nameCtrl,
                          enabled: allowEdit,
                          decoration: const InputDecoration(labelText: 'Name'),
                          validator: (v) =>
                              (v == null || v.trim().isEmpty)
                                  ? 'Please enter a name'
                                  : null,
                        ),
                        const SizedBox(height: 12),
                        // Description
                        TextFormField(
                          controller: descCtrl,
                          enabled: allowEdit,
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Description'),
                        ),
                        const SizedBox(height: 12),
                        // Type
                        DropdownButtonFormField<UserRoleType>(
                          decoration: const InputDecoration(labelText: 'Type'),
                          value: currentType,
                          items: UserRoleType.values
                              .map(
                                (rt) => DropdownMenuItem(
                                  value: rt,
                                  child: Text(rt.value),
                                ),
                              )
                              .toList(),
                          onChanged: allowEdit ? (v) {
                            if (v != null) {
                              setStateDialog(() {
                                currentType = v;
                              });
                            }
                          } : null,
                        ),
                        const SizedBox(height: 16),
                        // Permissions
                        Text(
                          'Permissions',
                          style: Theme.of(ctx2).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: Permission.values.map((p) {
                            return FilterChip(
                              label: Text(p.value),
                              selected: selected.contains(p),
                              onSelected: (sel) {
                                if (!allowEdit) return;
                                setStateDialog(() {
                                  if (sel) {
                                    selected.add(p);
                                  } else {
                                    selected.remove(p);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                        // Actions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx2).pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            if (allowEdit)
                              FilledButton(
                                onPressed: () async {
                                  if (!formKey.currentState!.validate()) return;

                                  final roleToSave = UserRole(
                                    id: role.id,
                                    name: nameCtrl.text.trim(),
                                    description: descCtrl.text.trim(),
                                    roleType: currentType,
                                    permissions: selected.toList(),
                                    organizationId: role.organizationId,
                                    isDefault: role.isDefault,
                                    isActive: role.isActive,
                                    createdAt: role.createdAt,
                                    updatedAt: DateTime.now(),
                                  );

                                  final res = await _rolesService.updateRole(roleToSave);

                                  if (res.isSuccess) {
                                    if (mounted) {
                                      Navigator.of(ctx2).pop();
                                      setState(() => _role = res.value);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Role updated successfully'),
                                        ),
                                      );
                                    }
                                  } else {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to update role: ${res.error.message}',
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                },
                                child: const Text('Save'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final myOrgRole = locator<AuthService>().selectedOrganization?.role?.toUpperCase();
    final isAdmin = myOrgRole == 'ADMIN';
    final isDefaultRole = _role?.isDefault ?? false;
    final allowEdit = isAdmin && !isDefaultRole;

    return AdminOnly(
      fallback: const AccessDeniedRedirectScreen(),
      child: Scaffold(
        backgroundColor: const Color(0xFFE9EDF5),
        appBar: AppBar(
          backgroundColor: const Color(0xFFE9EDF5),
          elevation: 0,
          title: const Text('Role Details'),
          actions: [
            if (allowEdit && _role != null)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: _showEditRoleDialog,
              ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text('Error: $_errorMessage'),
                  )
                : _role == null
                    ? const Center(child: Text('Role not found'))
                    : Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header Card
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: colorScheme.surface,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            colorScheme.outline.withOpacity(0.08),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Title and Status
                                        Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary.withOpacity(0.08),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Icon(
                                                Icons.security,
                                                size: 24,
                                                color: colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    _role!.name,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineSmall
                                                        ?.copyWith(
                                                          fontWeight: FontWeight.w700,
                                                        ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _role!.description ?? 'No description',
                                                    style:
                                                        Theme.of(context).textTheme.bodyMedium,
                                                  ),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            // Status chips
                                            Column(
                                              children: [
                                                Chip(
                                                  label: Text(_role!.roleType.value),
                                                  backgroundColor:
                                                      colorScheme.secondary.withOpacity(0.1),
                                                  labelStyle: TextStyle(
                                                    color: colorScheme.secondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                if (_role!.isActive)
                                                  Chip(
                                                    label: const Text('Active'),
                                                    backgroundColor:
                                                        Colors.green.withOpacity(0.1),
                                                    labelStyle: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  )
                                                else
                                                  Chip(
                                                    label: const Text('Inactive'),
                                                    backgroundColor: Colors.orange.withOpacity(0.1),
                                                    labelStyle: const TextStyle(
                                                      color: Colors.orange,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 24),
                                        // Additional Info
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _InfoTile(
                                                label: 'Created',
                                                value: _formatDate(_role!.createdAt),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: _InfoTile(
                                                label: 'Last Updated',
                                                value: _formatDate(_role!.updatedAt),
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: _InfoTile(
                                                label: 'Default Role',
                                                value:
                                                    _role!.isDefault ? 'Yes' : 'No',
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  // Permissions Section
                                  Text(
                                    'Permissions (${_role!.permissions.length})',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 16),
                                  _buildPermissionsGrid(_role!.permissions),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildPermissionsGrid(List<Permission> permissions) {
    if (permissions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('No permissions assigned'),
        ),
      );
    }

    // Group permissions by category
    final grouped = _groupPermissionsByCategory(permissions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: grouped.entries.map((entry) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entry.value
                    .map(
                      (permission) => Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Text(
                          permission.value,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, List<Permission>> _groupPermissionsByCategory(List<Permission> permissions) {
    const categories = {
      'Contacts': [
        Permission.viewContacts,
        Permission.createContacts,
        Permission.editContacts,
        Permission.deleteContacts,
      ],
      'Leads': [
        Permission.viewLeads,
        Permission.createLeads,
        Permission.editLeads,
        Permission.deleteLeads,
        Permission.convertLeads,
      ],
      'Tickets': [
        Permission.viewTickets,
        Permission.createTickets,
        Permission.editTickets,
        Permission.deleteTickets,
        Permission.assignTickets,
        Permission.resolveTickets,
      ],
      'Tasks': [
        Permission.viewTasks,
        Permission.createTasks,
        Permission.editTasks,
        Permission.deleteTasks,
        Permission.assignTasks,
      ],
      'Dashboard & Reports': [
        Permission.viewDashboard,
        Permission.viewReports,
      ],
      'Admin': [
        Permission.manageUsers,
        Permission.manageRoles,
        Permission.manageOrganization,
        Permission.viewAuditLogs,
      ],
    };

    final grouped = <String, List<Permission>>{};
    for (final entry in categories.entries) {
      final filtered = entry.value.where((p) => permissions.contains(p)).toList();
      if (filtered.isNotEmpty) {
        grouped[entry.key] = filtered;
      }
    }
    return grouped;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

/// Simple info tile widget
class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
      ],
    );
  }
}
