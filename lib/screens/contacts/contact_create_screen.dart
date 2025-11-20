import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/contacts_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class ContactCreateScreen extends StatefulWidget {
  const ContactCreateScreen({super.key});

  @override
  State<ContactCreateScreen> createState() => _ContactCreateScreenState();
}

class _ContactCreateScreenState extends State<ContactCreateScreen> {
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
    setState(() => _isLoading = true);
    final contact = Contact(
      id: '',
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      organizationId: locator<AuthService>().selectedOrganizationId ?? '',
    );
    final res = await _contactsService.createContact(contact);
    if (res.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isLoading = false;
      _error = res.error.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Contact')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_error != null) ErrorView(message: _error!, onRetry: null),
              TextFormField(
                controller: _firstNameCtrl,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter first name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _lastNameCtrl,
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter last name' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 20),
              if (_isLoading) const LoadingView(message: 'Creating contact...')
              else ElevatedButton(onPressed: _createContact, child: const Text('Create'))
            ],
          ),
        ),
      ),
    );
  }
}
