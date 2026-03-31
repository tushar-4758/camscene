import 'dart:io';
import 'package:flutter/material.dart';

import '../services/drive_service.dart';

enum UploadStatus { uploading, success, failed }

class UploadItem {
  final String id;
  final String tempPath;
  UploadStatus status;

  UploadItem({
    required this.id,
    required this.tempPath,
    this.status = UploadStatus.uploading,
  });
}

class UploadProvider extends ChangeNotifier {
  final List<UploadItem> _items = [];

  List<UploadItem> get items => List.unmodifiable(_items);
  int get total => _items.length;
  int get successCount =>
      _items.where((e) => e.status == UploadStatus.success).length;
  int get failedCount =>
      _items.where((e) => e.status == UploadStatus.failed).length;
  bool get hasItems => _items.isNotEmpty;
  bool get isUploading =>
      _items.any((e) => e.status == UploadStatus.uploading);

  Future<void> addAndUpload({
    required String path,
    required String folderId,
  }) async {
    final item = UploadItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      tempPath: path,
    );

    _items.add(item);
    notifyListeners();

    final ok = await DriveService.uploadFile(
      filePath: path,
      folderId: folderId,
    );

    if (ok) {
      item.status = UploadStatus.success;
      _deleteTempFile(path);
    } else {
      item.status = UploadStatus.failed;
    }

    notifyListeners();
  }

  Future<void> retryFailed(String folderId) async {
    final failed =
    _items.where((e) => e.status == UploadStatus.failed).toList();

    for (final item in failed) {
      item.status = UploadStatus.uploading;
      notifyListeners();

      final ok = await DriveService.uploadFile(
        filePath: item.tempPath,
        folderId: folderId,
      );

      if (ok) {
        item.status = UploadStatus.success;
        _deleteTempFile(item.tempPath);
      } else {
        item.status = UploadStatus.failed;
      }
      notifyListeners();
    }
  }

  void _deleteTempFile(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (e) {
      debugPrint('Delete temp error: $e');
    }
  }

  void clearAll() {
    _items.clear();
    notifyListeners();
  }
}