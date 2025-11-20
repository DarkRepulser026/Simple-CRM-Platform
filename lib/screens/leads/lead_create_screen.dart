import 'package:flutter/material.dart';
import '../../models/lead.dart';
import '../../services/service_locator.dart';
import '../../services/auth/auth_service.dart';
import '../../services/leads_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class LeadCreateScreen extends StatefulWidget {
  const LeadCreateScreen({super.key});

  @override
  State<LeadCreateScreen> createState() => _LeadCreateScreenState();
}

class _LeadCreateScreenState extends State<LeadCreateScreen> {
  late final LeadsService _leadsService;
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _leadsService = locator<LeadsService>();
  }

  Future<void> _createLead() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final lead = Lead(
      id: '',
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      status: LeadStatus.newLead,
      leadSource: LeadSource.web,
      organizationId: locator<AuthService>().selectedOrganizationId ?? '',
      isConverted: false,
    );
    final res = await _leadsService.createLead(lead);
    if (res.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isLoading = false;
      _error = res.error.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Lead')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_error != null) ErrorView(message: _error!, onRetry: null),
            TextFormField(controller: _firstNameCtrl, decoration: const InputDecoration(labelText: 'First name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter first name' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _lastNameCtrl, decoration: const InputDecoration(labelText: 'Last name'), validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter last name' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _companyCtrl, decoration: const InputDecoration(labelText: 'Company')),
            const SizedBox(height: 20),
            if (_isLoading) const LoadingView(message: 'Creating lead...') else ElevatedButton(onPressed: _createLead, child: const Text('Create'))
          ]),
        ),
      ),
    );
  }
}
