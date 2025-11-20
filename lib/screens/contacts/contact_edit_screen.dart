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

class ContactEditScreen extends StatefulWidget {
  final String contactId;
  const ContactEditScreen({super.key, required this.contactId});

  @override
  State<ContactEditScreen> createState() => _ContactEditScreenState();
}

class _ContactEditScreenState extends State<ContactEditScreen> {
  late final ContactsService _contactsService;
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isLoading = true;
  String? _error;
  Contact? _contact;

  @override
  void initState() {
    super.initState();
    _contactsService = locator<ContactsService>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await _contactsService.getContact(widget.contactId);
    if (res.isSuccess) {
      _contact = res.value;
      _firstNameCtrl.text = _contact!.firstName;
      _lastNameCtrl.text = _contact!.lastName;
      _emailCtrl.text = _contact!.email ?? '';
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _error = res.error.message);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _contact == null) return;
    setState(() => _isLoading = true);
    final updated = Contact(
      id: _contact!.id,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
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
    if (res.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() { _error = res.error.message; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading contact...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Contact')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'First name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter first name' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Last name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter last name' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 20),
            if (_isLoading) const LoadingView(message: 'Saving contact...') else ElevatedButton(onPressed: _save, child: const Text('Save'))
          ]),
        ),
      ),
    );
  }
}
