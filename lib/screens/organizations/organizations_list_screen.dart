import 'package:flutter/material.dart';
import '../../widgets/paginated_list_view.dart';
import '../../models/organization.dart';
import '../../services/service_locator.dart';
import '../../services/organizations_service.dart';
import '../../navigation/app_router.dart';
import '../../services/auth/auth_service.dart';

/// Organizations list screen
class OrganizationsListScreen extends StatefulWidget {
  const OrganizationsListScreen({super.key});

  @override
  State<OrganizationsListScreen> createState() => _OrganizationsListScreenState();
}

class _OrganizationsListScreenState extends State<OrganizationsListScreen> {
  late final OrganizationsService _organizationsService;
  late final AuthService _authService;

  Future<List<Organization>> _fetchOrgs(int page, int limit) async {
    try {
      final res = await _organizationsService.getOrganizations(page: page, limit: limit);
      if (res.isSuccess) return res.value.organizations;
      throw Exception(res.error.message);
    } catch (e) {
      throw Exception('Failed to load organizations: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _organizationsService = locator<OrganizationsService>();
    _authService = locator<AuthService>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Organizations'),
        actions: [
          IconButton(
            onPressed: () => AppRouter.navigateTo(context, AppRouter.companyCreate),
            icon: const Icon(Icons.add),
            tooltip: 'Create Organization',
          ),
        ],
      ),
      body: PaginatedListView<Organization>(
        itemBuilder: (context, org, index) => Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            title: Text(org.name),
            subtitle: Text(org.role ?? ''),
            leading: const Icon(Icons.business),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              // Set the selected organization and navigate to dashboard
              try {
                await _authService.selectOrganization(org.id);
                if (mounted) {
                  AppRouter.replaceWith(context, AppRouter.dashboard);
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed selecting organization: $e')),
                );
              }
            },
          ),
        ),
        fetchPage: _fetchOrgs,
        pageSize: 20,
        emptyMessage: 'No organizations found',
        errorMessage: 'Failed to load organizations',
        loadingMessage: 'Loading organizations...',
      ),
    );
  }
}
