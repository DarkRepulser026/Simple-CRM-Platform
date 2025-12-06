import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/users_service.dart';
import '../../models/user.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class UserDetailScreen extends StatelessWidget {
  final String userId;
  const UserDetailScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFE9EDF5);
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('User Details'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: UserDetailCard(userId: userId),
          ),
        ),
      ),
    );
  }
}

/// Dialog helper to show admin user detail as a modal dialog
Future<bool?> showAdminUserDetailDialog(BuildContext context, {required String userId}) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(padding: const EdgeInsets.all(16), child: SingleChildScrollView(child: UserDetailCard(userId: userId))),
      ),
    ),
  );
}

class UserDetailCard extends StatefulWidget {
  final String userId;
  const UserDetailCard({required this.userId});

  @override
  State<UserDetailCard> createState() => _UserDetailCardState();
}

class _UserDetailCardState extends State<UserDetailCard> {
  late final UsersService _usersService;
  late final AuthService _authService;
  bool _isLoading = true;
  String? _error;
  User? _user;
  bool _isEditing = false;

  // Edit form fields
  late TextEditingController _nameCtrl;
  late TextEditingController _emailCtrl;
  bool _isActive = true;
  String? _role;
  final List<String> _availableRoles = const ['ADMIN', 'MANAGER', 'AGENT', 'VIEWER'];

  @override
  void initState() {
    super.initState();
    _usersService = locator<UsersService>();
    _authService = locator<AuthService>();
    _nameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _usersService.getUser(widget.userId);
      if (res.isSuccess) {
        if (!mounted) return;
        final user = res.value;
        setState(() {
          _user = user;
          _nameCtrl.text = user.name;
          _emailCtrl.text = user.email;
          _isActive = user.isActive;
          _role = user.role;
          _isLoading = false;
        });
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load user: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveEdit() async {
    final newName = _nameCtrl.text.trim();
    final newEmail = _emailCtrl.text.trim();
    final newIsActive = _isActive;
    final newRole = _role;

    // Check if anything actually changed
    bool hasChanges = newName != (_user?.name ?? '') ||
        newEmail != (_user?.email ?? '') ||
        newIsActive != (_user?.isActive ?? true) ||
        newRole != _user?.role;

    if (!hasChanges) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No changes made')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updated = User(
        id: widget.userId,
        email: newEmail,
        name: newName,
        profileImage: _user?.profileImage,
        googleId: _user?.googleId,
        isActive: newIsActive,
        tokenVersion: _user?.tokenVersion ?? 0,
        role: newRole,
        createdAt: _user?.createdAt ?? DateTime.now(),
        updatedAt: _user?.updatedAt ?? DateTime.now(),
      );

      final res = await _usersService.updateUser(updated);
      if (res.isSuccess) {
        if (!mounted) return;
        setState(() {
          _user = res.value;
          _isEditing = false;
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User updated successfully')),
          );
          // Close dialog after brief delay to show success message
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) Navigator.of(context).pop(true);
        }
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to save user: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user'),
        content: const Text(
          'Remove this user from the organization? This will unassign them from the selected organization.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final res = await _usersService.deleteUser(widget.userId);
      if (res.isSuccess) {
        Navigator.of(context).pop(true);
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to delete user: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    
    if (_isLoading) return const Center(child: LoadingView(message: 'Loading user...'));
    if (_error != null) return Center(child: ErrorView(message: _error!, onRetry: _load));
    if (_user == null) return const Center(child: Text('No user data'));

    final colorScheme = Theme.of(context).colorScheme;
    final user = _user!;

    final me = _authService.currentUser;
    final myRole = _authService.selectedOrganization?.role?.toUpperCase();
    final isMe = me?.id == user.id;
    final isAdmin = myRole == 'ADMIN';
    final isManager = myRole == 'MANAGER';
    final canEdit = isMe || isAdmin || isManager;
    final canDelete = !isMe && isAdmin;

    // If editing, show form; otherwise show details
    if (_isEditing) {
      return _buildEditForm(context, colorScheme, canEdit, isMe);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                user.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              if (user.role != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(999)),
                  child: Text(user.role!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.primary)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with avatar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(radius: 40, child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold))),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(user.email, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          Row(children: [
                            Icon(user.isActive ? Icons.check_circle : Icons.cancel, size: 18, color: user.isActive ? Colors.green : Colors.red),
                            const SizedBox(width: 6),
                            Text(user.isActive ? 'Status: Active' : 'Status: Inactive', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: user.isActive ? Colors.green : Colors.red)),
                          ]),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Information sections
                Text('User Information', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                _buildDetailRow(
                  context,
                  label: 'User ID',
                  value: user.id,
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 12),

                _buildDetailRow(
                  context,
                  label: 'Email',
                  value: user.email,
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 12),

                if (user.googleId != null) ...[
                  _buildDetailRow(
                    context,
                    label: 'Google ID',
                    value: user.googleId!,
                    icon: Icons.verified_user_outlined,
                  ),
                  const SizedBox(height: 12),
                ],

                _buildDetailRow(
                  context,
                  label: 'Role',
                  value: user.role ?? 'VIEWER',
                  icon: Icons.security_outlined,
                ),
                const SizedBox(height: 12),

                _buildDetailRow(
                  context,
                  label: 'Token Version',
                  value: user.tokenVersion.toString(),
                  icon: Icons.vpn_key_outlined,
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Timestamps section
                Text('Activity Timeline', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                if (user.createdAt != null)
                  _buildDetailRow(
                    context,
                    label: 'Created',
                    value: _formatDateTime(user.createdAt!),
                    icon: Icons.event_note_outlined,
                  ),
                if (user.createdAt != null) const SizedBox(height: 12),

                if (user.updatedAt != null)
                  _buildDetailRow(
                    context,
                    label: 'Last Updated',
                    value: _formatDateTime(user.updatedAt!),
                    icon: Icons.update_outlined,
                  ),

                const SizedBox(height: 32),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Back')),
                    const SizedBox(width: 8),
                    if (canDelete)
                      OutlinedButton.icon(
                        onPressed: _delete,
                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                        style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                        label: const Text('Remove'),
                      ),
                    if (canDelete) const SizedBox(width: 8),
                    if (canEdit)
                      FilledButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Edit User'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build edit form
  Widget _buildEditForm(BuildContext context, ColorScheme colorScheme, bool canEdit, bool isMe) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.edit_outlined, size: 20),
              const SizedBox(width: 8),
              Text(
                'Edit User',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 18, offset: const Offset(0, 6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile & Permissions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Update basic information, role and status of this user.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),

                // Name field
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Email field
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),

                // Role + Status
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _role,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                        ),
                        items: _availableRoles
                            .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                            .toList(),
                        onChanged: (v) => setState(() => _role = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  _isActive ? Icons.check_circle : Icons.pause_circle_filled,
                                  size: 18,
                                  color: _isActive ? Colors.green : Colors.red,
                                ),
                                const SizedBox(width: 6),
                                Text(_isActive ? 'Active' : 'Inactive'),
                              ],
                            ),
                            Switch(
                              value: _isActive,
                              onChanged: (v) => setState(() => _isActive = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => setState(() {
                        _isEditing = false;
                        _nameCtrl.text = _user?.name ?? '';
                        _emailCtrl.text = _user?.email ?? '';
                        _isActive = _user?.isActive ?? true;
                        _role = _user?.role;
                      }),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _saveEdit,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save changes'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a detail row with icon, label, and value
  Widget _buildDetailRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Format DateTime to readable string
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

 
