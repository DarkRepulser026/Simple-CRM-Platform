// Web-only implementation
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui_web;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:js' as js;

/// A widget that renders the Google Sign-In button using Google Identity Services for web.
/// Requires your Google Client ID.
class WebGoogleSignInButton extends StatefulWidget {
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
  State<WebGoogleSignInButton> createState() => _WebGoogleSignInButtonState();
}

class _WebGoogleSignInButtonState extends State<WebGoogleSignInButton> {
  late final String _viewType;
  bool _rendered = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _viewType = 'google-signin-btn-${widget.clientId.hashCode}-${DateTime.now().millisecondsSinceEpoch}';
    if (kIsWeb) {
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
        final div = html.DivElement();
        div.id = 'g_id_onload_${_viewType}';
        div.style.width = '100%';
        div.style.display = 'flex';
        div.style.justifyContent = 'center';
        div.style.margin = '16px 0';

        void renderButton() async {
          // Wait until google.accounts.id.initialize is available
          const int maxAttempts = 10;
          const Duration attemptDelay = Duration(milliseconds: 250);
          int attempts = 0;

          Future<bool> _isGoogleAccountsReady() async {
            try {
              if (!js.context.hasProperty('google')) return false;
              final dynamic google = js.context['google'];
              if (google == null) return false;
              if (!(google as dynamic).hasProperty('accounts')) return false;
              final dynamic accounts = google['accounts'];
              if (accounts == null) return false;
              return (accounts as dynamic).hasProperty('id') && (accounts['id'] != null) && (accounts['id'] as dynamic).hasProperty('initialize');
            } catch (_) {
              return false;
            }
          }

          while (attempts < maxAttempts) {
            final ready = await _isGoogleAccountsReady();
            if (ready) break;
            await Future.delayed(attemptDelay);
            attempts += 1;
          }

          try {
            // Final check before initialize and render
            if (!(js.context.hasProperty('google') && js.context['google'].hasProperty('accounts') && js.context['google']['accounts'].hasProperty('id'))) {
              throw 'Google Identity Services (google.accounts.id) not available';
            }

            // Prepare the JS options using allowInterop for the callback
            final options = js.JsObject.jsify({
              'client_id': widget.clientId,
              'callback': js.allowInterop((response) {
                final credential = js.JsObject.fromBrowserObject(response)['credential'];
                if (credential != null) {
                  widget.onSuccess?.call(credential);
                } else {
                  widget.onError?.call('No credential received');
                }
              }),
              'auto_select': false,
            });

            // Call nested JS methods on the google.accounts.id object
            final dynamic googleAccountsId = js.context['google']['accounts']['id'];
            googleAccountsId.callMethod('initialize', [options]);
            googleAccountsId.callMethod('renderButton', [div, js.JsObject.jsify({
              'theme': 'outline',
              'size': 'large',
              'width': 300,
            })]);

            if (!_rendered) {
              setState(() {
                _rendered = true;
                _error = null;
              });
            }
          } catch (e) {
            setState(() {
              _error = 'Failed to render Google Sign-In button: $e';
            });
            widget.onError?.call(_error!);
          }
        }

        // Load the Google Identity Services script if not already loaded
        final existingScript = html.document.getElementById('google-identity-services');
        if (existingScript == null) {
          final script = html.ScriptElement()
            ..id = 'google-identity-services'
            ..src = 'https://accounts.google.com/gsi/client'
            ..async = true;
          script.onError.listen((e) {
            setState(() {
              _error = 'Failed to load Google Identity Services script';
            });
            widget.onError?.call(_error!);
          });
          script.onLoad.listen((event) {
            renderButton();
          });
          html.document.body!.append(script);
        } else {
          // If script is already loaded, check if GIS is available
          if (js.context.hasProperty('google') && js.context['google'].hasProperty('accounts')) {
            renderButton();
          } else {
            existingScript.onLoad.listen((event) {
              renderButton();
            });
          }
        }

        // Fallback: if not rendered after 5 seconds, show error
        Future.delayed(const Duration(seconds: 5), () {
          if (!_rendered && mounted) {
            setState(() {
              _error = 'Google Sign-In button failed to load.';
            });
            widget.onError?.call(_error!);
          }
        });

        return div;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }
    if (_error != null) {
      return Container(
        height: 60,
        alignment: Alignment.center,
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }
    return SizedBox(
      height: 60,
      child: HtmlElementView(viewType: _viewType),
    );
  }
}
