// Native picker is intentionally disabled for web-only workflows. No imports required.
import 'picker_stub.dart';

Future<PickedFile?> pickFile() async {
  // Native picker not implemented in this project (web-only workflow).
  // This implementation intentionally returns null instead of requiring the file_picker plugin.
  // If native support is needed later, implement using `file_picker` or a suitable plugin.
  return null;
}
