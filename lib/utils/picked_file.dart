import 'dart:typed_data';

class PickedFile {
  final String name;
  final Uint8List bytes;
  final String? mimeType;

  const PickedFile({
    required this.name,
    required this.bytes,
    this.mimeType,
  });
}
