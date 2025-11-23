import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../services/users_service.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class InviteUserScreen extends StatefulWidget {
  const InviteUserScreen({super.key});

  @override
  State<InviteUserScreen> createState() => _InviteUserScreenState();
}

class _InviteUserScreenState extends State<InviteUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  String _role = 'ADMIN';
  bool _isLoading = false;
  String? _error;

  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final usersService = locator<UsersService>();
    final auth = locator<AuthService>();
    final orgId = auth.selectedOrganizationId;
    if (orgId == null) {
      setState(() { _error = 'No organization selected'; _isLoading = false; });
      return;
    }
    final res = await usersService.inviteUser(orgId: orgId, email: _emailCtrl.text.trim(), role: _role);
    setState(() => _isLoading = false);
    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invite sent')));
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _error = res.error.message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invite User')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(children: [
            if (_error != null) ErrorView(message: _error!, onRetry: null),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter email' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _role,
              items: const [
                DropdownMenuItem(value: 'ADMIN', child: Text('Admin')),
                DropdownMenuItem(value: 'MANAGER', child: Text('Manager')),
                DropdownMenuItem(value: 'AGENT', child: Text('Agent')),
                DropdownMenuItem(value: 'VIEWER', child: Text('Viewer')),
              ],
              onChanged: (v) { if (v != null) setState(() => _role = v); },
              decoration: const InputDecoration(labelText: 'Role'),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const LoadingView(message: 'Sending invite...')
            else ElevatedButton(onPressed: _invite, child: const Text('Invite'))
          ]),
        ),
      ),
    );
  }
}
