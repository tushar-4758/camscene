import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;

import '../models/drive_file_item.dart';
import 'auth_service.dart';

class DriveService {
  static Future<drive.DriveApi?> _getApi() async {
    final client = await AuthService.getAuthClient();
    if (client == null) return null;
    return drive.DriveApi(client);
  }

  static Future<http.Client?> _getHttpClient() async {
    return await AuthService.getAuthClient();
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
        ..name = fileName ?? 'IMG_${DateTime
            .now()
            .millisecondsSinceEpoch}.jpg'
        ..parents = [folderId];

      final media = drive.Media(file.openRead(), file.lengthSync());
      final result = await api.files.create(driveFile, uploadMedia: media);
      return result.id != null;
    } catch (e) {
      debugPrint('uploadFile error: $e');
      return false;
    }
  }

  static Future<List<DriveFileItem>> listFilesInFolder(String folderId) async {
    try {
      final api = await _getApi();
      if (api == null) return [];

      final response = await api.files.list(
        q: "'$folderId' in parents and trashed = false",
        $fields:
        'files(id,name,thumbnailLink,webContentLink,mimeType,imageMediaMetadata)',
        orderBy: 'createdTime desc',
      );

      return (response.files ?? [])
          .map(
            (f) =>
            DriveFileItem(
              id: f.id ?? '',
              name: f.name ?? '',
              thumbnailLink: f.thumbnailLink,
              webContentLink: f.webContentLink,
              mimeType: f.mimeType,
            ),
      )
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('listFilesInFolder error: $e');
      return [];
    }
  }

  static Future<bool> deleteFile(String fileId) async {
    try {
      final api = await _getApi();
      if (api == null) return false;
      await api.files.delete(fileId);
      return true;
    } catch (e) {
      debugPrint('deleteFile error: $e');
      return false;
    }
  }

  static Future<bool> deleteFolder(String folderId) async {
    try {
      final api = await _getApi();
      if (api == null) return false;
      await api.files.delete(folderId);
      return true;
    } catch (e) {
      debugPrint('deleteFolder error: $e');
      return false;
    }
  }

  static Future<Uint8List?> getFileBytes(String fileId) async {
    try {
      final client = await _getHttpClient();
      if (client == null) return null;

      final url = Uri.parse(
        'https://www.googleapis.com/drive/v3/files/$fileId?alt=media',
      );

      final response = await client.get(url);

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('getFileBytes failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('getFileBytes error: $e');
      return null;
    }
  }

  static Future<List<drive.File>> listFolders() async {
    try {
      final api = await _getApi();
      if (api == null) return [];

      final response = await api.files.list(
        q: "mimeType='application/vnd.google-apps.folder' and trashed=false",
        $fields: "files(id,name)",
        supportsAllDrives: true,
        includeItemsFromAllDrives: true,
      );

      return response.files ?? [];
    } catch (e) {
      debugPrint("listFolders error: $e");
      return [];
    }
  }
}