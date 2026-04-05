import 'dart:io';
import 'package:flutter/material.dart';
import '../services/drive_service.dart';

enum UploadItemStatus { pending, uploading, success, failed }

class UploadItem {
  final String id;
  final String path;
  UploadItemStatus status;

  UploadItem({
    required this.id,
    required this.path,
    this.status = UploadItemStatus.pending,
  });
}

class UploadProvider extends ChangeNotifier {
  final List<UploadItem> _items = [];
  bool _isUploading = false;

  List<UploadItem> get items => List.unmodifiable(_items);

  int get total => _items.length;
  int get successCount =>
      _items.where((e) => e.status == UploadItemStatus.success).length;
  int get failedCount =>
      _items.where((e) => e.status == UploadItemStatus.failed).length;
  int get pendingCount =>
      _items.where((e) =>
      e.status == UploadItemStatus.pending ||
          e.status == UploadItemStatus.uploading).length;

  bool get hasItems => _items.isNotEmpty;
  bool get isUploading => _isUploading;

  bool get hasUnfinished =>
      _items.any((e) =>
      e.status == UploadItemStatus.pending ||
          e.status == UploadItemStatus.uploading ||
          e.status == UploadItemStatus.failed);

  void addCapturedPhoto(String path) {
    _items.add(
      UploadItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        path: path,
      ),
    );
    notifyListeners();
  }

  Future<void> processQueue(String folderId) async {
    if (_isUploading) return;
    _isUploading = true;
    notifyListeners();

    while (true) {
      UploadItem? next;
      try {
        next = _items.firstWhere((e) => e.status == UploadItemStatus.pending);
      } catch (_) {
        next = null;
      }

      if (next == null) break;

      next.status = UploadItemStatus.uploading;
      notifyListeners();

      final ok = await DriveService.uploadFile(
        filePath: next.path,
        folderId: folderId,
      );

      if (ok) {
        next.status = UploadItemStatus.success;
        try {
          final file = File(next.path);
          if (file.existsSync()) await file.delete();
        } catch (_) {}
      } else {
        next.status = UploadItemStatus.failed;
      }

      notifyListeners();
    }

    _isUploading = false;
    notifyListeners();
  }

  Future<void> retryFailed(String folderId) async {
    for (final item in _items.where((e) => e.status == UploadItemStatus.failed)) {
      item.status = UploadItemStatus.pending;
    }
    notifyListeners();
    await processQueue(folderId);
  }

  void clearCompleted() {
    _items.removeWhere((e) => e.status == UploadItemStatus.success);
    notifyListeners();
  }

  void resetAll() {
    for (final item in _items) {
      try {
        final file = File(item.path);
        if (file.existsSync()) file.deleteSync();
      } catch (_) {}
    }
    _items.clear();
    _isUploading = false;
    notifyListeners();
  }
}