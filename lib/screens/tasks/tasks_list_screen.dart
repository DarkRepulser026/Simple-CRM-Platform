import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/task.dart';
import '../../navigation/app_router.dart';
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
  int _reloadVersion = 0; // Dùng để reload list

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

  Future<List<Task>> _fetchTasksPage(int page, int limit) async {
    try {
      final res = await _tasksService.getTasks(
        page: page,
        limit: limit,
        // search: _searchCtrl.text // Truyền search nếu API hỗ trợ
      );
      if (res.isSuccess) {
        var tasks = res.value.tasks;

        // Filter local đơn giản (nếu API chưa hỗ trợ search)
        if (_searchCtrl.text.isNotEmpty) {
          final q = _searchCtrl.text.toLowerCase();
          tasks = tasks.where((t) => 
            t.subject.toLowerCase().contains(q) || 
            (t.description ?? '').toLowerCase().contains(q)
          ).toList();
        }

        return tasks;
      }
      throw Exception(res.error.message);
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  void _refreshList() {
    setState(() => _reloadVersion++);
  }

  Future<void> _navigateToTaskDetail(String taskId) async {
    final changed = await AppRouter.navigateTo<bool?>(
      context,
      AppRouter.taskDetail,
      arguments: TaskDetailArgs(taskId: taskId),
    );
    if (changed == true) _refreshList();
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
    final colorScheme = theme.colorScheme;
    const bgColor = Color(0xFFE9EDF5); // Màu nền Dashboard chuẩn

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
                      'Tasks',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Work',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
                const SizedBox(height: 16),

                // ===== FILTER & ACTIONS =====
                Row(
                  children: [
                    // Search
                    Expanded(
                      child: TextField(
                        controller: _searchCtrl,
                        decoration: InputDecoration(
                          hintText: 'Search by subject or description',
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
                            vertical: 0, horizontal: 12
                          ),
                        ),
                        onSubmitted: (_) => _refreshList(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // New Task Button
                    FilledButton.icon(
                      onPressed: () async {
                        final res = await AppRouter.navigateTo(context, AppRouter.taskCreate);
                        if (res == true) _refreshList();
                      },
                      icon: const Icon(Icons.add_task, size: 18),
                      label: const Text('New task'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      border: Border.all(color: colorScheme.outline.withOpacity(0.08)),
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
                        // Table Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            color: colorScheme.surfaceVariant.withOpacity(0.2),
                          ),
                          child: Row(
                            children: [
                              _HeaderCell('Subject', flex: 4),
                              _HeaderCell('Priority', flex: 2),
                              _HeaderCell('Status', flex: 2),
                              _HeaderCell('Due Date', flex: 2),
                              _HeaderCell('Created', flex: 2, align: TextAlign.right),
                            ],
                          ),
                        ),
                        const Divider(height: 1),

                        // Table Body
                        Expanded(
                          child: PaginatedListView<Task>(
                            key: ValueKey(_reloadVersion),
                            fetchPage: _fetchTasksPage,
                            pageSize: 20,
                            emptyMessage: 'No tasks found',
                            errorMessage: 'Failed to load tasks',
                            loadingMessage: 'Loading tasks...',
                            itemBuilder: (context, task, index) => _TaskRow(
                              task: task,
                              onTap: () => _navigateToTaskDetail(task.id),
                            ),
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
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  final TextAlign align;

  const _HeaderCell(this.label, {this.flex = 1, this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        textAlign: align,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;

  const _TaskRow({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    // Date formatting
    final createdStr = "${task.createdAt.year}-${task.createdAt.month.toString().padLeft(2,'0')}-${task.createdAt.day.toString().padLeft(2,'0')}";
    final dueDateStr = task.dueDate != null 
        ? "${task.dueDate!.year}-${task.dueDate!.month.toString().padLeft(2,'0')}-${task.dueDate!.day.toString().padLeft(2,'0')}"
        : "—";

    return InkWell(
      onTap: onTap,
      hoverColor: cs.surfaceVariant.withOpacity(0.1),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: cs.outline.withOpacity(0.06))),
        ),
        child: Row(
          children: [
            // Subject
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    task.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  if (task.description != null && task.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        task.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ),
                ],
              ),
            ),

            // Priority
            Expanded(
              flex: 2,
              child: Row(
                children: [
                  _priorityIcon(task.priority, cs),
                  const SizedBox(width: 6),
                  Text(
                    task.priority.value,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _priorityColor(task.priority, cs),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Status
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _StatusChip(task: task),
              ),
            ),

            // Due Date
            Expanded(
              flex: 2,
              child: Text(
                dueDateStr,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: task.isOverdue ? cs.error : cs.onSurfaceVariant,
                  fontWeight: task.isOverdue ? FontWeight.w600 : null,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ),

            // Created
            Expanded(
              flex: 2,
              child: Text(
                createdStr,
                textAlign: TextAlign.right,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontFeatures: [const FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helpers
  Color _priorityColor(TaskPriority p, ColorScheme cs) {
    switch (p) {
      case TaskPriority.high: return cs.error;
      case TaskPriority.normal: return cs.primary;
      case TaskPriority.low: return cs.secondary;
    }
  }

  Icon _priorityIcon(TaskPriority p, ColorScheme cs) {
    switch (p) {
      case TaskPriority.high: return Icon(Icons.priority_high_rounded, size: 16, color: cs.error);
      case TaskPriority.normal: return Icon(Icons.low_priority_rounded, size: 16, color: cs.primary);
      case TaskPriority.low: return Icon(Icons.arrow_downward_rounded, size: 16, color: cs.secondary);
    }
  }
}

class _StatusChip extends StatelessWidget {
  final Task task;
  const _StatusChip({required this.task});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    Color bg, fg;

    switch (task.status) {
      case TaskStatus.completed:
        bg = Colors.green.withOpacity(0.1);
        fg = Colors.green[700]!;
        break;
      case TaskStatus.inProgress:
        bg = Colors.blue.withOpacity(0.1);
        fg = Colors.blue[700]!;
        break;
      case TaskStatus.cancelled:
        bg = cs.surfaceVariant;
        fg = cs.onSurfaceVariant;
        break;
      default: // Not Started
        bg = Colors.orange.withOpacity(0.1);
        fg = Colors.orange[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        task.status.value,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}