import 'package:flutter/material.dart';

import '../models/drive_file_item.dart';
import '../models/drive_link.dart';
import '../services/drive_service.dart';
import '../widgets/password_dialog.dart';
import 'file_preview_screen.dart';

class FolderDetailScreen extends StatefulWidget {
  final DriveLink link;

  const FolderDetailScreen({super.key, required this.link});

  @override
  State<FolderDetailScreen> createState() => _FolderDetailScreenState();
}

class _FolderDetailScreenState extends State<FolderDetailScreen> {
  bool _loading = true;
  List<DriveFileItem> _files = [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() => _loading = true);
    final files = await DriveService.listFilesInFolder(widget.link.folderId);
    setState(() {
      _files = files.where((e) => e.isImage).toList();
      _loading = false;
    });
  }

  Future<void> _deleteFolder() async {
    final valid = await showPasswordDialog(context);
    if (!valid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong password')),
        );
      }
      return;
    }

    final ok = await DriveService.deleteFolder(widget.link.folderId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Folder deleted' : 'Failed to delete folder')),
    );

    if (ok) Navigator.pop(context);
  }

  Future<void> _deletePhoto(String fileId) async {
    final valid = await showPasswordDialog(context);
    if (!valid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong password')),
        );
      }
      return;
    }

    final ok = await DriveService.deleteFile(fileId);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Photo deleted' : 'Failed to delete photo')),
    );

    if (ok) {
      await _loadFiles();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF7F7F8),
        title: Text(
          widget.link.name,
          style: const TextStyle(color: Colors.black87),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete_folder') {
                _deleteFolder();
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(
                value: 'delete_folder',
                child: Text('Delete Folder'),
              ),
            ],
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Text(
                  '${_files.length} photos',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _loadFiles,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(
            child: _files.isEmpty
                ? const Center(
              child: Text(
                'No photos in this folder',
                style: TextStyle(color: Colors.black54),
              ),
            )
                : GridView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _files.length,
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                final file = _files[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FilePreviewScreen(file: file),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        file.thumbnailLink != null
                            ? Image.network(
                          file.thumbnailLink!,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _deletePhoto(file.id),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.delete,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}