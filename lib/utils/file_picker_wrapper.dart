// // Cross-platform file picker wrapper
// // Uses dart:html for web and file_picker package for platforms where available
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';

// // Export a simple result structure that's stable between platforms
// class PickedFile {
//   final String name;
//   final Uint8List bytes;
//   final String? mimeType;
//   PickedFile({required this.name, required this.bytes, this.mimeType});
// }

// /// High-level API to pick one file and return its bytes + filename.
// Future<PickedFile?> pickFileWrapper() async {
//   if (kIsWeb) {
//     // Web implementation uses dart:html - avoid importing when not web
//     return _pickFileWeb();
//   } else {
//     return _pickFileNative();
//   }
// }

// // Deferred imports handled below via conditional imports
// import 'file_picker_wrapper_web.dart' if (dart.library.html) 'file_picker_wrapper_web.dart';
// import 'file_picker_wrapper_native.dart' if (!dart.library.html) 'file_picker_wrapper_native.dart';

// file_picker_wrapper.dart
// Cross-platform file picker wrapper.
// Dùng conditional import để chọn implementation theo nền tảng.

// import 'dart:typed_data';

// // Mặc định dùng native implementation,
// // nếu compile cho web (có dart.library.html) thì dùng file web.
// import 'file_picker_wrapper_native.dart'
//     if (dart.library.html) 'file_picker_wrapper_web.dart';

// // Kết quả trả về thống nhất giữa các nền tảng
// class PickedFile {
//   final String name;
//   final Uint8List bytes;
//   final String? mimeType;

//   PickedFile({
//     required this.name,
//     required this.bytes,
//     this.mimeType,
//   });
// }

// /// API cấp cao: chọn 1 file, trả về bytes + tên file
// Future<PickedFile?> pickFileWrapper() {
//   // Hàm này sẽ được hiện thực trong file_picker_wrapper_native.dart
//   // hoặc file_picker_wrapper_web.dart tuỳ nền tảng.
//   return pickFileImpl();
// }

import 'picked_file.dart';

// Mặc định import native, nếu build web (có dart.library.html) thì thay bằng web.
import 'file_picker_wrapper_native.dart'
    if (dart.library.html) 'file_picker_wrapper_web.dart';

Future<PickedFile?> pickFileWrapper() {
  return pickFileImpl(); // hàm này sẽ đến từ file native hoặc web ở trên
}

