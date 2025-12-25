import 'package:flutter/material.dart';
import '../../models/user_role.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../services/roles_service.dart';

/// Widget for assigning a role to a user
/// Can be used in user detail/edit screens
class RoleAssignmentWidget extends StatefulWidget {
  final User user;
  final UserRole? currentRole;
  final Function(UserRole)? onRoleChanged;
  final bool enabled;

  const RoleAssignmentWidget({
    super.key,
    required this.user,
    this.currentRole,
    this.onRoleChanged,
    this.enabled = true,
  });

  @override
  State<RoleAssignmentWidget> createState() => _RoleAssignmentWidgetState();
}

class _RoleAssignmentWidgetState extends State<RoleAssignmentWidget> {
  late final RolesService _rolesService;
  List<UserRole>? _availableRoles;
  String? _errorMessage;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _rolesService = locator<RolesService>();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      setState(() => _isLoading = true);
      final result = await _rolesService.getActiveRoles(limit: 100);
      if (result.isSuccess) {
        setState(() => _availableRoles = result.value);
      } else {
        setState(() => _errorMessage = result.error.message);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load roles: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_errorMessage != null) {
      return SizedBox(
        height: 56,
        child: Center(
          child: Text(
            'Error: $_errorMessage',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }

    if (_availableRoles == null || _availableRoles!.isEmpty) {
      return const SizedBox(
        height: 56,
        child: Center(child: Text('No roles available')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Assign Role',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<UserRole>(
          value: widget.currentRole,
          decoration: InputDecoration(
            hintText: 'Select a role',
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
          ),
          isExpanded: true,
          items: _availableRoles!
              .map(
                (role) => DropdownMenuItem(
                  value: role,
                  child: Row(
                    children: [
                      Text(role.name),
                      const SizedBox(width: 8),
                      Chip(
                        label: Text(role.roleType.value),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          onChanged: widget.enabled
              ? (role) {
                  if (role != null) {
                    widget.onRoleChanged?.call(role);
                  }
                }
              : null,
        ),
        if (widget.currentRole != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selected Role Details',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Permissions: ${widget.currentRole!.permissions.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: widget.currentRole!.permissions.take(5).map((p) {
                    return Chip(
                      label: Text(p.value),
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary.withOpacity(0.15),
                    );
                  }).toList(),
                ),
                if (widget.currentRole!.permissions.length > 5)
                  Text(
                    '+${widget.currentRole!.permissions.length - 5} more',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Dialog for bulk role assignment to multiple users
class BulkRoleAssignmentDialog extends StatefulWidget {
  final List<User> users;
  final Function(UserRole selectedRole, List<User> selectedUsers)? onAssign;

  const BulkRoleAssignmentDialog({
    super.key,
    required this.users,
    this.onAssign,
  });

  @override
  State<BulkRoleAssignmentDialog> createState() =>
      _BulkRoleAssignmentDialogState();
}

class _BulkRoleAssignmentDialogState extends State<BulkRoleAssignmentDialog> {
  late final RolesService _rolesService;
  List<UserRole>? _availableRoles;
  UserRole? _selectedRole;
  Set<String> _selectedUserIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _rolesService = locator<RolesService>();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    try {
      setState(() => _isLoading = true);
      final result = await _rolesService.getActiveRoles(limit: 100);
      if (result.isSuccess) {
        setState(() => _availableRoles = result.value);
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Assign Role to Users'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Role selection dropdown
              Text(
                'Select Role',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else if (_availableRoles == null || _availableRoles!.isEmpty)
                const Text('No roles available')
              else
                DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  isExpanded: true,
                  items: _availableRoles!
                      .map(
                        (role) => DropdownMenuItem(
                          value: role,
                          child: Text(role.name),
                        ),
                      )
                      .toList(),
                  onChanged: (role) {
                    setState(() => _selectedRole = role);
                  },
                ),
              const SizedBox(height: 24),
              // Users selection
              Text(
                'Select Users',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SizedBox(
                  height: 250,
                  child: ListView.builder(
                    itemCount: widget.users.length,
                    itemBuilder: (context, index) {
                      final user = widget.users[index];
                      final isSelected = _selectedUserIds.contains(user.id);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (selected) {
                          setState(() {
                            if (selected == true) {
                              _selectedUserIds.add(user.id);
                            } else {
                              _selectedUserIds.remove(user.id);
                            }
                          });
                        },
                        title: Text(user.name),
                        subtitle: Text(user.email),
                        dense: true,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${_selectedUserIds.length} user(s) selected',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _selectedRole == null || _selectedUserIds.isEmpty
              ? null
              : () {
                  final selectedUsers = widget.users
                      .where((u) => _selectedUserIds.contains(u.id))
                      .toList();
                  widget.onAssign?.call(_selectedRole!, selectedUsers);
                  Navigator.of(context).pop();
                },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
