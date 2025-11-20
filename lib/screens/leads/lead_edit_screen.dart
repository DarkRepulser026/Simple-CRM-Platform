import 'package:flutter/material.dart';
import '../../models/lead.dart';
import '../../services/service_locator.dart';
import '../../services/leads_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class LeadEditArgs {
  const LeadEditArgs({required this.leadId});
  final String leadId;
}

class LeadEditScreen extends StatefulWidget {
  final String leadId;
  const LeadEditScreen({super.key, required this.leadId});

  @override
  State<LeadEditScreen> createState() => _LeadEditScreenState();
}

class _LeadEditScreenState extends State<LeadEditScreen> {
  late final LeadsService _leadsService;
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isLoading = true;
  String? _error;
  Lead? _lead;

  @override
  void initState() {
    super.initState();
    _leadsService = locator<LeadsService>();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await _leadsService.getLead(widget.leadId);
    if (res.isSuccess) {
      _lead = res.value;
      _firstNameCtrl.text = _lead!.firstName;
      _lastNameCtrl.text = _lead!.lastName;
      _companyCtrl.text = _lead!.company ?? '';
      _emailCtrl.text = _lead!.email ?? '';
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _error = res.error.message);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _lead == null) return;
    setState(() => _isLoading = true);
    final updated = Lead(
      id: _lead!.id,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _lead!.phone,
      company: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
      title: _lead!.title,
      status: _lead!.status,
      leadSource: _lead!.leadSource,
      industry: _lead!.industry,
      rating: _lead!.rating,
      description: _lead!.description,
      createdAt: _lead!.createdAt,
      updatedAt: DateTime.now(),
      ownerId: _lead!.ownerId,
      organizationId: _lead!.organizationId,
      isConverted: _lead!.isConverted,
      convertedAt: _lead!.convertedAt,
      convertedAccountId: _lead!.convertedAccountId,
      convertedContactId: _lead!.convertedContactId,
      convertedOpportunityId: _lead!.convertedOpportunityId,
      contactId: _lead!.contactId,
    );
    final res = await _leadsService.updateLead(updated);
    if (res.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() { _error = res.error.message; _isLoading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading lead...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Lead')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextFormField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'First name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter first name' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Last name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter last name' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _companyCtrl, decoration: const InputDecoration(labelText: 'Company')),
            const SizedBox(height: 12),
            TextFormField(controller: _emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 20),
            if (_isLoading) const LoadingView(message: 'Saving lead...') else ElevatedButton(onPressed: _save, child: const Text('Save'))
          ]),
        ),
      ),
    );
  }
}
