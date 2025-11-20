import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/tasks_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class TaskCreateScreen extends StatefulWidget {
  const TaskCreateScreen({super.key});

  @override
  State<TaskCreateScreen> createState() => _TaskCreateScreenState();
}

class _TaskCreateScreenState extends State<TaskCreateScreen> {
  late final TasksService _tasksService;
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tasksService = locator<TasksService>();
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final task = Task(
      id: '',
      subject: _subjectCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      status: TaskStatus.notStarted,
      priority: TaskPriority.normal,
      organizationId: locator<AuthService>().selectedOrganizationId ?? '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final res = await _tasksService.createTask(task);
    if (res.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() { _isLoading = false; _error = res.error.message; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_error != null) ErrorView(message: _error!, onRetry: null),
            TextFormField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a subject' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descriptionCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 20),
            if (_isLoading) const LoadingView(message: 'Creating task...') else ElevatedButton(onPressed: _createTask, child: const Text('Create'))
          ]),
        ),
      ),
    );
  }
}
