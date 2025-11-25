import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/service_locator.dart';
import '../../services/tasks_service.dart';
import '../../navigation/app_router.dart';
import '../../widgets/role_visibility.dart';
import 'task_edit_screen.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class TaskDetailArgs {
  const TaskDetailArgs({required this.taskId});
  final String taskId;
}

class TaskDetailScreen extends StatefulWidget {
  final String taskId;
  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late final TasksService _tasksService;
  bool _isLoading = true;
  String? _error;
  Task? _task;

  @override
  void initState() {
    super.initState();
    _tasksService = locator<TasksService>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final res = await _tasksService.getTask(widget.taskId);
      if (res.isSuccess) {
        setState(() {_task = res.value; _isLoading = false;});
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() { _error = 'Failed to load task: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading task...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    if (_task == null) return const Scaffold(body: Center(child: Text('No task data')));
    return Scaffold(
      appBar: AppBar(
        title: Text(_task!.subject),
        actions: [
          ManagerOrAdminOnly(child: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => AppRouter.navigateTo(context, AppRouter.taskEdit, arguments: TaskEditArgs(taskId: _task!.id)),
          )),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Status: ${_task!.status.value}'),
          const SizedBox(height: 8),
          Text('Priority: ${_task!.priority.value}'),
        ]),
      ),
    );
  }
}
