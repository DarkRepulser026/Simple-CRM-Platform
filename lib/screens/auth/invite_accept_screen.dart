import 'package:flutter/material.dart';
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

  // UI Colors
  final Color _primaryColor = const Color(0xFF0F172A);
  final Color _accentColor = const Color(0xFF3B82F6);

  @override
  void initState() {
    super.initState();
    // (Logic giữ nguyên)
    var token = Uri.base.queryParameters['token'];
    if (token == null || token.isEmpty) {
      final frag = Uri.base.fragment;
      if (frag.isNotEmpty) {
        try {
          final fragUri = Uri.parse(frag);
          token = fragUri.queryParameters['token'];
        } catch (_) {}
      }
    }
    setState(() => _token = token);
    
    // Auto-accept logic
    Future.microtask(() async {
      if (token == null || token.isEmpty) return;
      final auth = locator<AuthService>();
      if (!auth.isLoggedIn) return;
      try {
        final payload = JwtDecoder.decode(token);
        final tokenEmail = payload['email'] as String?;
        final currentEmail = auth.currentUser?.email;
        // ignore: unused_local_variable
        final orgId = payload['orgId'] ?? payload['organizationId'] ?? '';
        final role = payload['role'] ?? 'member';
        
        if (tokenEmail != null && currentEmail != null && tokenEmail == currentEmail) {
          final confirmed = await showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Accept Invitation'),
              content: Text('You are already logged in as $currentEmail.\nAccept invitation to join as "$role"?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Accept')),
              ],
            ),
          );
          if (confirmed != true) return;

          if (!mounted) return;
          setState(() => _isLoading = true);
          final ok = await auth.acceptInviteTokenAsCurrentUser(token);
          if (!mounted) return;
          setState(() => _isLoading = false);
          if (ok) {
            if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
          } else {
            if (mounted) setState(() => _error = 'Invite acceptance failed.');
          }
        }
      } catch (e) {
        debugPrint('Invite check error: $e');
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
    if (mounted) Navigator.of(context).pushReplacementNamed('/dashboard');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // Slate 50
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon Header
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.mail_outline_rounded, size: 40, color: _accentColor),
                    ),
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      'You\'ve been invited!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please confirm your details to join the organization workspace.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], height: 1.5),
                    ),
                    const SizedBox(height: 32),

                    // Error View
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ErrorView(message: _error!, onRetry: null),
                      ),

                    // Token Info (Subtle)
                    if (_token != null)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.vpn_key_outlined, size: 14, color: Colors.grey[600]),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Secure Token: ${_token!.substring(0, 10)}...',
                                style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.grey[700]),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Form
                    TextField(
                      controller: _nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Your Full Name (Optional)',
                        hintText: 'e.g. John Doe',
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: _isLoading
                          ? Center(child: LoadingView(message: 'Processing...', size: 24))
                          : ElevatedButton(
                              onPressed: _accept,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: const Text('Accept Invitation & Join', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            ),
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