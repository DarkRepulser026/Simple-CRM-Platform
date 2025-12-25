import 'package:flutter/material.dart';

/// Main app shell that wraps authenticated content
class AppShell extends StatefulWidget {
  final Widget child;
  final bool showBreadcrumbs;

  const AppShell({
    super.key,
    required this.child,
    this.showBreadcrumbs = true,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
