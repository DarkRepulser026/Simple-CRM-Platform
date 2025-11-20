import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../services/tickets_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class TicketCreateScreen extends StatefulWidget {
  const TicketCreateScreen({super.key});

  @override
  State<TicketCreateScreen> createState() => _TicketCreateScreenState();
}

class _TicketCreateScreenState extends State<TicketCreateScreen> {
  late final TicketsService _ticketsService;
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ticketsService = locator<TicketsService>();
  }

  Future<void> _createTicket() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final data = {
      'subject': _subjectCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
    };
    final res = await _ticketsService.createTicket(data);
    if (res.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() { _isLoading = false; _error = res.error.message; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Ticket')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_error != null) ErrorView(message: _error!, onRetry: null),
            TextFormField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter subject' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descriptionCtrl, decoration: const InputDecoration(labelText: 'Description')), 
            const SizedBox(height: 20),
            if (_isLoading) const LoadingView(message: 'Creating ticket...') else ElevatedButton(onPressed: _createTicket, child: const Text('Create'))
          ]),
        ),
      ),
    );
  }
}
