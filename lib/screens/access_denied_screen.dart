import 'package:flutter/material.dart';
import '../navigation/app_router.dart';

class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Access denied')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('You do not have access to this page.', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              ElevatedButton(onPressed: () => AppRouter.navigateTo(context, AppRouter.dashboard), child: const Text('Return to dashboard')),
            ],
          ),
        ),
      ),
    );
  }
}
