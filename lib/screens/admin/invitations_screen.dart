import 'package:flutter/material.dart';
import '../../services/service_locator.dart';
import '../../services/invitations_service.dart';
import '../../services/auth/auth_service.dart';
import '../../models/invitation.dart';

class InvitationsScreen extends StatefulWidget {
  const InvitationsScreen({super.key});

  @override
  State<InvitationsScreen> createState() => _InvitationsScreenState();
}

class _InvitationsScreenState extends State<InvitationsScreen> {
  late final InvitationsService _invitationsService;
  late Future<List<Invitation>> _futureInvites;

  @override
  void initState() {
    super.initState();
    _invitationsService = locator<InvitationsService>();
    _loadData();
  }

  void _loadData() {
    final orgId = locator<AuthService>().selectedOrganizationId;
    if (orgId == null) {
      _futureInvites = Future.error('No organization selected');
    } else {
      _futureInvites = _loadInvites(orgId);
    }
  }

  Future<List<Invitation>> _loadInvites(String orgId) async {
    final r = await _invitationsService.getInvitesForOrganization(orgId);
    if (r.isError) throw Exception(r.error);
    return r.value;
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  Future<void> _revoke(String id) async {
    // Hiển thị dialog xác nhận trước khi xóa
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Revoke Invitation'),
        content: const Text('Are you sure you want to cancel this invitation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Revoke'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final res = await _invitationsService.revokeInvitation(id);
    if (res.isError) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to revoke: ${res.error}')),
        );
      }
      return;
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invitation revoked successfully')),
      );
    }
    await _refresh();
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Never';
    final d = date.toLocal();
    return "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final orgName = locator<AuthService>().selectedOrganization?.name ?? 'Organization';

    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.4),
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            color: Colors.transparent, 
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 680,
                maxHeight: 600,
              ),
              child: GestureDetector(
                onTap: () {}, 
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ===== HEADER SECTION =====
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.mark_email_unread_outlined,
                                color: colorScheme.onPrimaryContainer,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Pending Invitations',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Manage outgoing invites for $orgName',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close),
                              tooltip: 'Close',
                            ),
                          ],
                        ),
                      ),
                      
                      const Divider(height: 1),

                      // ===== LIST SECTION =====
                      Expanded(
                        child: FutureBuilder<List<Invitation>>(
                          future: _futureInvites,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                                    const SizedBox(height: 16),
                                    Text('Error loading invites', style: TextStyle(color: colorScheme.error)),
                                    TextButton(onPressed: _refresh, child: const Text('Try Again'))
                                  ],
                                ),
                              );
                            }

                            final invites = snapshot.data ?? [];

                            if (invites.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.forward_to_inbox_rounded, 
                                      size: 64, 
                                      color: colorScheme.outline.withOpacity(0.5)
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No pending invitations',
                                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Invite users to your organization to see them here.',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: invites.length,
                              separatorBuilder: (ctx, index) => Divider(
                                color: colorScheme.outlineVariant.withOpacity(0.4),
                                indent: 70, 
                                endIndent: 24,
                              ),
                              itemBuilder: (context, index) {
                                final inv = invites[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    hoverColor: colorScheme.surfaceVariant.withOpacity(0.3),
                                    leading: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: colorScheme.primary.withOpacity(0.1),
                                      child: Text(
                                        inv.email.isNotEmpty ? inv.email[0].toUpperCase() : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold, 
                                          color: colorScheme.primary
                                        ),
                                      ),
                                    ),
                                    title: Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Text(
                                        inv.email,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    subtitle: Row(
                                      children: [
                                        // Role Chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: colorScheme.secondaryContainer.withOpacity(0.5),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: colorScheme.outlineVariant),
                                          ),
                                          child: Text(
                                            inv.role.toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onSecondaryContainer,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Expiry info
                                        Icon(Icons.access_time, size: 14, color: colorScheme.outline),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(inv.expiresAt),
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: OutlinedButton.icon(
                                      onPressed: () => _revoke(inv.id),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: colorScheme.error,
                                        side: BorderSide(color: colorScheme.error.withOpacity(0.5)),
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                      ),
                                      icon: const Icon(Icons.person_remove_outlined, size: 18),
                                      label: const Text('Revoke'),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      
                      const Divider(height: 1),

                      // ===== FOOTER SECTION =====
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.2),
                          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                              'Invitations expire after 7 days',
                              style: TextStyle(
                                fontSize: 12, 
                                color: colorScheme.onSurfaceVariant,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _refresh,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Refresh List'),
                            ),
                          ],
                        ),
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