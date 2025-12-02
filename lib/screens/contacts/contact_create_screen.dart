import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/contacts_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

/// === Public API =============================================================
/// Dùng ở bất cứ đâu (ví dụ từ ContactsListScreen) nếu muốn show popup trực tiếp:
///   final created = await showCreateContactDialog(context);
Future<bool?> showCreateContactDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _ContactCreateDialog(),
  );
}

class ContactCreateScreen extends StatefulWidget {
  const ContactCreateScreen({super.key});

  @override
  State<ContactCreateScreen> createState() => _ContactCreateScreenState();
}

class _ContactCreateScreenState extends State<ContactCreateScreen> {
  @override
  void initState() {
    super.initState();
    // mở dialog sau khi route được build
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await showCreateContactDialog(context);
      if (mounted) {
        Navigator.of(context).pop(result ?? false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Route này chỉ là “placeholder” cho popup
    return const SizedBox.shrink();
  }
}

/// === Dialog thực tế ================

class _ContactCreateDialog extends StatefulWidget {
  const _ContactCreateDialog();

  @override
  State<_ContactCreateDialog> createState() => _ContactCreateDialogState();
}

class _ContactCreateDialogState extends State<_ContactCreateDialog> {
  late final ContactsService _contactsService;

  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _contactsService = locator<ContactsService>();
  }

  Future<void> _createContact() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final contact = Contact(
      id: '',
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      organizationId: locator<AuthService>().selectedOrganizationId ?? '',
      // TODO: Add email/phone... here once supported by the model.
    );

    final res = await _contactsService.createContact(contact);

    if (!mounted) return;

    if (res.isSuccess) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isLoading = false;
        _error = res.error.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person_add_alt_1,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'New contact',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Keep your CRM organized by saving people you interact with.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_error != null) ...[
                ErrorView(message: _error!, onRetry: null),
                const SizedBox(height: 8),
              ],

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _firstNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'First name',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter first name'
                                : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lastNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Last name',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Please enter last name'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Work email (optional)',
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'You can add more details (phone, company, notes) after creating the contact.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _createContact,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check, size: 18),
                    label: Text(_isLoading ? 'Creating...' : 'Create contact'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
