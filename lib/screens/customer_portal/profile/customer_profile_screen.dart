import 'package:flutter/material.dart';
import '../../../navigation/app_router.dart';
import '../../../services/auth/customer_auth_service.dart';
import '../../../services/service_locator.dart';
import '../../../models/customer_auth.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  bool _isLoading = true;
  CustomerUser? _currentCustomer;
  bool _hasInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_hasInitialized) {
      _hasInitialized = true;
      // Defer the load until after the current build phase completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadProfile();
      });
    }
  }

  Future<void> _loadProfile() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final authService = locator<CustomerAuthService>();
      final customer = authService.currentCustomer;
      
      if (customer == null) {
        // Not logged in, redirect to login
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/customer-login');
        }
        return;
      }

      if (mounted) {
        setState(() {
          _currentCustomer = customer;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final authService = locator<CustomerAuthService>();
      await authService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/customer-login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentCustomer == null
              ? const Center(child: Text('Failed to load profile'))
              : RefreshIndicator(
                  onRefresh: _loadProfile,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Profile Header
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: colorScheme.primaryContainer,
                                child: Text(
                                  _currentCustomer!.name
                                      .split(' ')
                                      .map((n) => n.isNotEmpty ? n[0] : '')
                                      .take(2)
                                      .join()
                                      .toUpperCase(),
                                  style: theme.textTheme.headlineMedium
                                      ?.copyWith(
                                    color: colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _currentCustomer!.name,
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _currentCustomer!.email,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Contact Information
                      _SectionHeader(title: 'Contact Information'),
                      Card(
                        child: Column(
                          children: [
                            _InfoTile(
                              icon: Icons.business,
                              label: 'Company',
                              value: _currentCustomer!.companyName ?? 'Not provided',
                            ),
                            const Divider(height: 1),
                            _InfoTile(
                              icon: Icons.phone,
                              label: 'Phone',
                              value: _currentCustomer!.phone ?? 'Not provided',
                            ),
                            const Divider(height: 1),
                            _InfoTile(
                              icon: Icons.email,
                              label: 'Email',
                              value: _currentCustomer!.email,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Actions
                      _SectionHeader(title: 'Account'),
                      Card(
                        child: Column(
                          children: [
                            ListTile(
                              leading: const Icon(Icons.edit),
                              title: const Text('Edit Profile'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                AppRouter.navigateTo(
                                  context,
                                  AppRouter.customerEditProfile,
                                );
                              },
                            ),
                            const Divider(height: 1),
                            ListTile(
                              leading: const Icon(Icons.lock),
                              title: const Text('Change Password'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () {
                                AppRouter.navigateTo(
                                  context,
                                  AppRouter.customerChangePassword,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Logout Button
                      FilledButton.tonal(
                        onPressed: _logout,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(
        value,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
