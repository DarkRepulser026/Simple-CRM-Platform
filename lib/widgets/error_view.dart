import 'package:flutter/material.dart';

/// A reusable error view widget that shows error message with optional retry action
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryText = 'Try Again',
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryText;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(retryText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A compact error banner that can be shown at the top of screens
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              color: Theme.of(context).colorScheme.error,
            ),
        ],
      ),
    );
  }
}