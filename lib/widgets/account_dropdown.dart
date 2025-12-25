import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/accounts_service.dart';
import '../services/service_locator.dart';

/// Reusable dropdown widget for selecting an account
///
/// Usage:
/// ```dart
/// AccountDropdown(
///   initialAccountId: ticket.accountId,
///   onChanged: (accountId) => setState(() => _accountId = accountId),
/// )
/// ```
class AccountDropdown extends StatefulWidget {
  final String? initialAccountId;
  final ValueChanged<String?> onChanged;
  final String? label;
  final String? hintText;
  final bool enabled;

  const AccountDropdown({
    super.key,
    this.initialAccountId,
    required this.onChanged,
    this.label,
    this.hintText,
    this.enabled = true,
  });

  @override
  State<AccountDropdown> createState() => _AccountDropdownState();
}

class _AccountDropdownState extends State<AccountDropdown> {
  List<Account> _accounts = [];
  bool _loading = true;
  String? _selectedAccountId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.initialAccountId;
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final accountsService = locator<AccountsService>();
    final result = await accountsService.getAccounts(limit: 100);

    if (result.isSuccess && mounted) {
      setState(() {
        _accounts = result.value.accounts;
        _loading = false;
      });
    } else if (mounted) {
      setState(() {
        _error = result.error.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label ?? 'Account',
          filled: true,
          fillColor: cs.surfaceVariant.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        child: const SizedBox(
          height: 20,
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return InputDecorator(
        decoration: InputDecoration(
          labelText: widget.label ?? 'Account',
          filled: true,
          fillColor: cs.errorContainer.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorText: _error,
        ),
        child: const SizedBox(height: 20),
      );
    }

    return DropdownButtonFormField<String>(
      value: _selectedAccountId,
      decoration: InputDecoration(
        labelText: widget.label ?? 'Account',
        hintText: widget.hintText ?? 'Select an account',
        filled: true,
        fillColor: cs.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.outline.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cs.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.all(16),
        prefixIcon: Icon(Icons.business_outlined, color: cs.primary),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('No account'),
        ),
        ..._accounts.map((account) {
          return DropdownMenuItem<String>(
            value: account.id,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primaryContainer,
                  child: Text(
                    account.name.isNotEmpty ? account.name[0].toUpperCase() : 'A',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    account.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
      onChanged: widget.enabled
          ? (value) {
              setState(() => _selectedAccountId = value);
              widget.onChanged(value);
            }
          : null,
      isExpanded: true,
    );
  }
}
