import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'auth_service.dart';

class DriveService {
  static Future<drive.DriveApi?> _getApi() async {
    final client = await AuthService.getAuthClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  static Future<bool> uploadFile({
    required String filePath,
    required String folderId,
  }) async {
    try {
      final api = await _getApi();
      if (api == null) return false;

      final file = File(filePath);
      if (!file.existsSync()) return false;

      final driveFile = drive.File()
        ..name = 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ..parents = [folderId];

      final media = drive.Media(
        file.openRead(),
        file.lengthSync(),
      );

      await api.files.create(driveFile, uploadMedia: media);
      return true;
    } catch (e) {
      debugPrint('Upload error: $e');
      return false;
    }
  }

  static Future<bool> verifyFolder(String folderId) async {
    try {
      final api = await _getApi();
      if (api == null) return false;
      await api.files.get(folderId);
      return true;
    } catch (e) {
      debugPrint('Verify folder error: $e');
      return false;
    }
  }
}