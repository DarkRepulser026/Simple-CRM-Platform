import 'package:flutter/material.dart';

/// Non-web stub for `WebGoogleSignInButton` — returns empty widget for non-web platforms.
class WebGoogleSignInButton extends StatelessWidget {
  final String clientId;
  final void Function(String idToken)? onSuccess;
  final void Function(String error)? onError;

  const WebGoogleSignInButton({
    Key? key,
    required this.clientId,
    this.onSuccess,
    this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Pluggable: for non-web, the regular GoogleSignIn button is used elsewhere
    return const SizedBox.shrink();
  }
}
