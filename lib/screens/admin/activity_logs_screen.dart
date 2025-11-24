import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/activity_log.dart';
import '../../services/activity_log_service.dart';
import '../../services/service_locator.dart';
import '../../services/api/api_exceptions.dart';
import '../../services/auth/auth_service.dart';
import '../../navigation/app_router.dart';
import '../../widgets/error_view.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  late final ActivityLogService _activityLogService;
  bool _apiAvailable = true;

  Future<List<ActivityLog>> _fetchPage(int page, int limit) async {
    if (!_apiAvailable) throw Exception('Activity logs API not available on server');
    final res = await _activityLogService.getActivityLogs(page: page, limit: limit);
    if (res.isSuccess) return res.value.logs;
    throw Exception(res.error.message);
  }

  @override
  void initState() {
    super.initState();
    _activityLogService = locator<ActivityLogService>();
    _checkApiAvailability();
  }

  Future<void> _checkApiAvailability() async {
    if (!locator<AuthService>().isLoggedIn || !locator<AuthService>().hasSelectedOrganization) return;
    final res = await _activityLogService.getActivityLogs(page: 1, limit: 1);
    if (res.isError && res.error is HttpError && (res.error as HttpError).statusCode == 404) {
      setState(() => _apiAvailable = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (locator<AuthService>().isLoggedIn && !locator<AuthService>().hasSelectedOrganization) {
      return Scaffold(body: ErrorView(message: 'No organization selected. Please select a company to continue.', onRetry: () => AppRouter.navigateTo(context, AppRouter.companySelection)));
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Logs')),
        body: _apiAvailable
          ? PaginatedListView<ActivityLog>(
              fetchPage: _fetchPage,
              pageSize: 20,
              emptyMessage: 'No activity logs',
              errorMessage: 'Failed to load activity logs',
              loadingMessage: 'Loading activity logs...',
              
              itemBuilder: (context, log, index) => ListTile(
                title: Text(log.summary),
                subtitle: Text('${log.entityType ?? '-'} ${log.createdAt.toLocal()}'),
              ),
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Activity Logs feature is not available on the server'),
                )
            ),
      
    );
  }
}
