import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/pagination.dart';
import '../../services/auth/auth_service.dart';
import '../../navigation/app_router.dart';
import 'contact_detail_screen.dart';
import '../../models/contact.dart';
import '../../widgets/error_view.dart';
import '../../services/contacts_service.dart';
import '../../services/users_service.dart';
import '../../models/user.dart';
import '../../services/service_locator.dart';

/// List screen for displaying and managing contacts with pagination
class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  late final ContactsService _contactsService;
  late final UsersService _usersService;
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _departmentCtrl = TextEditingController();
  String? _selectedOwnerId;
  int _reloadVersion = 0; // Dùng để ép reload list khi search/filter
  List<User>? _users;

  // server paginated fetch is done inline via fetchPaginated param in the PaginatedListView

  @override
  void initState() {
    super.initState();
    _contactsService = locator<ContactsService>();
    _usersService = locator<UsersService>();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final res = await _usersService.getUsers(limit: 200);
    if (res.isSuccess) {
      setState(() {
        _users = res.value.users;
      });
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _cityCtrl.dispose();
    _departmentCtrl.dispose();
    super.dispose();
  }

  void _refreshList() {
    setState(() => _reloadVersion++);
  }

  @override
  Widget build(BuildContext context) {
    final auth = locator<AuthService>();
    if (auth.isLoggedIn && !auth.hasSelectedOrganization) {
      return Scaffold(
        body: ErrorView(
          message:
              'No organization selected. Please select a company to continue.',
          onRetry: () =>
              AppRouter.navigateTo(context, AppRouter.companySelection),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;
    const bgColor = Color(0xFFE9EDF5); // Màu nền chuẩn Dashboard

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: bgColor,
        centerTitle: false,
        titleSpacing: 0,
        title: const Text(''),
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          IconButton(
             tooltip: 'Refresh',
             onPressed: _refreshList,
             icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ===== HEADER ROW =====
                Row(
                  children: [
                    Text(
                      'Contacts',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'CRM',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== FILTER / ACTION BAR =====
                Row(
                  children: [
                    // Search Field
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search by name, email or phone',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: colorScheme.surface.withOpacity(0.9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 12,
                          ),
                        ),
                        onSubmitted: (_) => _refreshList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 160,
                      child: DropdownButtonFormField<String?>(
                        value: _selectedOwnerId,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Owner',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                          filled: true,
                          fillColor: colorScheme.surface,
                        ),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('Any owner')),
                          ...( _users ?? []).map((u) => DropdownMenuItem<String?>(value: u.id, child: Text(u.name))).toList()
                        ],
                        onChanged: (v) => setState(() => _selectedOwnerId = v),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: TextField(
                        controller: _cityCtrl,
                        decoration: InputDecoration(
                          labelText: 'City',
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                        onSubmitted: (_) => _refreshList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 160,
                      child: TextField(
                        controller: _departmentCtrl,
                        decoration: InputDecoration(
                          labelText: 'Department',
                          filled: true,
                          fillColor: colorScheme.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(999),
                            borderSide: BorderSide(
                              color: colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                        ),
                        onSubmitted: (_) => _refreshList(),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: () {
                        setState(() {
                          _selectedOwnerId = null;
                          _cityCtrl.clear();
                          _departmentCtrl.clear();
                          _searchCtrl.clear();
                          _refreshList();
                        });
                      },
                      tooltip: 'Clear filters',
                      icon: const Icon(Icons.filter_alt_off),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _refreshList,
                      child: const Text('Apply'),
                    ),
                    const SizedBox(width: 12),
                    // New Contact Button
                    FilledButton.icon(
                      onPressed: () async {
                        final created = await AppRouter.navigateTo<bool?>(
                          context,
                          AppRouter.contactCreate,
                        );
                        if (created == true) _refreshList();
                      },
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('New contact'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== MAIN TABLE CARD =====
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colorScheme.outline.withOpacity(0.08),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // TABLE HEADER
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            color: colorScheme.surfaceVariant.withOpacity(0.2),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 48), // Space for Avatar
                                _headerCell(context, 'Name', flex: 3),
                                _headerCell(context, 'Email', flex: 2),
                                _headerCell(context, 'Phone', flex: 2),
                                _headerCell(context, 'Department', flex: 2),
                                _headerCell(context, 'Owner', flex: 2),
                                _headerCell(context, 'Created',
                                  flex: 2, align: TextAlign.right),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // TABLE BODY (List)
                        Expanded(
                          child: PaginatedListView<Contact>(
                                      key: ValueKey(_reloadVersion),
                                      fetchPaginated: (page, limit) async {
                                        final res = await _contactsService.getContacts(
                                          page: page,
                                          limit: limit,
                                          search: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
                                          ownerId: _selectedOwnerId,
                                          city: _cityCtrl.text.isEmpty ? null : _cityCtrl.text,
                                          department: _departmentCtrl.text.isEmpty ? null : _departmentCtrl.text,
                                        );
                                        if (res.isError) throw Exception(res.error.message);
                                        final contactsResp = res.value;
                                        final pagination = contactsResp.pagination ?? Pagination(page: page, limit: limit, total: contactsResp.contacts.length, totalPages: 1, hasNext: false, hasPrev: false);
                                        return PaginatedResponse<Contact>(items: contactsResp.contacts, pagination: pagination);
                                      },
                                      pageSize: 9,
                                      emptyMessage: 'No contacts found',
                                      errorMessage: 'Failed to load contacts',
                                      loadingMessage: 'Loading contacts...',
                                    itemBuilder: (context, contact, index) => _ContactRow(contact: contact, onTap: () => _navigateToContactDetail(contact.id)),
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToContactDetail(String contactId) async {
    // Show the contact detail dialog directly. This ensures the dialog is presented
    // on top of all overlays and avoids navigator nesting issues from the list view.
    debugPrint('ContactsListScreen: navigate to contact detail: $contactId');
    final changed = await showContactDetailDialog(context, contactId: contactId);
    if (changed == true) _refreshList();
  }

  Widget _headerCell(BuildContext context, String label,
      {int flex = 3, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Một dòng contact trong bảng
class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.contact,
    required this.onTap,
  });

  final Contact contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Format ngày tạo
    final createdDt = contact.createdAt.toLocal();
    final createdStr = "${createdDt.year}-${createdDt.month.toString().padLeft(2, '0')}-${createdDt.day.toString().padLeft(2, '0')}";

    // Lấy ký tự đầu cho Avatar
    final initial = (contact.firstName.isNotEmpty
            ? contact.firstName[0]
            : (contact.fullName.isNotEmpty ? contact.fullName[0] : '?'))
        .toUpperCase();

    return InkWell(
      onTap: onTap,
      hoverColor: colorScheme.surfaceVariant.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withOpacity(0.06),
            ),
          ),
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: colorScheme.primary.withOpacity(0.12),
              child: Text(
                initial,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Name
            Expanded(
              flex: 3,
              child: Text(
                contact.fullName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),

            // Email
            Expanded(
              flex: 2,
              child: Text(
                contact.email ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),

            // Phone
            Expanded(
              flex: 2,
              child: Text(
                contact.phone ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),

            // Department
            Expanded(
              flex: 2,
              child: Text(
                contact.department ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),

            // Owner
            Expanded(
              flex: 2,
              child: Text(
                contact.owner?.name ?? '-',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),

            // Created Date
            Expanded(
              flex: 2,
              child: Text(
                createdStr,
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}