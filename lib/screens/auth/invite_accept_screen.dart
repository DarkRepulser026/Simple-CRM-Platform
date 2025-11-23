import 'package:flutter/material.dart';
// web-only: no dart:html imports necessary here
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class InviteAcceptScreen extends StatefulWidget {
  const InviteAcceptScreen({super.key});

  @override
  State<InviteAcceptScreen> createState() => _InviteAcceptScreenState();
}

class _InviteAcceptScreenState extends State<InviteAcceptScreen> {
  String? _token;
  final _nameCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final token = Uri.base.queryParameters['token'];
    setState(() => _token = token);
  }

  Future<void> _accept() async {
    final token = _token;
    if (token == null || token.isEmpty) return setState(() => _error = 'Invalid token');
    setState(() => _isLoading = true);
    final auth = locator<AuthService>();
    final ok = await auth.signInWithInviteToken(token, name: _nameCtrl.text.trim().isEmpty ? null : _nameCtrl.text.trim());
    setState(() => _isLoading = false);
    if (!ok) return setState(() => _error = 'Invite acceptance failed');
    // Navigate to dashboard after sign in
    Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accept Invite')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          if (_error != null) ErrorView(message: _error!, onRetry: null),
          const SizedBox(height: 8),
          Text('Token: ${_token ?? 'no token provided'}'),
          const SizedBox(height: 12),
          TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Your name (optional)')),
          const SizedBox(height: 20),
          if (_isLoading) const LoadingView(message: 'Accepting invite...') else ElevatedButton(onPressed: _accept, child: const Text('Accept Invite')),
        ]),
      ),
    );
  }
}
