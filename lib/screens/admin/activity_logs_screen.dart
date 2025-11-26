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
  String? _selectedEntityType;
  String? _selectedUserId;
  String? _selectedEntityId;
  String? _search;
  int _filterVersion = 0;
  List<User>? _users;

  Future<List<ActivityLog>> _fetchPage(int page, int limit) async {
    if (!_apiAvailable) throw Exception('Activity logs API not available on server');
    final res = await _activityLogService.getActivityLogs(page: page, limit: limit, entityType: _selectedEntityType, entityId: _selectedEntityId, userId: _selectedUserId, search: _search);
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
    final args = ModalRoute.of(context)?.settings.arguments as ActivityLogsArgs?;
    if (args != null) {
      setState(() {
        _selectedEntityType = args.entityType;
        _selectedEntityId = args.entityId;
        _selectedUserId = args.userId;
        _search = args.search;
        _filterVersion++;
      });
    }
  }

  Future<void> _checkApiAvailability() async {
    if (!locator<AuthService>().isLoggedIn || !locator<AuthService>().hasSelectedOrganization) return;
    final res = await _activityLogService.getActivityLogs(page: 1, limit: 1);
    if (res.isError && res.error is HttpError && (res.error as HttpError).statusCode == 404) {
      setState(() => _apiAvailable = false);
    }
  }

  Future<void> _loadUsers() async {
    if (!locator<AuthService>().isLoggedIn || !locator<AuthService>().hasSelectedOrganization) return;
    final res = await _usersService.getUsers(limit: 200);
    if (res.isSuccess) {
      setState(() => _users = res.value.users);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (locator<AuthService>().isLoggedIn && !locator<AuthService>().hasSelectedOrganization) {
      return Scaffold(body: ErrorView(message: 'No organization selected. Please select a company to continue.', onRetry: () => AppRouter.navigateTo(context, AppRouter.companySelection)));
    }
    // Only Admins can access activity logs -> wrap screen with AdminOnly fallback
    if (!locator<AuthService>().isAdmin) return const AccessDeniedRedirectScreen();
    final userItems = <DropdownMenuItem<String?>>[DropdownMenuItem<String?>(value: null, child: Text('All'))];
    final users = _users ?? [];
    userItems.addAll(users.map((u) => DropdownMenuItem<String?>(value: u.id, child: Text(u.name))).toList());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity Logs'),
        actions: [
          IconButton(onPressed: () => setState(() => _filterVersion++), icon: const Icon(Icons.refresh), tooltip: 'Refresh logs'),
          IconButton(onPressed: _loadUsers, icon: const Icon(Icons.person_search), tooltip: 'Reload users')
        ],
      ),
        body: _apiAvailable
          ? Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _selectedEntityType,
                          decoration: const InputDecoration(labelText: 'Entity Type'),
                          items: const [
                            DropdownMenuItem(value: null, child: Text('All')),
                            DropdownMenuItem(value: 'Account', child: Text('Account')),
                            DropdownMenuItem(value: 'Contact', child: Text('Contact')),
                            DropdownMenuItem(value: 'Lead', child: Text('Lead')),
                            DropdownMenuItem(value: 'Ticket', child: Text('Ticket')),
                            DropdownMenuItem(value: 'Task', child: Text('Task')),
                          ],
                          onChanged: (v) => setState(() => _selectedEntityType = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String?>(
                          value: _selectedUserId,
                          decoration: const InputDecoration(labelText: 'User'),
                          items: userItems,
                          onChanged: (v) => setState(() => _selectedUserId = v),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 150,
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Entity ID'),
                          onChanged: (v) => _selectedEntityId = v.isNotEmpty ? v : null,
                          onSubmitted: (v) => setState(() => _filterVersion++),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: 'Search'),
                          onChanged: (v) => _search = v,
                          onSubmitted: (v) => setState(() => _filterVersion++),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(onPressed: () => setState(() => _filterVersion++), child: const Text('Apply')),
                      const SizedBox(width: 8),
                      TextButton(onPressed: () => setState(() { _selectedEntityType = null; _selectedUserId = null; _search = null; _filterVersion++; }), child: const Text('Clear')),
                    ],
                  ),
                ),
                Expanded(
                  child: PaginatedListView<ActivityLog>(
                    key: ValueKey(_filterVersion),
                    fetchPage: _fetchPage,
                    pageSize: 20,
                    emptyMessage: 'No activity logs',
                    errorMessage: 'Failed to load activity logs',
                    loadingMessage: 'Loading activity logs...',
                    itemBuilder: (context, log, index) => ListTile(
                      title: Text(log.summary),
                      subtitle: Text('${log.entityType ?? '-'} ${log.createdAt.toLocal()}'),
                      onTap: () => _showLogDetails(context, log),
                    ),
                  ),
                )
              ],
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Activity Logs feature is not available on the server'),
                )
            ),
      
    );
  }

  void _showLogDetails(BuildContext context, ActivityLog log) {
    showDialog(
      context: context,
      builder: (ctx) => ActivityLogDetailDialog(activityLog: log),
    );
  }
}
