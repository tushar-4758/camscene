import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/drive_file_item.dart';
import '../services/drive_service.dart';

class FilePreviewScreen extends StatefulWidget {
  final DriveFileItem file;

  const FilePreviewScreen({super.key, required this.file});

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _loading = true;
      _failed = false;
    });

    final bytes = await DriveService.getFileBytes(widget.file.id);

    if (!mounted) return;

    setState(() {
      _bytes = bytes;
      _loading = false;
      _failed = bytes == null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.file.name,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            onPressed: _loadImage,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator(color: Colors.white)
            : _failed
            ? Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.broken_image,
                color: Colors.white70, size: 60),
            const SizedBox(height: 12),
            const Text(
              'Image preview unavailable',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadImage,
              child: const Text('Retry'),
            ),
          ],
        )
            : InteractiveViewer(
          minScale: 0.5,
          maxScale: 5,
          child: Image.memory(
            _bytes!,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}