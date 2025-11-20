import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/activity_log.dart';
import '../../services/activity_log_service.dart';
import '../../services/service_locator.dart';

class ActivityLogsScreen extends StatefulWidget {
  const ActivityLogsScreen({super.key});

  @override
  State<ActivityLogsScreen> createState() => _ActivityLogsScreenState();
}

class _ActivityLogsScreenState extends State<ActivityLogsScreen> {
  late final ActivityLogService _activityLogService;

  Future<List<ActivityLog>> _fetchPage(int page, int limit) async {
    final res = await _activityLogService.getActivityLogs(page: page, limit: limit);
    if (res.isSuccess) return res.value.logs;
    throw Exception(res.error.message);
  }

  @override
  void initState() {
    super.initState();
    _activityLogService = locator<ActivityLogService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity Logs')),
      body: PaginatedListView<ActivityLog>(
        fetchPage: _fetchPage,
        pageSize: 20,
        emptyMessage: 'No activity logs',
        errorMessage: 'Failed to load activity logs',
        loadingMessage: 'Loading activity logs...',
        itemBuilder: (context, log, index) => ListTile(
          title: Text(log.summary),
          subtitle: Text('${log.entityType ?? '-'} ${log.createdAt.toLocal()}'),
        ),
      ),
    );
  }
}
