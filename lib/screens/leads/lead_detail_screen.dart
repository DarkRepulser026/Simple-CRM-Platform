import 'package:flutter/material.dart';
import '../../models/lead.dart';
import '../../services/service_locator.dart';
import '../../navigation/app_router.dart';
import '../../widgets/role_visibility.dart';
import 'lead_edit_screen.dart';
import '../../services/leads_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';

class LeadDetailArgs {
  const LeadDetailArgs({required this.leadId});
  final String leadId;
}

class LeadDetailScreen extends StatefulWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  late final LeadsService _leadsService;
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
    try {
      final res = await _leadsService.getLead(widget.leadId);
      if (res.isSuccess) {
        setState(() { _lead = res.value; _isLoading = false; });
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() { _error = 'Failed to load lead: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: LoadingView(message: 'Loading lead...'));
    if (_error != null) return Scaffold(body: ErrorView(message: _error!, onRetry: _load));
    if (_lead == null) return const Scaffold(body: Center(child: Text('No lead data')));
    return Scaffold(
      appBar: AppBar(
        title: Text(_lead!.fullName),
        actions: [
          ManagerOrAdminOnly(child: IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => AppRouter.navigateTo(context, AppRouter.leadEdit, arguments: LeadEditArgs(leadId: _lead!.id)),
          )),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Company: ${_lead!.company ?? '-'}'),
            const SizedBox(height: 8),
            Text('Email: ${_lead!.email ?? '-'}'),
            const SizedBox(height: 8),
            Text('Phone: ${_lead!.phone ?? '-'}'),
          ],
        ),
      ),
    );
  }
}
