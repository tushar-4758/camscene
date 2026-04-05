import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/drive_file_item.dart';
import '../services/drive_service.dart';

class FilePreviewScreen extends StatefulWidget {
  final List<DriveFileItem> files;
  final int initialIndex;

  const FilePreviewScreen({
    super.key,
    required this.files,
    required this.initialIndex,
  });

  @override
  State<FilePreviewScreen> createState() => _FilePreviewScreenState();
}

class _FilePreviewScreenState extends State<FilePreviewScreen> {
  late final PageController _pageController;
  late int _currentIndex;

  Uint8List? _bytes;
  bool _loading = true;
  bool _failed = false;

  DriveFileItem get currentFile => widget.files[_currentIndex];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() {
      _loading = true;
      _failed = false;
      _bytes = null;
    });

    final bytes = await DriveService.getFileBytes(currentFile.id);

    if (!mounted) return;

    setState(() {
      _bytes = bytes;
      _loading = false;
      _failed = bytes == null;
    });
  }

  Future<void> _onPageChanged(int index) async {
    setState(() {
      _currentIndex = index;
    });
    await _loadImage();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildImagePage() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    if (_failed || _bytes == null) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, color: Colors.white70, size: 60),
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
      );
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 5,
      child: Center(
        child: Image.memory(
          _bytes!,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          currentFile.name,
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
      body: PageView.builder(
        controller: _pageController,
        itemCount: widget.files.length,
        onPageChanged: _onPageChanged,
        itemBuilder: (context, index) {
          if (index != _currentIndex) {
            final thumb = widget.files[index].thumbnailLink;
            return Center(
              child: thumb != null
                  ? InteractiveViewer(
                child: Image.network(
                  thumb,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              )
                  : const Icon(Icons.image, color: Colors.white, size: 60),
            );
          }

          return Center(child: _buildImagePage());
        },
      ),
    );
  }
}