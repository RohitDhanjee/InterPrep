// lib/services/file_picker_service.dart

import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' as io;

class PickedFileData {
  final String? name;
  final String? path;
  final Uint8List? bytes;

  PickedFileData({this.name, this.path, this.bytes});
}

// This function abstracts the different picking behaviors of web and mobile/desktop.
Future<PickedFileData?> pickFileForPlatform({
  required FileType type,
  List<String>? allowedExtensions,
}) async {
  // We request file data (bytes) only for web and platform-specific info for others.
  final result = await FilePicker.platform.pickFiles(
    type: type,
    allowedExtensions: allowedExtensions,
    withData: kIsWeb,
    withReadStream: !kIsWeb,
  );

  if (result != null && result.files.single.name.isNotEmpty) {
    final platformFile = result.files.single;

    if (kIsWeb) {
      // WEB: use bytes
      return PickedFileData(
        name: platformFile.name,
        bytes: platformFile.bytes,
        path: null,
      );
    } else {
      // MOBILE/DESKTOP (Non-Web): use path
      return PickedFileData(
        name: platformFile.name,
        path: platformFile.path,
        bytes: null,
      );
    }
  }
  return null;
}

// Helper function to conditionally create a dart:io.File or return null.
io.File? getFileFromPath(String? path) {
  if (path != null && !kIsWeb) {
    return io.File(path);
  }
  return null;
}
