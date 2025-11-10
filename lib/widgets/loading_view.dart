import 'package:flutter/material.dart';

/// A reusable loading view widget that shows a loading indicator with optional message
class LoadingView extends StatelessWidget {
  const LoadingView({
    super.key,
    this.message = 'Loading...',
    this.size = 40.0,
  });

  final String message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// A full-screen loading overlay that can be shown over existing content
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
    this.message = 'Loading...',
  });

  final bool isLoading;
  final Widget child;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withOpacity(0.5),
            child: LoadingView(message: message),
          ),
      ],
    );
  }
}