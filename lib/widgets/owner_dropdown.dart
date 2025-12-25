import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/users_service.dart';
import '../services/service_locator.dart';

/// Reusable dropdown widget for assigning owners to tickets or tasks
///
/// Usage:
/// ```dart
/// OwnerDropdown(
///   entityType: 'ticket', // or 'task'
///   initialOwnerId: ticket.ownerId,
///   onChanged: (ownerId) => setState(() => _ownerId = ownerId),
/// )
/// ```
class OwnerDropdown extends StatefulWidget {
  final String? initialOwnerId;
  final String entityType; // 'ticket' or 'task'
  final ValueChanged<String?> onChanged;
  final String? label;
  final String? hintText;
  final bool enabled;

  const OwnerDropdown({
    super.key,
    this.initialOwnerId,
    required this.entityType,
    required this.onChanged,
    this.label,
    this.hintText,
    this.enabled = true,
  });

  @override
  State<OwnerDropdown> createState() => _OwnerDropdownState();
}

class _OwnerDropdownState extends State<OwnerDropdown> {
  List<User> _users = [];
  bool _loading = true;
  String? _selectedOwnerId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedOwnerId = widget.initialOwnerId;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final usersService = locator<UsersService>();

    final result = widget.entityType == 'ticket'
        ? await usersService.getTicketAssignableUsers()
        : await usersService.getTaskAssignableUsers();

    if (result.isSuccess && mounted) {
      setState(() {
        _users = result.value;
        _loading = false;
      });
    } else if (mounted) {
      setState(() {
        _error = result.error.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label ?? 'Assign To',
          filled: true,
          fillColor: cs.surfaceVariant.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        child: const SizedBox(
          height: 20,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          InputDecorator(
            decoration: InputDecoration(
              labelText: widget.label ?? 'Assign To',
              filled: true,
              fillColor: cs.errorContainer.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: cs.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Failed to load users',
                    style: TextStyle(color: cs.error, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: _loadUsers,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            ),
          ),
        ],
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedOwnerId,
      decoration: InputDecoration(
        labelText: widget.label ?? 'Assign To',
        hintText: widget.hintText ?? 'Select assignee',
        filled: true,
        fillColor: cs.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        prefixIcon: Icon(Icons.person_outline, color: cs.primary),
      ),
      isExpanded: true,
      menuMaxHeight: 300,
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(
            'Unassigned',
            style: TextStyle(
              color: cs.onSurface.withOpacity(0.6),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        ..._users.map(
          (user) => DropdownMenuItem<String>(
            value: user.id,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage:
                      user.profileImage != null && user.profileImage!.isNotEmpty
                      ? NetworkImage(user.profileImage!)
                      : null,
                  child: user.profileImage == null || user.profileImage!.isEmpty
                      ? Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    user.email.isNotEmpty 
                        ? '${user.name} (${user.email})'
                        : user.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                if (user.role != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.role!, cs),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      user.role!,
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
      onChanged: widget.enabled
          ? (value) {
              setState(() => _selectedOwnerId = value);
              widget.onChanged(value);
            }
          : null,
    );
  }

  Color _getRoleColor(String role, ColorScheme cs) {
    switch (role.toUpperCase()) {
      case 'ADMIN':
        return cs.error;
      case 'MANAGER':
        return cs.tertiary;
      case 'AGENT':
        return cs.primary;
      default:
        return cs.secondary;
    }
  }
}
