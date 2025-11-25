import 'package:flutter/material.dart';
import '../navigation/app_router.dart';

class AccessDeniedRedirectScreen extends StatefulWidget {
  const AccessDeniedRedirectScreen({super.key});

  @override
  State<AccessDeniedRedirectScreen> createState() => _AccessDeniedRedirectScreenState();
}

class _AccessDeniedRedirectScreenState extends State<AccessDeniedRedirectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Access denied — redirecting to dashboard')));
      await Future.delayed(const Duration(milliseconds: 800));
      AppRouter.replaceWith(context, AppRouter.dashboard);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: Text('Redirecting...')),
    );
  }
}
