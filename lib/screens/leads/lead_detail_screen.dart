import 'package:flutter/material.dart';
import '../../models/lead.dart';
import '../../services/service_locator.dart';
import '../../navigation/app_router.dart';
import '../../widgets/role_visibility.dart';
import '../../services/leads_service.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../widgets/activity_log_widget.dart';

class LeadDetailScreen extends StatefulWidget {
  final String leadId;
  const LeadDetailScreen({super.key, required this.leadId});

  @override
  State<LeadDetailScreen> createState() => _LeadDetailScreenState();
}

class _LeadDetailScreenState extends State<LeadDetailScreen> {
  @override
  void initState() {
    super.initState();
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
          // 🔒 UX Rule: After conversion → read-only (hide edit/delete for converted leads)
          LeadDetailActionsMenu(leadId: widget.leadId),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: LeadDetailCard(leadId: widget.leadId),
          ),
        ),
      ),
    );
  }


}

/// Dialog helper to show lead details in a modal dialog
Future<bool?> showLeadDetailDialog(BuildContext context, {required String leadId}) {
  return showDialog<bool>(
    context: context,
    useRootNavigator: true,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(child: LeadDetailCard(leadId: leadId)),
        ),
      ),
    ),
  );
}
class LeadDetailCard extends StatefulWidget {
  final String leadId;
  const LeadDetailCard({required this.leadId});

  @override
  State<LeadDetailCard> createState() => _LeadDetailCardState();
}

class _LeadDetailCardState extends State<LeadDetailCard> {
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
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final res = await _leadsService.getLead(widget.leadId);
      if (res.isSuccess) {
        setState(() {
          _lead = res.value;
          _isLoading = false;
        });
        return;
      }
      throw Exception(res.error.message);
    } catch (e) {
      setState(() {
        _error = 'Failed to load lead: $e';
        _isLoading = false;
      });
    }
  }

  void _refresh() => _load();

  Future<void> _convertLead(BuildContext context, Lead lead) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Convert Lead'),
        content: Text('Are you sure you want to convert ${lead.fullName} to an Account and Contact?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Convert')),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    
    // Auto-generate account name from lead's company or name
    final accountName = lead.company ?? '${lead.firstName} ${lead.lastName}';
    
    final res = await _leadsService.convertLead(
      lead.id,
      accountName: accountName,
    );
    
    if (!mounted) return;

    if (res.isSuccess) {
      final conversion = res.value;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead converted successfully')),
      );
      
      // 🔗 UX Rule: Navigation moves user toward Account, not back to Lead
      if (conversion.account != null) {
        // Navigate to the newly created/linked account
        AppRouter.navigateTo(
          context,
          AppRouter.accountDetail,
          arguments: AccountDetailArgs(accountId: conversion.account!.id),
        );
      } else {
        // Fallback: just reload to show converted status
        _load();
      }
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Conversion failed: ${res.error.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const LoadingView(message: 'Loading lead details...');
    if (_error != null) return ErrorView(message: _error!, onRetry: _refresh);
    if (_lead == null) return const Center(child: Text('Lead not found'));

    final lead = _lead!;
    final colorScheme = Theme.of(context).colorScheme;

    return DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, lead),
          const SizedBox(height: 16),
          TabBar(
            isScrollable: true,
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Activity Log'),
            ],
            labelColor: colorScheme.primary,
            unselectedLabelColor: colorScheme.onSurfaceVariant,
            indicatorColor: colorScheme.primary,
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 600,
            child: TabBarView(
              children: [
                SingleChildScrollView(child: _buildContentLayout(context, lead)),
                ActivityLogWidget(entityId: widget.leadId, entityType: 'Lead'),
              ],
            ),
          ),
        ],
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
        if (!lead.isConverted)
          FilledButton.icon(
            onPressed: () => _convertLead(context, lead),
            icon: const Icon(Icons.transform, size: 18),
            label: const Text('Convert'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // E1: Converted Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Converted',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // E2: Linked Account
              if (lead.convertedAccountId != null)
                OutlinedButton.icon(
                  onPressed: () {
                    AppRouter.navigateTo(
                      context,
                      AppRouter.accountDetail,
                      arguments: AccountDetailArgs(accountId: lead.convertedAccountId!),
                    );
                  },
                  icon: const Icon(Icons.business_outlined, size: 16),
                  label: const Text('View Account'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              // E3: Linked Contact
              if (lead.convertedContactId != null)
                OutlinedButton.icon(
                  onPressed: () {
                    AppRouter.navigateTo(
                      context,
                      AppRouter.contactDetail,
                      arguments: ContactDetailArgs(contactId: lead.convertedContactId!),
                    );
                  },
                  icon: const Icon(Icons.person_outlined, size: 16),
                  label: const Text('View Contact'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
            ],
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
          // 🔗 Show conversion info if converted
          if (lead.isConverted) ...[
            _buildSectionTitle(context, 'Conversion Info'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Converted Lead',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  if (lead.convertedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Converted: ${_formatDateTime(lead.convertedAt!)}',
                      style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                    ),
                  ],
                  const SizedBox(height: 12),
                  // Link to Account
                  if (lead.convertedAccountId != null)
                    _buildConversionLink(
                      context,
                      icon: Icons.business_outlined,
                      label: 'View Account',
                      onTap: () {
                        AppRouter.navigateTo(
                          context,
                          AppRouter.accountDetail,
                          arguments: AccountDetailArgs(accountId: lead.convertedAccountId!),
                        );
                      },
                    ),
                  if (lead.convertedContactId != null) ...[
                    const SizedBox(height: 8),
                    _buildConversionLink(
                      context,
                      icon: Icons.person_outlined,
                      label: 'View Contact',
                      onTap: () {
                        AppRouter.navigateTo(
                          context,
                          AppRouter.contactDetail,
                          arguments: ContactDetailArgs(contactId: lead.convertedContactId!),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
          
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

  Widget _buildConversionLink(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: cs.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: cs.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(Icons.arrow_forward, size: 14, color: cs.primary),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// Edit button that hides for converted leads
/// 🔒 UX Rule: After conversion → read-only
class LeadDetailActionsMenu extends StatefulWidget {
  final String leadId;
  const LeadDetailActionsMenu({super.key, required this.leadId});

  @override
  State<LeadDetailActionsMenu> createState() => _LeadDetailActionsMenuState();
}

class _LeadDetailActionsMenuState extends State<LeadDetailActionsMenu> {
  late final LeadsService _leadsService;
  bool _isConverted = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _leadsService = locator<LeadsService>();
    _checkConversion();
  }

  Future<void> _checkConversion() async {
    final res = await _leadsService.getLead(widget.leadId);
    if (res.isSuccess) {
      setState(() {
        _isConverted = res.value.isConverted;
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Lead'),
        content: const Text('Are you sure you want to delete this lead? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final result = await _leadsService.deleteLead(widget.leadId);
    
    if (!context.mounted) return;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lead deleted successfully')),
      );
      Navigator.of(context).pop(true); // Return to previous screen
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete lead: ${result.error.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();
    
    // Hide actions menu if lead is converted (read-only)
    if (_isConverted) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface),
      tooltip: 'More actions',
      onSelected: (value) async {
        switch (value) {
          case 'edit':
            final res = await AppRouter.navigateTo<bool?>(
              context,
              AppRouter.leadEdit,
              arguments: LeadEditArgs(leadId: widget.leadId),
            );
            if (res == true && mounted) {
              Navigator.of(context).pop(true);
            }
            break;
          case 'delete':
            await _handleDelete(context);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(
            children: [
              Icon(Icons.edit_outlined, size: 20),
              SizedBox(width: 12),
              Text('Edit Lead'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(
            children: [
              Icon(Icons.delete_outline, size: 20, color: Colors.red),
              SizedBox(width: 12),
              Text('Delete Lead', style: TextStyle(color: Colors.red)),
            ],
          ),
        ),
      ],
    );
  }
}
