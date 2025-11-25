import 'package:flutter/material.dart';
import '../../models/contact.dart';
import '../../services/service_locator.dart';
import '../../navigation/app_router.dart';
import '../../widgets/role_visibility.dart';
import 'contact_edit_screen.dart';
import '../../services/contacts_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class ContactDetailArgs {
  const ContactDetailArgs({required this.contactId});
  final String contactId;
}

class ContactDetailScreen extends StatefulWidget {
  final String contactId;
  const ContactDetailScreen({super.key, required this.contactId});

  @override
  State<ContactDetailScreen> createState() => _ContactDetailScreenState();
}

class _ContactDetailScreenState extends State<ContactDetailScreen> {
  late final ContactsService _contactsService;
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
    try {
      final res = await _contactsService.getContact(widget.contactId);
      if (res.isSuccess) {
        setState(() {
          _contact = res.value;
          _isLoading = false;
        });
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() {
        _error = 'Failed to load contact: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading contact...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    if (_contact == null) return const Scaffold(body: Center(child: Text('No contact data')));
    return Scaffold(
      appBar: AppBar(
        title: Text('${_contact!.fullName}'),
        actions: [
          ManagerOrAdminOnly(child: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => AppRouter.navigateTo(context, AppRouter.contactEdit, arguments: ContactEditArgs(contactId: _contact!.id)),
          )),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${_contact!.email ?? '-'}'),
            const SizedBox(height: 8),
            Text('Phone: ${_contact!.phone ?? '-'}'),
            const SizedBox(height: 8),
            Text('Address: ${_contact!.fullAddress}'),
          ],
        ),
      ),
    );
  }
}
