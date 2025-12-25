import 'package:flutter/material.dart';

import '../models/activity_log.dart';
import '../services/service_locator.dart';
import '../services/activity_log_service.dart';
import 'loading_view.dart';
import 'error_view.dart';

class ActivityLogWidget extends StatefulWidget {
  final String entityId;
  final String entityType;
  final int initialPage;
  final int pageSize;

  const ActivityLogWidget({
    super.key,
    required this.entityId,
    required this.entityType,
    this.initialPage = 1,
    this.pageSize = 20,
  });

  @override
  State<ActivityLogWidget> createState() => _ActivityLogWidgetState();
}

class _ActivityLogWidgetState extends State<ActivityLogWidget> {
  late final ActivityLogService _activityLogService;
  bool _isLoading = true;
  String? _error;
  List<ActivityLog> _activities = [];
  int _currentPage = 1;
  int _totalPages = 1;
  bool _hasNext = false;
  bool _hasPrev = false;
  int _totalActivities = 0;

  @override
  void initState() {
    super.initState();
    _activityLogService = locator<ActivityLogService>();
    _currentPage = widget.initialPage;
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _activityLogService.getActivityLogs(
        page: _currentPage,
        limit: widget.pageSize,
        entityType: widget.entityType,
        entityId: widget.entityId,
      );

      if (!mounted) return;

      if (res.isSuccess) {
        final data = res.value;
        setState(() {
          _activities = data.logs;
          _totalActivities = data.pagination?.total ?? 0;
          _totalPages = data.pagination?.totalPages ?? 1;
          _hasNext = data.pagination?.hasNext ?? false;
          _hasPrev = data.pagination?.hasPrev ?? false;
          _isLoading = false;
          _error = null;
        });
      } else {
        throw Exception(res.error.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load activity log: $e';
        _isLoading = false;
      });
    }
  }

  void _goToPage(int page) {
    _currentPage = page;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_isLoading) {
      return const Center(child: LoadingView(message: 'Loading activity log...'));
    }

    if (_error != null) {
      return Center(
        child: ErrorView(
          message: _error!,
          onRetry: _load,
        ),
      );
    }

    if (_activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: cs.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No activity yet',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Activity logs will appear here as changes are made',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: _activities.length,
            itemBuilder: (context, index) {
              return _buildActivityItem(context, _activities[index], theme, cs);
            },
          ),
        ),
        if (_totalPages > 1) ...[
          const SizedBox(height: 16),
          _buildPaginationControls(context, theme, cs),
        ],
      ],
    );
  }

  Widget _buildActivityItem(
    BuildContext context,
    ActivityLog activity,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(
          left: BorderSide(
            color: _getActivityColor(activity.activityType),
            width: 4,
          ),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getActivityIcon(activity.activityType),
                size: 20,
                color: _getActivityColor(activity.activityType),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  activity.activityType.value,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                _formatTimeAgo(activity.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            activity.description,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                'By: ${activity.userName ?? 'System'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                _formatDateTime(activity.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (activity.isUpdate && activity.oldValues != null && activity.newValues != null)
            _buildChangeDetails(context, activity, theme, cs),
        ],
      ),
    );
  }

  Widget _buildChangeDetails(
    BuildContext context,
    ActivityLog activity,
    ThemeData theme,
    ColorScheme cs,
  ) {
    final oldVals = activity.oldValues ?? {};
    final newVals = activity.newValues ?? {};
    final changedKeys = <String>{...oldVals.keys, ...newVals.keys};

    if (changedKeys.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: changedKeys.map((key) {
              final oldVal = oldVals[key];
              final newVal = newVals[key];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '$key: $oldVal → $newVal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: cs.onSurfaceVariant,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPaginationControls(
    BuildContext context,
    ThemeData theme,
    ColorScheme cs,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_hasPrev)
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: () => _goToPage(_currentPage - 1),
              tooltip: 'Previous page',
            )
          else
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: null,
              tooltip: 'No previous page',
            ),
          const SizedBox(width: 8),
          Text(
            'Page $_currentPage of $_totalPages',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(width: 8),
          Text(
            '($_totalActivities total)',
            style: theme.textTheme.bodySmall?.copyWith(
              color: cs.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          if (_hasNext)
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () => _goToPage(_currentPage + 1),
              tooltip: 'Next page',
            )
          else
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: null,
              tooltip: 'No next page',
            ),
        ],
      ),
    );
  }

  Color _getActivityColor(ActivityType type) {
    switch (type) {
      case ActivityType.contactCreated:
      case ActivityType.leadCreated:
      case ActivityType.taskCreated:
      case ActivityType.ticketCreated:
        return Colors.green;
      case ActivityType.contactUpdated:
      case ActivityType.leadUpdated:
      case ActivityType.taskUpdated:
      case ActivityType.ticketUpdated:
        return Colors.blue;
      case ActivityType.contactDeleted:
      case ActivityType.leadDeleted:
      case ActivityType.ticketDeleted:
        return Colors.red;
      case ActivityType.leadConverted:
      case ActivityType.taskCompleted:
        return Colors.purple;
      case ActivityType.ticketResolved:
      case ActivityType.ticketClosed:
        return Colors.orange;
      case ActivityType.ticketReopened:
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.contactCreated:
      case ActivityType.leadCreated:
      case ActivityType.taskCreated:
      case ActivityType.ticketCreated:
        return Icons.add_circle_outline;
      case ActivityType.contactUpdated:
      case ActivityType.leadUpdated:
      case ActivityType.taskUpdated:
      case ActivityType.ticketUpdated:
        return Icons.edit_note;
      case ActivityType.contactDeleted:
      case ActivityType.leadDeleted:
      case ActivityType.ticketDeleted:
        return Icons.delete_outline;
      case ActivityType.leadConverted:
        return Icons.trending_up;
      case ActivityType.taskCompleted:
        return Icons.check_circle_outline;
      case ActivityType.ticketResolved:
      case ActivityType.ticketClosed:
        return Icons.done_all;
      case ActivityType.ticketReopened:
        return Icons.replay;
      default:
        return Icons.info_outline;
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return _formatDate(dateTime);
    }
  }

  String _formatDate(DateTime dateTime) {
    return "${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}";
  }

  String _formatDateTime(DateTime dateTime) {
    final date = _formatDate(dateTime);
    final time =
        "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    return '$date at $time';
  }
}
