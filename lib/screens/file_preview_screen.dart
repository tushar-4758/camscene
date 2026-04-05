import 'package:flutter/material.dart';
import '../models/drive_file_item.dart';

class FilePreviewScreen extends StatelessWidget {
  final DriveFileItem file;

  const FilePreviewScreen({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final imageUrl = file.webContentLink ?? file.thumbnailLink;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(file.name),
      ),
      body: Center(
        child: imageUrl != null
            ? InteractiveViewer(
          child: Image.network(imageUrl),
        )
            : const Text(
          'Preview not available',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}