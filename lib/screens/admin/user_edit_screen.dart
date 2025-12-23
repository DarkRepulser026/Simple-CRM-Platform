import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/users_service.dart';
import '../../services/roles_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class UserEditScreen extends StatefulWidget {
  final String userId;
  const UserEditScreen({super.key, required this.userId});

  @override
  State<UserEditScreen> createState() => _UserEditScreenState();
}

class _UserEditScreenState extends State<UserEditScreen> {
  late final UsersService _usersService;
  late final RolesService _rolesService;
  bool _isLoading = true;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isActive = true;
  bool _canEditRole = false;
  String? _role;
  List<String> _availableRoles = [];

  @override
  void initState() {
    super.initState();
    _usersService = locator<UsersService>();
    _rolesService = locator<RolesService>();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      // Fetch roles first
      final rolesRes = await _rolesService.getRoles();
      if (rolesRes.isSuccess) {
        _availableRoles = rolesRes.value.roles.map((r) => r.name).toList();
      } else {
        // Fallback if roles fetch fails, but we should probably handle this better
        _availableRoles = ['ADMIN', 'MANAGER', 'AGENT', 'VIEWER'];
      }

      final res = await _usersService.getUser(widget.userId);
      if (res.isSuccess) {
        final u = res.value;
        _nameCtrl.text = u.name;
        _emailCtrl.text = u.email;
        _role = u.role;
        _isActive = u.isActive;

        // Ensure current role is in available roles if it's not there for some reason
        if (_role != null && !_availableRoles.contains(_role)) {
          _availableRoles.add(_role!);
        }

        final myRole =
            locator<AuthService>().selectedOrganization?.role?.toUpperCase();
        _canEditRole = (myRole == 'ADMIN' || myRole == 'MANAGER');

        setState(() => _isLoading = false);
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() {
        _error = 'Failed to load user: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = User(
        id: widget.userId,
        email: _emailCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        profileImage: null,
        googleId: null,
        isActive: _isActive,
        role: _role,
      );

      final res = await _usersService.updateUser(user);
      if (res.isSuccess) {
        Navigator.of(context).pop(true);
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFFE9EDF5); // nền CRM đồng bộ

    if (_isLoading) {
      return const Scaffold(body: LoadingView(message: 'Loading...'));
    }
    if (_error != null) {
      return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('Edit user'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outline.withOpacity(0.08),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + subtitle
                    Text(
                      'Profile & permissions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Update basic information, role and status of this user.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // Name
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please enter a name' : null,
                    ),
                    const SizedBox(height: 14),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Please enter an email' : null,
                    ),
                    const SizedBox(height: 14),

                    // Role + Active
                    Row(
                      children: [
                        if (_canEditRole)
                          Expanded(
                            flex: 3,
                            child: DropdownButtonFormField<String>(
                              value: _role,
                              decoration: const InputDecoration(
                                labelText: 'Role',
                                border: OutlineInputBorder(),
                              ),
                              items: _availableRoles
                                  .map(
                                    (r) => DropdownMenuItem(
                                      value: r,
                                      child: Text(r),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => _role = v),
                            ),
                          )
                        else
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              enabled: false,
                              initialValue: _role ?? 'VIEWER',
                              decoration: const InputDecoration(
                                labelText: 'Role',
                                border: OutlineInputBorder(),
                              ),
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
                                      _isActive
                                          ? Icons.check_circle
                                          : Icons.pause_circle_filled,
                                      size: 18,
                                      color: _isActive ? Colors.green : Colors.red,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(_isActive ? 'Active' : 'Inactive'),
                                  ],
                                ),
                                Switch(
                                  value: _isActive,
                                  onChanged: (v) =>
                                      setState(() => _isActive = v),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Save changes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
