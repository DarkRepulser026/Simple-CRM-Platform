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
  late Future<Lead> _futureLead;

  @override
  void initState() {
    super.initState();
    _leadsService = locator<LeadsService>();
    _futureLead = _fetchLead();
  }

  Future<Lead> _fetchLead() async {
    final res = await _leadsService.getLead(widget.leadId);
    if (res.isSuccess) return res.value;
    throw Exception(res.error.message);
  }

  void _refresh() {
    setState(() {
      _futureLead = _fetchLead();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const bgColor = Color(0xFFE9EDF5);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(''), // Custom header below
        actions: [
          ManagerOrAdminOnly(
            child: IconButton(
              icon: Icon(Icons.edit_outlined, color: cs.onSurface),
              tooltip: 'Edit Lead',
              onPressed: () async {
                final res = await AppRouter.navigateTo(
                  context,
                  AppRouter.leadEdit,
                  arguments: LeadEditArgs(leadId: widget.leadId),
                );
                if (res == true) _refresh();
              },
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<Lead>(
        future: _futureLead,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView(message: 'Loading lead details...');
          }
          if (snapshot.hasError) {
            return ErrorView(
              message: snapshot.error.toString(),
              onRetry: _refresh,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: Text('Lead not found'));
          }

          final lead = snapshot.data!;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, lead),
                    const SizedBox(height: 24),
                    _buildContentLayout(context, lead),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // --- HEADER: Avatar + Name + Actions ---
  Widget _buildHeader(BuildContext context, Lead lead) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final initial = lead.firstName.isNotEmpty ? lead.firstName[0] : '?';

    return Row(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: cs.primary,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.primary.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initial.toUpperCase(),
              style: theme.textTheme.headlineMedium?.copyWith(
                color: cs.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lead.fullName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                lead.title ?? 'No Title',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        // Action Buttons (Convert, etc.)
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Convert feature coming soon')),
            );
          },
          icon: const Icon(Icons.transform, size: 18),
          label: const Text('Convert'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  // --- CONTENT: 2-Column Layout ---
  Widget _buildContentLayout(BuildContext context, Lead lead) {
    // Check screen width for responsive
    final width = MediaQuery.of(context).size.width;
    final isWide = width > 800;

    if (isWide) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: _buildMainInfoCard(context, lead)),
          const SizedBox(width: 24),
          Expanded(flex: 1, child: _buildSidebarCard(context, lead)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildMainInfoCard(context, lead),
          const SizedBox(height: 24),
          _buildSidebarCard(context, lead),
        ],
      );
    }
  }

  Widget _buildMainInfoCard(BuildContext context, Lead lead) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Contact Information'),
          const SizedBox(height: 16),
          _buildInfoRow(context, Icons.email_outlined, 'Email', lead.email),
          const Divider(height: 24),
          _buildInfoRow(context, Icons.phone_outlined, 'Phone', lead.phone),
          const Divider(height: 24),
          _buildInfoRow(context, Icons.business, 'Company', lead.company),
          
          const SizedBox(height: 32),
          _buildSectionTitle(context, 'About'),
          const SizedBox(height: 16),
          Text(
            lead.description ?? 'No description provided.',
            style: TextStyle(color: cs.onSurfaceVariant, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarCard(BuildContext context, Lead lead) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(context, 'Status & Source'),
          const SizedBox(height: 16),
          _buildMetaRow(context, 'Status', _buildStatusChip(context, lead.status)),
          const SizedBox(height: 16),
          _buildMetaRow(context, 'Source', Text(lead.leadSource.value)),
          const SizedBox(height: 16),
          _buildMetaRow(context, 'Industry', Text(lead.industry ?? '-')),
          const SizedBox(height: 16),
          _buildMetaRow(context, 'Rating', Text(lead.rating?.toString() ?? '-')),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String? value) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cs.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: cs.primary),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              Text(
                value ?? '-', 
                style: TextStyle(
                  fontSize: 16, 
                  color: value == null ? cs.onSurfaceVariant.withOpacity(0.5) : cs.onSurface
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow(BuildContext context, String label, Widget content) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        content,
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, LeadStatus status) {
    Color color;
    switch (status) {
      case LeadStatus.newLead: color = Colors.blue; break;
      case LeadStatus.qualified: color = Colors.amber; break;
      case LeadStatus.converted: color = Colors.green; break;
      default: color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        status.value,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}