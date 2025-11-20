import 'dart:typed_data';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'picker_stub.dart';

Future<PickedFile?> pickFile() async {
  final res = await FilePicker.platform.pickFiles(withData: true);
  if (res == null || res.files.isEmpty) return null;
  final f = res.files.first;
  final bytes = f.bytes ?? (f.path != null ? await File(f.path!).readAsBytes() : Uint8List(0));
  final mime = f.extension != null ? 'application/${f.extension}' : null;
  return PickedFile(name: f.name, bytes: bytes, mimeType: mime);
}
