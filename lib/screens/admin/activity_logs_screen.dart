import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/activity_log.dart';
import '../../models/user.dart';
import '../../services/activity_log_service.dart';
import '../../services/users_service.dart';
import '../../services/service_locator.dart';
import '../../services/api/api_exceptions.dart';
import '../../services/auth/auth_service.dart';
import '../../navigation/app_router.dart';
import '../../widgets/error_view.dart';
import '../../screens/access_denied_redirect_screen.dart';
import '../../widgets/activity_log_detail_dialog.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  late final ActivityLogService _activityLogService;
  late final UsersService _usersService;
  bool _apiAvailable = true;

  // Filter states
  String? _selectedEntityType;
  String? _selectedUserId;
  String? _selectedEntityId;
  String? _search;
  int _filterVersion = 0;

  // Data states
  List<User>? _users;
  final Set<String> _fetchedUserIds = {};

  // ===== LOGIC GIỮ NGUYÊN =====
  Future<List<ActivityLog>> _fetchPage(int page, int limit) async {
    if (!_apiAvailable) {
      throw Exception('Activity logs API not available on server');
    }
    final res = await _activityLogService.getActivityLogs(
      page: page,
      limit: limit,
      entityType: _selectedEntityType,
      entityId: _selectedEntityId,
      userId: _selectedUserId,
      search: _search,
    );
    if (res.isSuccess) return res.value.logs;
    throw Exception(res.error.message);
  }

  @override
  void initState() {
    super.initState();
    _activityLogService = locator<ActivityLogService>();
    _usersService = locator<UsersService>();
    _checkApiAvailability();
    _loadUsers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as ActivityLogsArgs?;
    if (args != null) {
      setState(() {
        _selectedEntityType = args.entityType;
        _selectedEntityId = args.entityId;
        _selectedUserId = args.userId;
        _search = args.search;
        _filterVersion++;
      });
      _ensureSelectedUserLoaded();
    }
  }

  Future<void> _checkApiAvailability() async {
    if (!locator<AuthService>().isLoggedIn ||
        !locator<AuthService>().hasSelectedOrganization) return;

    final res = await _activityLogService.getActivityLogs(page: 1, limit: 1);
    if (res.isError &&
        res.error is HttpError &&
        (res.error as HttpError).statusCode == 404) {
      setState(() => _apiAvailable = false);
    }
  }

  Future<void> _loadUsers() async {
    if (!locator<AuthService>().isLoggedIn ||
        !locator<AuthService>().hasSelectedOrganization) return;

    final res = await _usersService.getUsers(limit: 200);
    if (res.isSuccess) {
      final loaded = res.value.users;
      setState(() => _users = loaded);

      if (_selectedUserId != null &&
          !_users!.any((u) => u.id == _selectedUserId!)) {
        await _ensureSelectedUserLoaded();
      }
    }
  }

  Future<void> _ensureSelectedUserLoaded() async {
    if (_selectedUserId == null) return;
    if (_users != null && _users!.any((u) => u.id == _selectedUserId!)) return;
    if (_fetchedUserIds.contains(_selectedUserId)) return;
    _fetchedUserIds.add(_selectedUserId!);

    try {
      final resp = await _usersService.getUser(_selectedUserId!);
      if (resp.isSuccess) {
        setState(() {
          final list = List<User>.from(_users ?? []);
          if (!list.any((u) => u.id == resp.value.id)) {
            list.add(resp.value);
          }
          _users = list;
        });
      } else {
        _addPlaceholderUser();
      }
    } catch (_) {
      _addPlaceholderUser();
    }
  }

  void _addPlaceholderUser() {
    setState(() {
      final list = List<User>.from(_users ?? []);
      final placeholder =
          User(id: _selectedUserId!, email: '', name: _selectedUserId!);
      if (!list.any((u) => u.id == placeholder.id)) list.add(placeholder);
      _users = list;
    });
  }

  void _showLogDetails(BuildContext context, ActivityLog log) {
    showDialog(
      context: context,
      builder: (ctx) => ActivityLogDetailDialog(activityLog: log),
    );
  }

  // ===== UI BUILD =====
  @override
  Widget build(BuildContext context) {
    final auth = locator<AuthService>();
    if (auth.isLoggedIn && !auth.hasSelectedOrganization) {
      return Scaffold(
        body: ErrorView(
          message:
              'No organization selected. Please select a company to continue.',
          onRetry: () => AppRouter.navigateTo(
            context,
            AppRouter.companySelection,
          ),
        ),
      );
    }

    if (!auth.isAdmin) return const AccessDeniedRedirectScreen();

    final colorScheme = Theme.of(context).colorScheme;
    const bgColor = Color(0xFFE9EDF5);

    // Prepare dropdown items
    final userItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(value: null, child: Text('All users'))
    ];
    final users = _users ?? [];
    userItems.addAll(
      users
          .map((u) => DropdownMenuItem<String?>(
              value: u.id, child: Text(u.name)))
          .toList(),
    );
    // Ensure selected value exists in items
    final dropdownSelectedUserId = (_selectedUserId != null &&
            userItems.any((it) => it.value == _selectedUserId))
        ? _selectedUserId
        : null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Text(''), // Empty title, custom header in body
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        actions: [
          IconButton(
            tooltip: 'Reload users',
            onPressed: _loadUsers,
            icon: const Icon(Icons.person_search_outlined),
          ),
          IconButton(
            tooltip: 'Refresh logs',
            onPressed: () => setState(() => _filterVersion++),
            icon: const Icon(Icons.refresh_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: _apiAvailable
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== HEADER ROW =====
                      Row(
                        children: [
                          Text(
                            'Activity Logs',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
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
                              'Admin',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ===== FILTER BAR (Row Layout) =====
                      Row(
                        children: [
                          // Entity Type
                          SizedBox(
                            width: 180,
                            child: _buildEntityTypeDropdown(colorScheme),
                          ),
                          const SizedBox(width: 12),
                          // User
                          SizedBox(
                            width: 200,
                            child: DropdownButtonFormField<String?>(
                              value: dropdownSelectedUserId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'User',
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                filled: true,
                                fillColor: colorScheme.surface,
                              ),
                              items: userItems,
                              onChanged: (v) =>
                                  setState(() => _selectedUserId = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Search (Entity ID or Detail)
                          Expanded(
                            child: TextField(
                              controller: TextEditingController(text: _search),
                              decoration: InputDecoration(
                                labelText: 'Search or Entity ID',
                                hintText: 'Search summary or enter ID...',
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
                              onChanged: (v) {
                                _search = v.trim();
                                // Reset Entity ID if user is typing a generic search
                                if (_search!.length < 10) {
                                   _selectedEntityId = null; 
                                } else {
                                   // Optional: Auto detect ID
                                   // _selectedEntityId = _search; 
                                }
                              },
                              onSubmitted: (_) =>
                                  setState(() => _filterVersion++),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Action Buttons
                          IconButton.filledTonal(
                             onPressed: () {
                                setState(() {
                                  _selectedEntityType = null;
                                  _selectedUserId = null;
                                  _selectedEntityId = null;
                                  _search = null;
                                  _filterVersion++;
                                });
                             }, 
                             tooltip: 'Clear filters',
                             icon: const Icon(Icons.filter_alt_off),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: () => setState(() => _filterVersion++),
                            child: const Text('Apply'),
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
                                  color: colorScheme.surfaceVariant
                                      .withOpacity(0.2),
                                ),
                                child: Row(
                                  children: [
                                    const SizedBox(width: 40), // Icon space
                                    _headerCell(context, 'Summary', flex: 4),
                                    _headerCell(context, 'Entity', flex: 2),
                                    _headerCell(context, 'User', flex: 2),
                                    _headerCell(context, 'Time',
                                        flex: 2, align: TextAlign.right),
                                  ],
                                ),
                              ),
                              const Divider(height: 1),

                              // TABLE BODY
                              Expanded(
                                child: PaginatedListView<ActivityLog>(
                                  key: ValueKey(_filterVersion),
                                  fetchPage: _fetchPage,
                                  pageSize: 20,
                                  emptyMessage: 'No activity logs found',
                                  errorMessage: 'Failed to load logs',
                                  loadingMessage: 'Loading logs...',
                                  itemBuilder: (context, log, index) {
                                    return _ActivityLogRow(
                                      log: log,
                                      onTap: () =>
                                          _showLogDetails(context, log),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link_off,
                            size: 48, color: colorScheme.outline),
                        const SizedBox(height: 16),
                        Text(
                          'Activity Logs feature is not available on this server.',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  // Widget helper cho Dropdown Entity Type
  Widget _buildEntityTypeDropdown(ColorScheme colorScheme) {
    final items = <DropdownMenuItem<String?>>[
      const DropdownMenuItem(value: null, child: Text('All Entities')),
      const DropdownMenuItem(value: 'Account', child: Text('Account')),
      const DropdownMenuItem(value: 'Contact', child: Text('Contact')),
      const DropdownMenuItem(value: 'Lead', child: Text('Lead')),
      const DropdownMenuItem(value: 'Ticket', child: Text('Ticket')),
      const DropdownMenuItem(value: 'Task', child: Text('Task')),
    ];
    // Add current selected if not in list (edge case)
    if (_selectedEntityType != null &&
        !items.any((it) => it.value == _selectedEntityType)) {
      items.add(DropdownMenuItem(
        value: _selectedEntityType,
        child: Text(_selectedEntityType!),
      ));
    }
    // Safe selected value
    final dropdownVal = (_selectedEntityType != null &&
            items.any((it) => it.value == _selectedEntityType))
        ? _selectedEntityType
        : null;

    return DropdownButtonFormField<String?>(
      value: dropdownVal,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: 'Entity Type',
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
        ),
        filled: true,
        fillColor: colorScheme.surface,
      ),
      items: items,
      onChanged: (v) => setState(() => _selectedEntityType = v),
    );
  }

  // Helper cho Header Cell
  Widget _headerCell(BuildContext context, String label,
      {int flex = 1, TextAlign align = TextAlign.left}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

// ===== TABLE ROW WIDGET =====
class _ActivityLogRow extends StatelessWidget {
  const _ActivityLogRow({
    required this.log,
    required this.onTap,
  });

  final ActivityLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Data formatting
    final entityLabel =
        (log.entityName != null && log.entityName!.isNotEmpty)
            ? log.entityName!
            : (log.entityType ?? '-');
    final userLabel = log.userName ?? 'Unknown';
    // Format time đơn giản
    final dt = log.createdAt.toLocal();
    final timeLabel =
        "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colorScheme.outline.withOpacity(0.06),
            ),
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.history_edu,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),

            // Summary
            Expanded(
              flex: 4,
              child: Text(
                log.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),

            // Entity Type / Name
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (log.entityType != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.entityType!,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.secondary,
                        ),
                      ),
                    ),
                  if (log.entityType != null) const SizedBox(height: 2),
                  Text(
                    entityLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),

            // User
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: colorScheme.surfaceVariant,
                    child: Text(
                      userLabel.isNotEmpty ? userLabel[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 10,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      userLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            // Time
            Expanded(
              flex: 2,
              child: Text(
                timeLabel,
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