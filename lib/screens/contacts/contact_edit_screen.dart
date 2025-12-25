import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../services/service_locator.dart';
import '../../services/contacts_service.dart';
import '../../services/accounts_service.dart';
import '../../services/users_service.dart';
import '../../models/user.dart';
import '../../models/account.dart';
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
  debugPrint('showContactEditDialog: request for $contactId');
  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
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
      try {
        final result = await showContactEditDialog(
          context,
          contactId: widget.contactId,
        );
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop(result ?? false);
        }
      } catch (e, st) {
        debugPrint('Failed to open ContactEditDialog: $e\n$st');
        if (mounted) Navigator.of(context, rootNavigator: true).pop(false);
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
  late final AccountsService _accountsService;
  late final UsersService _usersService;
  List<User>? _users;
  List<Account>? _accounts;

  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _postalCodeCtrl = TextEditingController();
  final _countryCtrl = TextEditingController();
  final _latitudeCtrl = TextEditingController();
  final _longitudeCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  String? _selectedOwnerId;
  String? _selectedAccountId;

  bool _isLoading = true; // load contact
  bool _isSaving = false; // saving state
  String? _error;
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _contactsService = locator<ContactsService>();
    _accountsService = locator<AccountsService>();
    _usersService = locator<UsersService>();
    _load();
    debugPrint('ContactEditDialog:init');
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
      _phoneCtrl.text = _contact!.phone ?? '';
      _titleCtrl.text = _contact!.title ?? '';
      _deptCtrl.text = _contact!.department ?? '';
      _streetCtrl.text = _contact!.street ?? '';
      _cityCtrl.text = _contact!.city ?? '';
      _stateCtrl.text = _contact!.state ?? '';
      _postalCodeCtrl.text = _contact!.postalCode ?? '';
      _countryCtrl.text = _contact!.country ?? '';
      _latitudeCtrl.text = _contact!.latitude?.toString() ?? '';
      _longitudeCtrl.text = _contact!.longitude?.toString() ?? '';
      _descriptionCtrl.text = _contact!.description ?? '';
      _selectedOwnerId = _contact!.ownerId ?? _contact!.owner?.id;
      _selectedAccountId = _contact!.accountId;
        await _loadData();
      setState(() => _isLoading = false);
    } else {
      debugPrint('Failed to load contact ${widget.contactId}: ${res.error.message}');
      setState(() {
        _error = res.error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _loadData() async {
    final usersRes = await _usersService.getUsers(limit: 200);
    if (usersRes.isSuccess) setState(() => _users = usersRes.value.users);

    final accountsRes = await _accountsService.getAccounts(limit: 1000);
    if (accountsRes.isSuccess) setState(() => _accounts = accountsRes.value.accounts);
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
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      department: _deptCtrl.text.trim().isEmpty ? null : _deptCtrl.text.trim(),
      street: _streetCtrl.text.trim().isEmpty ? null : _streetCtrl.text.trim(),
      city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
      state: _stateCtrl.text.trim().isEmpty ? null : _stateCtrl.text.trim(),
      postalCode: _postalCodeCtrl.text.trim().isEmpty ? null : _postalCodeCtrl.text.trim(),
      country: _countryCtrl.text.trim().isEmpty ? null : _countryCtrl.text.trim(),
      latitude: _latitudeCtrl.text.trim().isEmpty ? null : double.tryParse(_latitudeCtrl.text.trim()),
      longitude: _longitudeCtrl.text.trim().isEmpty ? null : double.tryParse(_longitudeCtrl.text.trim()),
      description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
      createdAt: _contact!.createdAt,
      updatedAt: DateTime.now(),
      ownerId: _selectedOwnerId ?? _contact!.ownerId,
      accountId: _selectedAccountId,
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
        child: SingleChildScrollView(
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
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone (optional)'),
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _titleCtrl,
                      decoration: const InputDecoration(labelText: 'Title (optional)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(controller: _deptCtrl, decoration: const InputDecoration(labelText: 'Department (optional)')),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(controller: _descriptionCtrl, decoration: const InputDecoration(labelText: 'Short description (optional)')),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _streetCtrl, decoration: const InputDecoration(labelText: 'Street'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _cityCtrl, decoration: const InputDecoration(labelText: 'City'))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _stateCtrl, decoration: const InputDecoration(labelText: 'State'))),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _postalCodeCtrl, decoration: const InputDecoration(labelText: 'Postal Code'))),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: TextFormField(controller: _countryCtrl, decoration: const InputDecoration(labelText: 'Country'))),
                  const SizedBox(width: 12),
                  Expanded(child: Row(children: [
                    Expanded(child: TextFormField(controller: _latitudeCtrl, decoration: const InputDecoration(labelText: 'Latitude'), keyboardType: TextInputType.number)),
                    const SizedBox(width: 8),
                    Expanded(child: TextFormField(controller: _longitudeCtrl, decoration: const InputDecoration(labelText: 'Longitude'), keyboardType: TextInputType.number)),
                  ])),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _selectedAccountId,
                decoration: const InputDecoration(
                  labelText: 'Account (Required)',
                  prefixIcon: Icon(Icons.business),
                ),
                items: (_accounts ?? []).map((a) => DropdownMenuItem<String?>(
                  value: a.id,
                  child: Text(a.name),
                )).toList(),
                validator: (v) => (v == null) ? 'Please select an account' : null,
                onChanged: (v) => setState(() => _selectedAccountId = v),
              ),
              const SizedBox(height: 12),
              Row(children: [
                 Expanded(
                   child: DropdownButtonFormField<String?>(
                     value: _selectedOwnerId,
                     decoration: const InputDecoration(labelText: 'Owner'),
                     items: [
                       const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
                       ...(_users ?? []).map((u) => DropdownMenuItem<String?>(value: u.id, child: Text(u.name))).toList(),
                     ],
                     onChanged: (v) => setState(() => _selectedOwnerId = v),
                   ),
                 ),
              ]),
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
