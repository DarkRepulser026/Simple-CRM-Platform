import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../services/service_locator.dart';
import '../../services/tasks_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class TaskEditArgs {
  const TaskEditArgs({required this.taskId});
  final String taskId;
}

class TaskEditScreen extends StatefulWidget {
  final String taskId;
  const TaskEditScreen({super.key, required this.taskId});

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late final TasksService _tasksService;
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
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
    final res = await _tasksService.getTask(widget.taskId);
    if (res.isSuccess) {
      _task = res.value;
      _subjectCtrl.text = _task!.subject;
      _descriptionCtrl.text = _task!.description ?? '';
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _error = res.error.message);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _task == null) return;
    setState(() => _isLoading = true);
    final updated = _task!.copyWith(
      subject: _subjectCtrl.text.trim(),
      description: _descriptionCtrl.text.trim(),
      updatedAt: DateTime.now(),
    );
    final res = await _tasksService.updateTask(updated);
    if (res.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() { _error = res.error.message; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading task...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter subject' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descriptionCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 20),
            if (_isLoading) const LoadingView(message: 'Saving task...') else ElevatedButton(onPressed: _save, child: const Text('Save'))
          ]),
        ),
      ),
    );
  }
}
