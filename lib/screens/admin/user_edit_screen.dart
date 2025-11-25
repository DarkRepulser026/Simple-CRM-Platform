import 'package:flutter/material.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/users_service.dart';
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
  bool _isLoading = true;
  String? _error;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isActive = true;
  bool _canEditRole = false;
  String? _role;
  List<String> _availableRoles = ['ADMIN', 'MANAGER', 'AGENT', 'VIEWER'];

  @override
  void initState() {
    super.initState();
    _usersService = locator<UsersService>();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _usersService.getUser(widget.userId);
      if (res.isSuccess) {
        final u = res.value;
        _nameCtrl.text = u.name;
        _emailCtrl.text = u.email;
        _role = u.role;
        _isActive = u.isActive;
        final myRole = locator<AuthService>().selectedOrganization?.role?.toUpperCase();
        _canEditRole = (myRole == 'ADMIN' || myRole == 'MANAGER');
        setState(() => _isLoading = false);
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() => _error = 'Failed to load user: $e');
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
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit User')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a name' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter an email' : null),
              const SizedBox(height: 12),
              if (_canEditRole)
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: _availableRoles.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (v) => setState(() => _role = v),
                ),
              SwitchListTile(title: const Text('Active'), value: _isActive, onChanged: (v) => setState(() => _isActive = v)),
              const SizedBox(height: 20),
              ElevatedButton(onPressed: _save, child: const Text('Save')),
            ],
          ),
        ),
      ),
    );
  }
}
