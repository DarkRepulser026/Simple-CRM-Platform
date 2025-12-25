import 'package:flutter/material.dart';
import '../../widgets/loading_view.dart';
import '../../widgets/error_view.dart';
import '../../services/auth/auth_service.dart';
import '../../services/service_locator.dart';
import '../../services/organizations_service.dart';
import '../../models/organization.dart';
import '../../navigation/app_router.dart';

class CompanySelectionScreen extends StatefulWidget {
  const CompanySelectionScreen({super.key});

  @override
  State<CompanySelectionScreen> createState() => _CompanySelectionScreenState();
}

class _CompanySelectionScreenState extends State<CompanySelectionScreen> {
  late final AuthService _authService;
  bool _isLoading = true;
  String? _errorMessage;
  final TextEditingController _companyController = TextEditingController();
  List<Organization> _organizations = [];

  // Theme Colors
  final Color _primaryColor = const Color(0xFF0F172A);

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    _authService = locator<AuthService>();
    try {
      final orgService = locator<OrganizationsService>();
      final res = await orgService.getOrganizations(page: 1, limit: 50);
      if (res.isSuccess) {
        _organizations = res.value.organizations;
        // Optional: Auto-select if logic dictates
        if (_organizations.length == 1) {
          await _selectCompany(_organizations.first.id);
        }
      } else if (res.isError) {
        _errorMessage = res.error.message;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  Future<void> _selectCompany(String companyId) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      await _authService.selectOrganization(companyId);
      if (mounted) _navigateToDashboard();
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to select company: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createCompany() async {
    final companyName = _companyController.text.trim();
    if (companyName.isEmpty) return;
    
    // Close dialog first if open
    Navigator.of(context).pop(); 

    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final orgService = locator<OrganizationsService>();
      final result = await orgService.createOrganization(Organization(id: '', name: companyName));
      if (result.isSuccess) {
        await _selectCompany(result.value.id);
      } else {
        setState(() { _errorMessage = result.error.message; });
      }
    } catch (e) {
      setState(() { _errorMessage = e.toString(); });
    } finally {
      if(mounted && !_isLoading) setState(() { _isLoading = false; }); // check check
    }
  }

  void _showCreateDialog() {
    _companyController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Workspace'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter the name of your new organization.'),
            const SizedBox(height: 16),
            TextField(
              controller: _companyController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Organization Name',
                hintText: 'e.g. Acme Corp',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: _createCompany,
            child: const Text('Create & Join'),
          ),
        ],
      ),
    );
  }

  void _navigateToDashboard() {
    AppRouter.replaceWith(context, AppRouter.dashboard);
  }

  @override
  void dispose() {
    _companyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Slate 100
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
             Icon(Icons.grid_view_rounded, color: _primaryColor, size: 20),
             const SizedBox(width: 8),
             Text('Select Workspace', style: TextStyle(color: _primaryColor, fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () async {
              await _authService.logout();
              if (mounted) AppRouter.replaceWith(context, AppRouter.login);
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign Out'),
            style: TextButton.styleFrom(foregroundColor: Colors.grey[700]),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading && _organizations.isEmpty
          ? const Center(child: LoadingView(message: 'Loading workspaces...'))
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Text(
                        'Welcome back',
                        style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _primaryColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose an organization to continue to your dashboard.',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 32),

                      if (_errorMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          child: ErrorView(message: _errorMessage!, onRetry: null),
                        ),

                      // Grid of Organizations
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 300,
                            childAspectRatio: 1.3,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: _organizations.length + 1, // +1 for "Create New"
                          itemBuilder: (context, index) {
                            // "Create New" Card (Last Item)
                            if (index == _organizations.length) {
                              return _buildCreateNewCard();
                            }
                            // Organization Card
                            return _buildOrgCard(_organizations[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildOrgCard(Organization org) {
    final initial = org.name.isNotEmpty ? org.name[0].toUpperCase() : '?';
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: () => _selectCompany(org.id),
        borderRadius: BorderRadius.circular(16),
        hoverColor: Colors.blue.withOpacity(0.04),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE), // Light Blue
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0284C7),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Name
              Text(
                org.name,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // ID/Role Mockup
              Row(
                children: [
                  Text(
                    'Workspace',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward, size: 16, color: Colors.grey[400]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateNewCard() {
    return Card(
      elevation: 0,
      color: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade300, style: BorderStyle.none), // Or dashed
      ),
      child: InkWell(
        onTap: _showCreateDialog,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300, width: 2), // Simulate dashed
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline, size: 32, color: Colors.grey[600]),
                const SizedBox(height: 12),
                Text(
                  'Create New',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}