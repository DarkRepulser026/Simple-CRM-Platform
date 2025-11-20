// Conditional export: exports generic API implemented by platform-specific files
export 'picker_stub.dart'
  if (dart.library.html) 'picker_web.dart'
  if (dart.library.io) 'picker_native.dart';
