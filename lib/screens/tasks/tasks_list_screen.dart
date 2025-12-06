import 'package:flutter/material.dart';
import 'dart:ui';
import '../../widgets/paginated_list_view.dart';
import '../../models/task.dart';
import '../../models/pagination.dart';
import '../../navigation/app_router.dart';
import 'task_detail_screen.dart';
import '../../services/auth/auth_service.dart';
import '../../widgets/error_view.dart';
import '../../services/tasks_service.dart';
import '../../services/service_locator.dart';

class TasksListScreen extends StatefulWidget {
  const TasksListScreen({super.key});

  @override
  State<TasksListScreen> createState() => _TasksListScreenState();
}

class _TasksListScreenState extends State<TasksListScreen> {
  late final TasksService _tasksService;
  final TextEditingController _searchCtrl = TextEditingController();
  String? _selectedStatus;
  String? _selectedPriority;
  int _filterVersion = 0;

  @override
  void initState() {
    super.initState();
    _tasksService = locator<TasksService>();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<PaginatedResponse<Task>> _fetchPaginatedTasks(int page, int limit) async {
    try {
      final res = await _tasksService.getTasks(
        page: page,
        limit: limit,
        status: _selectedStatus,
        priority: _selectedPriority,
        q: _searchCtrl.text.isEmpty ? null : _searchCtrl.text,
      );
      if (res.isSuccess) {
        final pagination = res.value.pagination ?? Pagination(
          page: page,
          limit: limit,
          total: res.value.tasks.length,
          totalPages: 1,
          hasNext: false,
          hasPrev: false,
        );
        return PaginatedResponse<Task>(items: res.value.tasks, pagination: pagination);
      }
      throw Exception(res.error.message);
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  void _refreshList() {
    setState(() => _filterVersion++);
  }

  Future<void> _navigateToTaskDetail(String taskId) async {
    debugPrint('TasksListScreen: open task dialog $taskId');
    await showTaskDetailDialog(context, taskId);
    _refreshList();
  }

  @override
  Widget build(BuildContext context) {
    final auth = locator<AuthService>();

    if (auth.isLoggedIn && !auth.hasSelectedOrganization) {
      return Scaffold(
        body: ErrorView(
          message: 'No organization selected. Please select a company to continue.',
          onRetry: () => AppRouter.navigateTo(context, AppRouter.companySelection),
        ),
      );
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: false,
        titleSpacing: 24,
        title: Row(
          children: [
            const Text('Tasks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cs.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'CRM Board',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cs.primary),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refreshList,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ===== SEARCH & FILTERS =====
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Search
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search tasks...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.transparent),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: cs.outline.withOpacity(0.1)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        ),
                        onSubmitted: (_) => _refreshList(),
                        onChanged: (_) => _refreshList(),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Priority Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.outline.withOpacity(0.1)),
                      ),
                      child: DropdownButton<String?>(
                        value: _selectedPriority,
                        underline: const SizedBox(),
                        isDense: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Priorities')),
                          DropdownMenuItem(value: 'High', child: Text('High', style: TextStyle(color: Colors.red[700]))),
                          DropdownMenuItem(value: 'Normal', child: Text('Normal', style: TextStyle(color: cs.primary))),
                          DropdownMenuItem(value: 'Low', child: Text('Low', style: TextStyle(color: Colors.amber[700]))),
                        ],
                        onChanged: (val) => setState(() {
                          _selectedPriority = val;
                          _filterVersion++;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Status Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: cs.outline.withOpacity(0.1)),
                      ),
                      child: DropdownButton<String?>(
                        value: _selectedStatus,
                        underline: const SizedBox(),
                        isDense: true,
                        items: [
                          const DropdownMenuItem(value: null, child: Text('All Status')),
                          const DropdownMenuItem(value: 'NotStarted', child: Text('Not Started')),
                          const DropdownMenuItem(value: 'InProgress', child: Text('In Progress')),
                          const DropdownMenuItem(value: 'Completed', child: Text('Completed')),
                          const DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                        ],
                        onChanged: (val) => setState(() {
                          _selectedStatus = val;
                          _filterVersion++;
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // New Task Button
                    FilledButton.icon(
                      onPressed: () async {
                        final res = await AppRouter.navigateTo(context, AppRouter.taskCreate);
                        if (res == true) _refreshList();
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('New Task'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ===== TASK CARDS LIST =====
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.all(24),
              child: PaginatedListView<Task>(
                key: ValueKey(_filterVersion),
                fetchPaginated: _fetchPaginatedTasks,
                pageSize: 12,
                emptyMessage: 'No tasks found',
                errorMessage: 'Failed to load tasks',
                loadingMessage: 'Loading tasks...',
                itemBuilder: (context, task, index) => _TaskCard(
                  task: task,
                  onTap: () => _navigateToTaskDetail(task.id),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// CRM-style Task Card
class _TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _TaskCard({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Status color mapping
    final (statusBg, statusFg, statusIcon) = _getStatusStyle(task.status, cs);

    // Priority color mapping
    final priorityColor = _getPriorityColor(task.priority, cs);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outline.withOpacity(0.1), width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Priority Indicator (left border)
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // Main Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Subject
                    Text(
                      task.subject,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Description
                    if (task.description != null && task.description!.isNotEmpty)
                      Text(
                        task.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),

                    // Meta Info (Priority, Status, Due Date)
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Priority Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: priorityColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            task.priority.value,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: priorityColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(statusIcon, size: 12, color: statusFg),
                              const SizedBox(width: 4),
                              Text(
                                task.status.value,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: statusFg,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Due Date
                        if (task.dueDate != null) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.calendar_today, size: 12, color: cs.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(task.dueDate!),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: task.isOverdue ? cs.error : cs.onSurfaceVariant,
                              fontWeight: task.isOverdue ? FontWeight.w600 : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Right Arrow
              const SizedBox(width: 16),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);

    if (diff.isNegative) {
      return 'Overdue ${diff.inDays.abs()} days';
    } else if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Tomorrow';
    } else if (diff.inDays < 7) {
      return 'In ${diff.inDays} days';
    } else {
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    }
  }

  (Color, Color, IconData) _getStatusStyle(TaskStatus status, ColorScheme cs) {
    switch (status) {
      case TaskStatus.completed:
        return (Colors.green.withOpacity(0.1), Colors.green[700]!, Icons.check_circle);
      case TaskStatus.inProgress:
        return (Colors.blue.withOpacity(0.1), Colors.blue[700]!, Icons.schedule);
      case TaskStatus.cancelled:
        return (cs.surfaceVariant, cs.onSurfaceVariant, Icons.cancel);
      default:
        return (Colors.orange.withOpacity(0.1), Colors.orange[800]!, Icons.schedule);
    }
  }

  Color _getPriorityColor(TaskPriority priority, ColorScheme cs) {
    switch (priority) {
      case TaskPriority.high:
        return Colors.red[600]!;
      case TaskPriority.normal:
        return cs.primary;
      case TaskPriority.low:
        return Colors.amber[600]!;
    }
  }
}
