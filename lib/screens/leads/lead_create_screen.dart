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
  
  // Controllers
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _leadsService = locator<LeadsService>();
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

  Future<void> _createLead() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final lead = Lead(
        id: '',
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        title: _titleCtrl.text.trim().isEmpty ? null : _titleCtrl.text.trim(),
        company: _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        status: LeadStatus.newLead,
        leadSource: LeadSource.web, // Default source
        organizationId: locator<AuthService>().selectedOrganizationId ?? '',
        isConverted: false,
      );

      final res = await _leadsService.createLead(lead);
      
      if (res.isSuccess) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lead created successfully')),
          );
          Navigator.of(context).pop(true);
        }
      } else {
        if (mounted) setState(() => _error = res.error.message);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    // Input decoration helper
    final inputDecor = InputDecoration(
      filled: true,
      fillColor: cs.surfaceVariant.withOpacity(0.3),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      appBar: AppBar(
        title: const Text('Add New Lead'),
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
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: cs.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.person_add, color: cs.primary),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Lead Information', 
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Enter details for the potential customer',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      if (_error != null) ...[
                        ErrorView(message: _error!, onRetry: null),
                        const SizedBox(height: 16),
                      ],

                      // Name Row
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

                      // Title & Company
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: inputDecor.copyWith(
                          labelText: 'Job Title',
                          prefixIcon: Icon(Icons.work_outline, color: cs.primary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _companyCtrl,
                        decoration: inputDecor.copyWith(
                          labelText: 'Company',
                          prefixIcon: Icon(Icons.business, color: cs.primary),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact Info
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: inputDecor.copyWith(
                          labelText: 'Email Address',
                          prefixIcon: Icon(Icons.email_outlined, color: cs.primary),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _phoneCtrl,
                        decoration: inputDecor.copyWith(
                          labelText: 'Phone Number',
                          prefixIcon: Icon(Icons.phone_outlined, color: cs.primary),
                        ),
                        keyboardType: TextInputType.phone,
                      ),

                      const SizedBox(height: 40),

                      // Actions
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          FilledButton.icon(
                            onPressed: _isLoading ? null : _createLead,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: _isLoading 
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.check),
                            label: Text(_isLoading ? 'Saving...' : 'Create Lead'),
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