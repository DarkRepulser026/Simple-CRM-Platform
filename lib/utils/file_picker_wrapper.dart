// Cross-platform file picker wrapper
// Uses dart:html for web and file_picker package for platforms where available
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Export a simple result structure that's stable between platforms
class PickedFile {
  final String name;
  final Uint8List bytes;
  final String? mimeType;
  PickedFile({required this.name, required this.bytes, this.mimeType});
}

/// High-level API to pick one file and return its bytes + filename.
Future<PickedFile?> pickFileWrapper() async {
  if (kIsWeb) {
    // Web implementation uses dart:html - avoid importing when not web
    return _pickFileWeb();
  } else {
    return _pickFileNative();
  }
}

// Deferred imports handled below via conditional imports
import 'file_picker_wrapper_web.dart' if (dart.library.html) 'file_picker_wrapper_web.dart';
import 'file_picker_wrapper_native.dart' if (!dart.library.html) 'file_picker_wrapper_native.dart';
