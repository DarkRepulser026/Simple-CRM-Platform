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
    final orgId = locator<AuthService>().selectedOrganizationId;
    if (orgId == null) {
      _futureInvites = Future.error('No organization selected');
    } else {
      _futureInvites = _invitationsService.getInvitesForOrganization(orgId).then((r) {
        if (r.isError) throw Exception(r.error);
        return r.value;
      });
    }
  }

  Future<void> _refresh() async {
    final newListRes = await _invitationsService.getInvitesForOrganization(locator<AuthService>().selectedOrganizationId ?? '');
    if (newListRes.isError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading invites: ${newListRes.error}')));
      return;
    }
    setState(() {
      _futureInvites = Future.value(newListRes.value);
    });
  }

  Future<void> _revoke(String id) async {
    final res = await _invitationsService.revokeInvitation(id);
    if (res.isError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to revoke invite: ${res.error}')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invitation revoked')));
    await _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pending Invitations')),
      body: FutureBuilder<List<Invitation>>(
        future: _futureInvites,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Text('Failed to load: ${snapshot.error}'));
          final invites = snapshot.data ?? [];
          if (invites.isEmpty) return const Center(child: Text('No pending invites'));
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              itemBuilder: (context, index) {
                final inv = invites[index];
                return ListTile(
                  title: Text(inv.email),
                  subtitle: Text('Role: ${inv.role} • Expires: ${inv.expiresAt ?? 'N/A'}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.block),
                    tooltip: 'Revoke invite',
                    onPressed: () => _revoke(inv.id),
                  ),
                );
              },
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemCount: invites.length,
            ),
          );
        },
      ),
    );
  }
}
