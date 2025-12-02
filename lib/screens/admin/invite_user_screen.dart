import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../services/users_service.dart';
import '../../services/auth/auth_service.dart';

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

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final usersService = locator<UsersService>();
    final auth = locator<AuthService>();
    final orgId = auth.selectedOrganizationId;

    if (orgId == null) {
      setState(() {
        _error = 'No organization selected';
        _isLoading = false;
      });
      return;
    }

    final res = await usersService.inviteUser(
      orgId: orgId,
      email: _emailCtrl.text.trim(),
      role: _role,
    );

    setState(() => _isLoading = false);

    if (res.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation sent')),
      );
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = res.error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final orgName =
        locator<AuthService>().selectedOrganization?.name ?? 'your workspace';

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.35),
      body: Center(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.of(context).pop(),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 520,
                    minWidth: 360,
                  ),
                  child: GestureDetector(
                    onTap: () {},
                    child: Material(
                      borderRadius: BorderRadius.circular(20),
                      elevation: 24,
                      color: colorScheme.surface,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 20,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ===== HEADER TRONG DIALOG =====
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: colorScheme.primary
                                        .withOpacity(0.12),
                                    child: Icon(
                                      Icons.person_add_alt_1,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Invite user',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 3,
                                              ),
                                              decoration: BoxDecoration(
                                                color: colorScheme.primary
                                                    .withOpacity(0.08),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                'Admin',
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color:
                                                          colorScheme.primary,
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'We’ll email them a secure link to join $orgName.',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Close',
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    icon: const Icon(Icons.close_rounded),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              if (_error != null) ...[
                                Container(
                                  width: double.infinity,
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Colors.red.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.error_outline,
                                        size: 18,
                                        color: Colors.red,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(color: Colors.red),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              // ===== EMAIL =====
                              TextFormField(
                                controller: _emailCtrl,
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Work email',
                                  hintText: 'name@company.com',
                                  prefixIcon: Icon(Icons.mail_outline),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Please enter an email';
                                  }
                                  if (!v.contains('@')) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),

                              // ===== ROLE =====
                              DropdownButtonFormField<String>(
                                value: _role,
                                decoration: const InputDecoration(
                                  labelText: 'Role',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ADMIN',
                                    child: Text('Admin'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'MANAGER',
                                    child: Text('Manager'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'AGENT',
                                    child: Text('Agent'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'VIEWER',
                                    child: Text('Viewer'),
                                  ),
                                ],
                                onChanged: (v) {
                                  if (v != null) {
                                    setState(() => _role = v);
                                  }
                                },
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _roleDescription(_role),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          colorScheme.onSurfaceVariant,
                                    ),
                              ),

                              const SizedBox(height: 22),

                              // ===== BUTTONS =====
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextButton(
                                    onPressed: _isLoading
                                        ? null
                                        : () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  const SizedBox(width: 8),
                                  FilledButton.icon(
                                    onPressed:
                                        _isLoading ? null : _invite,
                                    icon: _isLoading
                                        ? SizedBox(
                                            width: 16,
                                            height: 16,
                                            child:
                                                CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation<
                                                      Color>(
                                                colorScheme.onPrimary,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.send_rounded,
                                            size: 18,
                                          ),
                                    label: Text(
                                      _isLoading
                                          ? 'Sending...'
                                          : 'Send invite',
                                    ),
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
            },
          ),
        ),
      ),
    );
  }

  String _roleDescription(String role) {
    switch (role) {
      case 'ADMIN':
        return 'Admins can manage users, roles and all CRM data.';
      case 'MANAGER':
        return 'Managers can oversee teams and update most records.';
      case 'AGENT':
        return 'Agents work on assigned leads, tickets and tasks.';
      case 'VIEWER':
        return 'Viewers have read-only access to data.';
      default:
        return '';
    }
  }
}
