import 'package:flutter/material.dart';
import '../../services/tickets_service.dart';
import '../../services/service_locator.dart';
import '../../models/ticket.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class TicketEditArgs {
  const TicketEditArgs({required this.ticketId});
  final String ticketId;
}

class TicketEditScreen extends StatefulWidget {
  final String ticketId;
  const TicketEditScreen({super.key, required this.ticketId});

  @override
  State<TicketEditScreen> createState() => _TicketEditScreenState();
}

class _TicketEditScreenState extends State<TicketEditScreen> {
  late final TicketsService _ticketsService;
  final _formKey = GlobalKey<FormState>();
  final _subjectCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  bool _isLoading = true;
  String? _error;
  Ticket? _ticket;

  @override
  void initState() {
    super.initState();
    _ticketsService = locator<TicketsService>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await _ticketsService.getTicket(widget.ticketId);
    if (res.isSuccess) {
      _ticket = res.value;
      _subjectCtrl.text = _ticket!.subject;
      _descriptionCtrl.text = _ticket!.description ?? '';
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _error = res.error.message);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _ticket == null) return;
    setState(() => _isLoading = true);
    final data = {
      'subject': _subjectCtrl.text.trim(),
      'description': _descriptionCtrl.text.trim(),
    };
    final res = await _ticketsService.updateTicket(_ticket!.id, data);
    if (res.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() { _error = res.error.message; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading ticket...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Ticket')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: 'Subject'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter subject' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _descriptionCtrl, decoration: const InputDecoration(labelText: 'Description')),
            const SizedBox(height: 20),
            if (_isLoading) const LoadingView(message: 'Saving ticket...') else ElevatedButton(onPressed: _save, child: const Text('Save'))
          ]),
        ),
      ),
    );
  }
}
