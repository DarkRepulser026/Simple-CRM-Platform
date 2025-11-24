// // Web-specific file picker implementation
// import 'dart:async';
// import 'dart:typed_data';
// import 'dart:html' as html;
// import 'file_picker_wrapper.dart' show PickedFile;

// Future<PickedFile?> _pickFileWeb() async {
//   final input = html.FileUploadInputElement();
//   input.accept = '*/*';
//   input.multiple = false;
//   input.click();
//   final completer = Completer<PickedFile?>();
//   input.onChange.listen((_) async {
//     final files = input.files;
//     if (files == null || files.isEmpty) {
//       completer.complete(null);
//       return;
//     }
//     final file = files.first;
//     final reader = html.FileReader();
//     reader.readAsArrayBuffer(file);
//     reader.onLoadEnd.listen((event) {
//       final array = reader.result as ByteBuffer;
//       final bytes = Uint8List.view(array);
//       final mime = file.type;
//       completer.complete(PickedFile(name: file.name, bytes: bytes, mimeType: mime));
//     });
//     reader.onError.listen((err) {
//       completer.completeError(err);
//     });
//   });
//   return completer.future;
// }

import 'dart:async';
import 'dart:typed_data';
import 'dart:html' as html;

import 'picked_file.dart';

Future<PickedFile?> pickFileImpl() async {
  final completer = Completer<PickedFile?>();

  final input = html.FileUploadInputElement();
  input.accept = '*/*';
  input.multiple = false;
  input.click();

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      completer.complete(null);
      return;
    }

    final file = files.first;
    final reader = html.FileReader();

    reader.readAsArrayBuffer(file);

    reader.onLoadEnd.listen((event) {
      final buffer = reader.result as ByteBuffer;
      final bytes = Uint8List.view(buffer);
      final mime = file.type;

      completer.complete(
        PickedFile(
          name: file.name,
          bytes: bytes,
          mimeType: mime,
        ),
      );
    });

    reader.onError.listen((err) {
      completer.completeError(err);
    });
  });

  return completer.future;
}
