import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../services/service_locator.dart';
import '../../services/contacts_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class ContactEditArgs {
  const ContactEditArgs({required this.contactId});
  final String contactId;
}

Future<bool?> showContactEditDialog(
  BuildContext context, {
  required String contactId,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _ContactEditDialog(contactId: contactId),
  );
}


class ContactEditScreen extends StatefulWidget {
  final String contactId;
  const ContactEditScreen({super.key, required this.contactId});

  @override
  State<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends State<ContactEditScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final result = await showContactEditDialog(
        context,
        contactId: widget.contactId,
      );
      if (mounted) {
        Navigator.of(context).pop(result ?? false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Nội dung chính nằm trong dialog
    return const SizedBox.shrink();
  }
}

/// ===================== DIALOG EDIT CONTACT =======================

class _ContactEditDialog extends StatefulWidget {
  const _ContactEditDialog({required this.contactId});

  final String contactId;

  @override
  State<_ContactEditDialog> createState() => _ContactEditDialogState();
}

class _ContactEditDialogState extends State<_ContactEditDialog> {
  late final ContactsService _contactsService;

  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isLoading = true; // load contact
  bool _isSaving = false; // saving state
  String? _error;
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _contactsService = locator<ContactsService>();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final res = await _contactsService.getContact(widget.contactId);
    if (!mounted) return;
    if (res.isSuccess) {
      _contact = res.value;
      _firstNameCtrl.text = _contact!.firstName;
      _lastNameCtrl.text = _contact!.lastName;
      _emailCtrl.text = _contact!.email ?? '';
      setState(() => _isLoading = false);
    } else {
      setState(() {
        _error = res.error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _contact == null) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });

    final updated = Contact(
      id: _contact!.id,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email:
          _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _contact!.phone,
      title: _contact!.title,
      department: _contact!.department,
      street: _contact!.street,
      city: _contact!.city,
      state: _contact!.state,
      postalCode: _contact!.postalCode,
      country: _contact!.country,
      latitude: _contact!.latitude,
      longitude: _contact!.longitude,
      description: _contact!.description,
      createdAt: _contact!.createdAt,
      updatedAt: DateTime.now(),
      ownerId: _contact!.ownerId,
      organizationId: _contact!.organizationId,
    );

    final res = await _contactsService.updateContact(updated);
    if (!mounted) return;

    if (res.isSuccess) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _error = res.error.message;
        _isSaving = false;
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
          child: _isLoading
              ? const SizedBox(
                  height: 220,
                  child: Center(
                    child: LoadingView(message: 'Loading contact...'),
                  ),
                )
              : _buildContent(context, colorScheme),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colorScheme) {
    if (_error != null && _contact == null) {
      // Lỗi khi load, chưa có data
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ErrorView(message: _error!, onRetry: _load),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Close'),
            ),
          ),
        ],
      );
    }

    final namePreview =
        '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}'.trim();
    final avatarInitial = namePreview.isNotEmpty
        ? namePreview[0].toUpperCase()
        : (_contact?.fullName.isNotEmpty == true
            ? _contact!.fullName[0].toUpperCase()
            : '?');

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ===== HEADER =====
        Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: colorScheme.primary.withOpacity(0.12),
              child: Text(
                avatarInitial,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Edit contact',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Update basic information for this person.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _isSaving
                  ? null
                  : () => Navigator.of(context).pop(false),
              icon: const Icon(Icons.close),
              tooltip: 'Close',
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_error != null && _contact != null) ...[
          ErrorView(message: _error!, onRetry: _load),
          const SizedBox(height: 8),
        ],

        // ===== FORM =====
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
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
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
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
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
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'You can edit address, phone and other fields from the full detail view later.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ===== ACTIONS =====
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed:
                  _isSaving ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined, size: 18),
              label: Text(_isSaving ? 'Saving...' : 'Save changes'),
            ),
          ],
        ),
      ],
    );
  }
}
