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
  bool _isUploadingBatch = false;

  List<UploadItem> get items => List.unmodifiable(_items);

  int get total => _items.length;
  int get successCount =>
      _items.where((e) => e.status == UploadItemStatus.success).length;
  int get failedCount =>
      _items.where((e) => e.status == UploadItemStatus.failed).length;
  int get pendingCount =>
      _items.where((e) => e.status == UploadItemStatus.pending).length;
  int get uploadingCount =>
      _items.where((e) => e.status == UploadItemStatus.uploading).length;

  bool get hasItems => _items.isNotEmpty;
  bool get isUploading => _isUploadingBatch;

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

  Future<void> triggerRollingUpload(String folderId) async {
    if (_isUploadingBatch) return;

    final pending = _items
        .where((e) => e.status == UploadItemStatus.pending)
        .take(5)
        .toList();

    if (pending.length < 5) return;
    await _uploadBatch(pending, folderId);
  }

  Future<void> submitAll(String folderId) async {
    while (true) {
      if (_isUploadingBatch) return;

      final pending = _items
          .where((e) => e.status == UploadItemStatus.pending)
          .take(5)
          .toList();

      if (pending.isEmpty) break;
      await _uploadBatch(pending, folderId);
    }
  }

  Future<void> retryFailed(String folderId) async {
    final failed = _items.where((e) => e.status == UploadItemStatus.failed).toList();
    for (final item in failed) {
      item.status = UploadItemStatus.pending;
    }
    notifyListeners();
    await submitAll(folderId);
  }

  Future<void> _uploadBatch(List<UploadItem> batch, String folderId) async {
    _isUploadingBatch = true;
    for (final item in batch) {
      item.status = UploadItemStatus.uploading;
    }
    notifyListeners();

    for (final item in batch) {
      final ok = await DriveService.uploadFile(
        filePath: item.path,
        folderId: folderId,
      );

      if (ok) {
        item.status = UploadItemStatus.success;
        try {
          final file = File(item.path);
          if (file.existsSync()) await file.delete();
        } catch (_) {}
      } else {
        item.status = UploadItemStatus.failed;
      }
      notifyListeners();
    }

    _isUploadingBatch = false;
    notifyListeners();
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
    _isUploadingBatch = false;
    notifyListeners();
  }
}