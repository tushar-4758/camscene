import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;

import 'auth_service.dart';

class DriveService {
  static Future<drive.DriveApi?> _getApi() async {
    final client = await AuthService.getAuthClient();
    if (client == null) {
      debugPrint('Drive client is null');
      return null;
    }
    return drive.DriveApi(client);
  }

  static Future<bool> verifyFolder(String folderId) async {
    try {
      final api = await _getApi();
      if (api == null) return false;

      final file = await api.files.get(folderId) as drive.File;
      return file.mimeType == 'application/vnd.google-apps.folder';
    } catch (e) {
      debugPrint('verifyFolder error: $e');
      return false;
    }
  }

  static Future<drive.File?> createFolder({
    required String folderName,
    String? parentFolderId,
  }) async {
    try {
      final api = await _getApi();
      if (api == null) return null;

      final folder = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder'
        ..parents = parentFolderId != null ? [parentFolderId] : null;

      return await api.files.create(folder);
    } catch (e) {
      debugPrint('createFolder error: $e');
      return null;
    }
  }

  static Future<bool> uploadFile({
    required String filePath,
    required String folderId,
    String? fileName,
  }) async {
    try {
      final api = await _getApi();
      if (api == null) return false;

      final file = File(filePath);
      if (!file.existsSync()) return false;

      final driveFile = drive.File()
        ..name = fileName ?? 'IMG_${DateTime.now().millisecondsSinceEpoch}.jpg'
        ..parents = [folderId];

      final media = drive.Media(file.openRead(), file.lengthSync());

      final result = await api.files.create(
        driveFile,
        uploadMedia: media,
      );

      return result.id != null;
    } catch (e) {
      debugPrint('uploadFile error: $e');
      return false;
    }
  }
}