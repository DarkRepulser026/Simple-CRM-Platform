import 'dart:typed_data';

class PickedFile {
  final String name;
  final Uint8List bytes;
  final String? mimeType;
  PickedFile({required this.name, required this.bytes, this.mimeType});
}

Future<PickedFile?> pickFile() async {
  // Fallback stub - no-op for unrecognized platforms
  return null;
}
