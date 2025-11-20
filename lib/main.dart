import 'package:flutter/material.dart';
import 'app.dart';
import 'services/service_locator.dart';

export 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize the service locator before starting the app
  await setupLocator();
  runApp(const App());
}
