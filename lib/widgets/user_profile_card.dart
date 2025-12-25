import 'package:flutter/material.dart';
import '../models/user.dart';

/// A comprehensive user profile card widget that displays all user information
/// with an elegant layout showing avatar, contact info, status, timestamps, etc.
class UserProfileCard extends StatelessWidget {
  final User user;
  final VoidCallback? onEditPressed;
  final VoidCallback? onMorePressed;
  final bool showActions;

  const UserProfileCard({
    super.key,
    required this.user,
    this.onEditPressed,
    this.onMorePressed,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outline.withOpacity(0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header section with avatar and basic info
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 48,
                  backgroundColor: colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Name
                Text(
                  user.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),

                // Email
                Text(
                  user.email,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),

                // Status and Role badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStatusBadge(context, user.isActive),
                    const SizedBox(width: 12),
                    if (user.role != null)
                      _buildRoleBadge(context, user.role!),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Details section
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User ID
                _buildDetailItem(
                  context,
                  icon: Icons.person_outline,
                  label: 'User ID',
                  value: user.id,
                ),
                const SizedBox(height: 16),

                // Google ID (if available)
                if (user.googleId != null) ...[
                  _buildDetailItem(
                    context,
                    icon: Icons.verified_user_outlined,
                    label: 'Google ID',
                    value: user.googleId!,
                  ),
                  const SizedBox(height: 16),
                ],

                // Token Version
                _buildDetailItem(
                  context,
                  icon: Icons.vpn_key_outlined,
                  label: 'Token Version',
                  value: user.tokenVersion.toString(),
                ),
                const SizedBox(height: 16),

                // Created At
                if (user.createdAt != null)
                  _buildDetailItem(
                    context,
                    icon: Icons.event_note_outlined,
                    label: 'Member Since',
                    value: _formatDateTime(user.createdAt!),
                  ),

                if (user.createdAt != null) const SizedBox(height: 16),

                // Updated At
                if (user.updatedAt != null)
                  _buildDetailItem(
                    context,
                    icon: Icons.update_outlined,
                    label: 'Last Updated',
                    value: _formatDateTime(user.updatedAt!),
                  ),
              ],
            ),
          ),

          // Action buttons
          if (showActions)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onEditPressed != null)
                    FilledButton.icon(
                      onPressed: onEditPressed,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                  if (onMorePressed != null) ...[
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: onMorePressed,
                      icon: const Icon(Icons.more_horiz, size: 18),
                      label: const Text('More'),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Build a detail item with icon, label, and value
  Widget _buildDetailItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Build status badge (Active/Inactive)
  Widget _buildStatusBadge(BuildContext context, bool isActive) {
    final color = isActive ? Colors.green : Colors.red;
    final bgColor = isActive
        ? Colors.green.withOpacity(0.12)
        : Colors.red.withOpacity(0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            isActive ? 'Active' : 'Inactive',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// Build role badge
  Widget _buildRoleBadge(BuildContext context, String role) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.security_outlined,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            role,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  /// Format DateTime to readable string
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

/// A compact version of the user profile card for list/grid views
class UserProfileCardCompact extends StatelessWidget {
  final User user;
  final VoidCallback? onTap;

  const UserProfileCardCompact({
    super.key,
    required this.user,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outline.withOpacity(0.08),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorScheme.primary.withOpacity(0.2),
                  child: Text(
                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: user.isActive
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      user.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color:
                            user.isActive ? Colors.green[700] : Colors.red[700],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (user.role != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        user.role!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
