import 'package:flutter/material.dart';
import '../../models/lead.dart';
import '../../services/service_locator.dart';
import '../../services/leads_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class LeadEditScreen extends StatefulWidget {
  final String leadId;
  const LeadEditScreen({super.key, required this.leadId});

  @override
  State<LeadEditScreen> createState() => _LeadEditScreenState();
}

class _LeadEditScreenState extends State<LeadEditScreen> {
  late final LeadsService _leadsService;
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  // State variables
  LeadStatus? _status;
  LeadSource? _source;
  Lead? _lead;
  
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _leadsService = locator<LeadsService>();
    _load();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _titleCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final res = await _leadsService.getLead(widget.leadId);
    if (res.isSuccess) {
      _lead = res.value;
      
      // 🔒 UX Rule: After conversion → read-only (prevent editing)
      if (_lead!.isConverted) {
        setState(() {
          _error = 'Cannot edit converted lead. This lead is now read-only.';
          _isLoading = false;
        });
        return;
      }
      
      _firstNameCtrl.text = _lead!.firstName;
      _lastNameCtrl.text = _lead!.lastName;
      _titleCtrl.text = _lead!.title ?? '';
      _companyCtrl.text = _lead!.company ?? '';
      _emailCtrl.text = _lead!.email ?? '';
      _phoneCtrl.text = _lead!.phone ?? '';
      _status = _lead!.status;
      _source = _lead!.leadSource;
      
      setState(() => _isLoading = false);
    } else {
      setState(() {
        _error = res.error.message;
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _lead == null) return;
    setState(() => _isSaving = true);

    final updated = _lead!.copyWith(
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
      company: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
      status: _status,
      leadSource: _source,
      updatedAt: DateTime.now(),
    );

    final res = await _leadsService.updateLead(updated);
    
    if (res.isSuccess) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lead updated successfully')),
        );
        Navigator.of(context).pop(true);
      }
    } else {
      if (mounted) setState(() { _error = res.error.message; _isSaving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading lead details...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));

    final cs = Theme.of(context).colorScheme;
    final inputDecor = InputDecoration(
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Edit Lead'),
        backgroundColor: const Color(0xFFF3F4F6),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              color: cs.surface,
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Lead Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 32),

                      // Name
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameCtrl,
                              decoration: inputDecor.copyWith(labelText: 'First Name'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameCtrl,
                              decoration: inputDecor.copyWith(labelText: 'Last Name'),
                              validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Meta (Status & Source)
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<LeadStatus>(
                              value: _status,
                              decoration: inputDecor.copyWith(labelText: 'Status'),
                              items: LeadStatus.values.map((s) => DropdownMenuItem(value: s, child: Text(s.value))).toList(),
                              onChanged: (v) => setState(() => _status = v),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<LeadSource>(
                              value: _source,
                              decoration: inputDecor.copyWith(labelText: 'Source'),
                              items: LeadSource.values.map((s) => DropdownMenuItem(value: s, child: Text(s.value))).toList(),
                              onChanged: (v) => setState(() => _source = v),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Company Info
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: inputDecor.copyWith(labelText: 'Job Title', prefixIcon: Icon(Icons.work_outline, color: cs.primary)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyCtrl,
                        decoration: inputDecor.copyWith(labelText: 'Company', prefixIcon: Icon(Icons.business, color: cs.primary)),
                      ),
                      const SizedBox(height: 16),

                      // Contact Info
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: inputDecor.copyWith(labelText: 'Email', prefixIcon: Icon(Icons.email_outlined, color: cs.primary)),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: inputDecor.copyWith(labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined, color: cs.primary)),
                      ),

                      const SizedBox(height: 40),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _save,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _isSaving 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.save_outlined),
                            label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}