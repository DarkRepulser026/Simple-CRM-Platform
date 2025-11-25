import 'package:flutter/material.dart';
// web-only: no dart:html imports necessary here
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
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
    // Support both path-based and hash-based (fragment) routing for web
    var token = Uri.base.queryParameters['token'];
    if (token == null || token.isEmpty) {
      final frag = Uri.base.fragment;
      if (frag.isNotEmpty) {
        try {
          final fragUri = Uri.parse(frag);
          token = fragUri.queryParameters['token'];
        } catch (_) {
          // ignore parse errors
        }
      }
    }
    setState(() => _token = token);
    // Attempt to auto-accept if the current user is already logged-in and the invite token matches their email
    Future.microtask(() async {
      if (token == null || token.isEmpty) return;
      final auth = locator<AuthService>();
      if (!auth.isLoggedIn) return; // not logged in — don't auto-accept
      try {
        final payload = JwtDecoder.decode(token);
        final tokenEmail = payload['email'] as String?;
        final currentEmail = auth.currentUser?.email;
        final orgId = payload['orgId'] ?? payload['organizationId'] ?? '';
        final role = payload['role'] ?? 'member';
        if (tokenEmail != null && currentEmail != null && tokenEmail == currentEmail) {
          // token belongs to the logged-in user — show a confirmation dialog first
          final confirmed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Accept Invitation'),
              content: Text('Accept invitation for "$tokenEmail" to organization "${orgId}" as "$role"?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Accept')),
              ],
            ),
          );
          if (confirmed != true) return; // user cancelled

          if (!mounted) return;
          setState(() => _isLoading = true);
          final ok = await auth.acceptInviteTokenAsCurrentUser(token);
          if (!mounted) return;
          setState(() => _isLoading = false);
          if (ok) {
            // Navigate to dashboard in the context of selected organization
            if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
          } else {
            if (mounted) setState(() => _error = 'Invite acceptance failed (auto).');
          }
        }
      } catch (e) {
        debugPrint('Invite accept auto-check error: $e');
        // ignore decode errors
      }
    });
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
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
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
