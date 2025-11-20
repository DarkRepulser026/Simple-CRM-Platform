import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/contact.dart';
import '../../navigation/app_router.dart';
import '../../services/contacts_service.dart';
import '../../services/service_locator.dart';

/// List screen for displaying and managing contacts with pagination
class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  late final ContactsService _contactsService;
  Future<List<Contact>> _fetchContactsPage(int page, int limit) async {
    try {
      final res = await _contactsService.getContacts(page: page, limit: limit);
      if (res.isSuccess) {
        return res.value.contacts;
      }
      throw Exception(res.error.message);
    } catch (e) {
      // Re-throw so PaginatedListView shows error state
      throw Exception('Failed to load contacts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        actions: [
          IconButton(
            onPressed: () => AppRouter.navigateTo(context, AppRouter.contactCreate),
            icon: const Icon(Icons.add),
            tooltip: 'Add Contact',
          ),
          IconButton(
            onPressed: () {
              // TODO: Implement search
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
            icon: const Icon(Icons.search),
            tooltip: 'Search Contacts',
          ),
        ],
      ),
      body: PaginatedListView<Contact>(
        itemBuilder: (context, contact, index) => ContactListItem(
          contact: contact,
          onTap: () => _navigateToContactDetail(contact.id),
        ),
        fetchPage: _fetchContactsPage,
        pageSize: 20,
        emptyMessage: 'No contacts found',
        errorMessage: 'Failed to load contacts',
        loadingMessage: 'Loading contacts...',
      ),
    );
  }

  void _navigateToContactDetail(String contactId) {
    AppRouter.navigateTo(
      context,
      AppRouter.contactDetail,
      arguments: ContactDetailArgs(contactId: contactId),
    );
  }

  @override
  void initState() {
    super.initState();
    _contactsService = locator<ContactsService>();
  }
}

/// Individual contact item in the list
class ContactListItem extends StatelessWidget {
  const ContactListItem({
    super.key,
    required this.contact,
    required this.onTap,
  });

  final Contact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            contact.firstName[0].toUpperCase(),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          contact.fullName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (contact.email != null) Text(contact.email!),
            if (contact.phone != null) Text(contact.phone!),
            Text(
              'Created ${contact.createdAt.toLocal().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}