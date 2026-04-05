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
  final Set<String> _selectedIds = {};

  bool get selectionMode => _selectedIds.isNotEmpty;

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

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final valid = await showPasswordDialog(context);
    if (!valid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wrong password')),
        );
      }
      return;
    }

    bool anyFailed = false;

    for (final id in _selectedIds) {
      final ok = await DriveService.deleteFile(id);
      if (!ok) anyFailed = true;
    }

    if (!mounted) return;

    setState(() => _selectedIds.clear());
    await _loadFiles();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          anyFailed
              ? 'Some photos could not be deleted'
              : 'Selected photos deleted',
        ),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: Text(
          selectionMode ? '${_selectedIds.length} selected' : widget.link.name,
        ),
        actions: [
          if (selectionMode)
            IconButton(
              onPressed: _deleteSelected,
              icon: const Icon(Icons.delete),
            )
          else
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
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Row(
              children: [
                Text(
                  '${_files.length} photos',
                  style: const TextStyle(
                    color: Colors.black,
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
                final selected = _selectedIds.contains(file.id);

                return GestureDetector(
                  onLongPress: () => _toggleSelection(file.id),
                  onTap: () {
                    if (selectionMode) {
                      _toggleSelection(file.id);
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FilePreviewScreen(
                            files: _files,
                            initialIndex: index,
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: file.thumbnailLink != null
                            ? Image.network(
                          file.thumbnailLink!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) {
                            return Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image),
                            );
                          },
                        )
                            : Container(
                          color: Colors.grey.shade300,
                          child: const Icon(Icons.image),
                        ),
                      ),
                      if (selected)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
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