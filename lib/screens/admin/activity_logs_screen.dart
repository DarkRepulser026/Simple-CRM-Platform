import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/activity_log.dart';
import '../../models/user.dart';
import '../../models/pagination.dart';
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
  String? _selectedActivityType;
  String? _selectedUserId;
  String? _search;
  DateTime? _startDate;
  DateTime? _endDate;
  int _filterVersion = 0;

  // Data states
  List<User>? _users;
  final Set<String> _fetchedUserIds = {};

  // ===== LOGIC GIỮ NGUYÊN =====
  Future<PaginatedResponse<ActivityLog>> _fetchPaginatedLogs(int page, int limit) async {
    if (!_apiAvailable) {
      throw Exception('Activity logs API not available on server');
    }
    final res = await _activityLogService.getActivityLogs(
      page: page,
      limit: limit,
      entityType: _selectedEntityType,
      userId: _selectedUserId,
      search: _search,
    );
    if (res.isSuccess) {
      final pagination = res.value.pagination ?? Pagination(page: page, limit: limit, total: res.value.logs.length, totalPages: 1, hasNext: false, hasPrev: false);
      return PaginatedResponse<ActivityLog>(items: res.value.logs, pagination: pagination);
    }
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
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: const Text('Activity Logs'),
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
          constraints: const BoxConstraints(maxWidth: 1400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: _apiAvailable
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ===== FILTERS CARD =====
                      Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.12),
                          ),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Filters',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                // Entity Type
                                SizedBox(
                                  width: 150,
                                  child: _buildEntityTypeDropdown(colorScheme),
                                ),
                                // Activity Type Filter
                                SizedBox(
                                  width: 160,
                                  child: DropdownButtonFormField<String?>(
                                    value: _selectedActivityType,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'Activity Type',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      isDense: true,
                                    ),
                                    items: [
                                      const DropdownMenuItem<String?>(
                                          value: null, child: Text('All')),
                                      const DropdownMenuItem(
                                          value: 'Created',
                                          child: Text('Created')),
                                      const DropdownMenuItem(
                                          value: 'Updated',
                                          child: Text('Updated')),
                                      const DropdownMenuItem(
                                          value: 'Deleted',
                                          child: Text('Deleted')),
                                      const DropdownMenuItem(
                                          value: 'Login', child: Text('Login')),
                                      const DropdownMenuItem(
                                          value: 'Logout',
                                          child: Text('Logout')),
                                    ],
                                    onChanged: (v) => setState(
                                        () => _selectedActivityType = v),
                                  ),
                                ),
                                // User
                                SizedBox(
                                  width: 160,
                                  child: DropdownButtonFormField<String?>(
                                    value: dropdownSelectedUserId,
                                    isExpanded: true,
                                    decoration: InputDecoration(
                                      labelText: 'User',
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      isDense: true,
                                    ),
                                    items: userItems,
                                    onChanged: (v) => setState(
                                        () => _selectedUserId = v),
                                  ),
                                ),
                                // Date Range - Start
                                SizedBox(
                                  width: 160,
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _startDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        setState(() => _startDate = picked);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'From Date',
                                        hintText: 'Select start date',
                                        prefixIcon: const Icon(
                                            Icons.calendar_today,
                                            size: 18),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 12),
                                      ),
                                      child: Text(
                                        _startDate != null
                                            ? '${_startDate!.year}-${_startDate!.month.toString().padLeft(2, '0')}-${_startDate!.day.toString().padLeft(2, '0')}'
                                            : 'Any',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ),
                                ),
                                // Date Range - End
                                SizedBox(
                                  width: 160,
                                  child: InkWell(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: _endDate ?? DateTime.now(),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime.now(),
                                      );
                                      if (picked != null) {
                                        setState(() => _endDate = picked);
                                      }
                                    },
                                    child: InputDecorator(
                                      decoration: InputDecoration(
                                        labelText: 'To Date',
                                        hintText: 'Select end date',
                                        prefixIcon: const Icon(
                                            Icons.calendar_today,
                                            size: 18),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 8, horizontal: 12),
                                      ),
                                      child: Text(
                                        _endDate != null
                                            ? '${_endDate!.year}-${_endDate!.month.toString().padLeft(2, '0')}-${_endDate!.day.toString().padLeft(2, '0')}'
                                            : 'Any',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ),
                                  ),
                                ),
                                // Search
                                SizedBox(
                                  width: 220,
                                  child: TextField(
                                    controller: TextEditingController(
                                        text: _search),
                                    decoration: InputDecoration(
                                      labelText: 'Search',
                                      hintText: 'Description or entity name...',
                                      prefixIcon: const Icon(Icons.search,
                                          size: 20),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(8),
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              vertical: 8, horizontal: 12),
                                    ),
                                    onChanged: (v) {
                                      _search = v.trim();
                                    },
                                    onSubmitted: (_) => setState(
                                        () => _filterVersion++),
                                  ),
                                ),
                                // Action Buttons
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton.filledTonal(
                                      onPressed: () {
                                        setState(() {
                                          _selectedEntityType = null;
                                          _selectedActivityType = null;
                                          _selectedUserId = null;
                                          _search = null;
                                          _startDate = null;
                                          _endDate = null;
                                          _filterVersion++;
                                        });
                                      },
                                      tooltip: 'Clear filters',
                                      icon: const Icon(Icons.filter_alt_off),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton.icon(
                                      onPressed: () =>
                                          setState(() => _filterVersion++),
                                      icon: const Icon(Icons.search, size: 18),
                                      label: const Text('Search'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ===== LOGS LIST CARD =====
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colorScheme.outline.withOpacity(0.12),
                            ),
                          ),
                          child: PaginatedListView<ActivityLog>(
                            key: ValueKey(_filterVersion),
                            fetchPaginated: _fetchPaginatedLogs,
                            pageSize: 10,
                            emptyMessage: 'No activity logs found',
                            errorMessage: 'Failed to load logs',
                            loadingMessage: 'Loading logs...',
                            itemBuilder: (context, log, index) {
                              return _ActivityLogRow(
                                log: log,
                                onTap: () => _showLogDetails(context, log),
                              );
                            },
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
      const DropdownMenuItem(value: 'User', child: Text('User')),
      const DropdownMenuItem(value: 'UserOrganization', child: Text('User Role')),
      const DropdownMenuItem(value: 'UserRole', child: Text('Custom Role')),
      const DropdownMenuItem(value: 'Contact', child: Text('Contact')),
      const DropdownMenuItem(value: 'Account', child: Text('Account')),
      const DropdownMenuItem(value: 'Lead', child: Text('Lead')),
      const DropdownMenuItem(value: 'Ticket', child: Text('Ticket')),
      const DropdownMenuItem(value: 'Task', child: Text('Task')),
      const DropdownMenuItem(value: 'Invitation', child: Text('Invitation')),
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
          borderRadius: BorderRadius.circular(8),
        ),
        isDense: true,
      ),
      items: items,
      onChanged: (v) => setState(() => _selectedEntityType = v),
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: colorScheme.outline.withOpacity(0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Icon + Main Description + Time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.history_edu,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Description & Entity
                  Expanded(
                    child: Text(
                      log.description.isNotEmpty
                          ? log.description
                          : log.summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Time
                  Text(
                    timeLabel,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                  ),
                ],
              ),

              // Meta Info Row: Entity Type + Entity Name + User
              const SizedBox(height: 12),
              Row(
                children: [
                  // Entity Info Section
                  if (log.entityType != null) ...[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Resource',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                  fontSize: 10,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: colorScheme.secondary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    log.entityType!.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      log.entityType!,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: colorScheme.secondary,
                                          ),
                                    ),
                                    Text(
                                      entityLabel,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                            fontSize: 9,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],

                  // User Info Section
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'By',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                fontSize: 10,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: colorScheme.tertiary.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  userLabel.isNotEmpty ? userLabel[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.tertiary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                userLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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