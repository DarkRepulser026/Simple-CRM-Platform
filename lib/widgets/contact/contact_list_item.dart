import 'package:flutter/material.dart';

import '../../widgets/paginated_list_view.dart';
import '../../widgets/layout/main_layout.dart';
import '../../models/contact.dart';
import '../../navigation/app_router.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  _ContactFilter _filter = _ContactFilter.all;

  Future<List<Contact>> _fetchContactsPage(int page, int limit) async {
    // TODO: gọi ContactsService + _searchQuery + _filter
    await Future.delayed(const Duration(milliseconds: 500));

    final all = List.generate(
      limit,
      (index) => Contact(
        id: 'contact_${page}_${index}',
        firstName: 'Contact',
        lastName: '${(page - 1) * limit + index + 1}',
        organizationId: 'org123',
        createdAt: DateTime.now().subtract(Duration(days: index)),
        updatedAt: DateTime.now().subtract(Duration(hours: index)),
        email:
            index.isEven ? 'contact${(page - 1) * limit + index + 1}@example.com' : null,
        phone: index.isOdd
            ? '+1-555-01${((page - 1) * limit + index + 1).toString().padLeft(4, '0')}'
            : null,
      ),
    );

    Iterable<Contact> result = all;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((c) {
        final name = _displayName(c).toLowerCase();
        final email = (c.email ?? '').toLowerCase();
        final phone = (c.phone ?? '').toLowerCase();
        return name.contains(q) || email.contains(q) || phone.contains(q);
      });
    }

    switch (_filter) {
      case _ContactFilter.all:
        break;
      case _ContactFilter.hasEmail:
        result = result.where((c) => (c.email ?? '').isNotEmpty);
        break;
      case _ContactFilter.hasPhone:
        result = result.where((c) => (c.phone ?? '').isNotEmpty);
        break;
    }

    return result.toList();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value.trim();
    });
  }

  void _onFilterChanged(_ContactFilter? newFilter) {
    if (newFilter == null) return;
    setState(() {
      _filter = newFilter;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Contacts',
      selectedMenu: 'contacts',
      actions: [
        IconButton(
          onPressed: () =>
              AppRouter.navigateTo(context, AppRouter.contactCreate),
          icon: const Icon(Icons.add),
          tooltip: 'Add Contact',
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          final horizontalPadding = isWide ? 32.0 : 16.0;

          return Padding(
            padding: EdgeInsets.fromLTRB(
              horizontalPadding,
              16,
              horizontalPadding,
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: 16),
                _buildSearchAndFilter(context),
                const SizedBox(height: 16),
                _buildTableHeader(context),
                const SizedBox(height: 4),
                Expanded(
                  child: PaginatedListView<Contact>(
                    fetchPage: _fetchContactsPage,
                    pageSize: 20,
                    emptyMessage: 'No contacts found',
                    errorMessage: 'Failed to load contacts',
                    loadingMessage: 'Loading contacts...',
                    itemBuilder: (context, contact, index) => _ContactRow(
                      contact: contact,
                      onTap: () => _navigateToContactDetail(contact.id),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contacts',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Manage your customers and leads in one place.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () =>
              AppRouter.navigateTo(context, AppRouter.contactCreate),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('New contact'),
        ),
      ],
    );
  }

  Widget _buildSearchAndFilter(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Search by name, email or phone...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 0,
                  ),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.3),
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<_ContactFilter>(
                  value: _filter,
                  borderRadius: BorderRadius.circular(12),
                  items: const [
                    DropdownMenuItem(
                      value: _ContactFilter.all,
                      child: Text('All'),
                    ),
                    DropdownMenuItem(
                      value: _ContactFilter.hasEmail,
                      child: Text('Has email'),
                    ),
                    DropdownMenuItem(
                      value: _ContactFilter.hasPhone,
                      child: Text('Has phone'),
                    ),
                  ],
                  onChanged: _onFilterChanged,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              const SizedBox(width: 52),
              Expanded(
                flex: 3,
                child: Text(
                  'Name',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  'Email',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Phone',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Created',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 24),
            ],
          ),
        ),
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

  String _displayName(Contact contact) {
    try {
      if ((contact.fullName).trim().isNotEmpty) return contact.fullName;
    } catch (_) {}
    final fn = (contact.firstName ?? '').trim();
    final ln = (contact.lastName ?? '').trim();
    final combined = '$fn $ln'.trim();
    return combined.isEmpty ? 'Unnamed contact' : combined;
  }
}

enum _ContactFilter { all, hasEmail, hasPhone }

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.onTap,
  });

  final Contact contact;
  final VoidCallback onTap;

  String _displayName() {
    try {
      if ((contact.fullName).trim().isNotEmpty) return contact.fullName;
    } catch (_) {}
    final fn = (contact.firstName ?? '').trim();
    final ln = (contact.lastName ?? '').trim();
    final combined = '$fn $ln'.trim();
    return combined.isEmpty ? 'Unnamed contact' : combined;
  }

  String _initials() {
    final name = _displayName();
    final parts = name.split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _createdLabel() {
    final created = contact.createdAt;
    if (created == null) return '';
    final d = created.toLocal();
    final y = d.year;
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createdLabel = _createdLabel();

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.08),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withOpacity(0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor:
                      theme.colorScheme.primary.withOpacity(0.12),
                  child: Text(
                    _initials(),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: Text(
                    _displayName(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    contact.email ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    contact.phone ?? '—',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (createdLabel.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceVariant
                                .withOpacity(0.7),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            createdLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color:
                                  theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ContactDetailArgs {
  final String contactId;

  const ContactDetailArgs({required this.contactId});

  @override
  String toString() => 'ContactDetailArgs(contactId: $contactId)';
}
