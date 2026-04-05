import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/drive_link.dart';
import '../providers/links_provider.dart';
import '../services/drive_service.dart';

class AddLinkScreen extends StatefulWidget {
  const AddLinkScreen({super.key});

  @override
  State<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends State<AddLinkScreen> {
  final _nameController = TextEditingController();
  final _urlController = TextEditingController();
  final _createFolderController = TextEditingController();

  bool _saving = false;
  bool _verifying = false;
  bool _creating = false;
  bool _verified = false;
  String? _verifiedFolderId;

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _urlController.text = data!.text!;
      setState(() {
        _verified = false;
        _verifiedFolderId = null;
      });
    }
  }

  Future<void> _verifyFolder() async {
    final raw = _urlController.text.trim();
    final folderId = DriveLink.extractFolderId(raw);

    if (folderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Drive folder link or ID')),
      );
      return;
    }

    setState(() {
      _verifying = true;
      _verified = false;
      _verifiedFolderId = null;
    });

    final ok = await DriveService.verifyFolder(folderId);

    setState(() {
      _verifying = false;
      _verified = ok;
      _verifiedFolderId = ok ? folderId : null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Folder verified successfully' : 'Folder verification failed'),
      ),
    );
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final url = _urlController.text.trim();

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill both fields')),
      );
      return;
    }

    if (!_verified || _verifiedFolderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify folder before saving')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      await context.read<LinksProvider>().addLink(
        name: name,
        url: url,
        isVerified: true,
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    if (mounted) {
      setState(() => _saving = false);
    }
  }

  Future<void> _createFolderInDrive() async {
    final folderName = _createFolderController.text.trim();

    if (folderName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter folder name first')),
      );
      return;
    }

    setState(() => _creating = true);

    final created = await DriveService.createFolder(folderName: folderName);

    if (created != null && created.id != null) {
      await context.read<LinksProvider>().addCreatedFolder(
        name: created.name ?? folderName,
        folderId: created.id!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drive folder created successfully')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create folder')),
        );
      }
    }

    if (mounted) {
      setState(() => _creating = false);
      _createFolderController.clear();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _createFolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detectedFolderId = DriveLink.extractFolderId(_urlController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add / Create Folder',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create new Drive folder',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _createFolderController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'New folder name',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF18181B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF2A2A2E)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _creating ? null : _createFolderInDrive,
              icon: const Icon(Icons.create_new_folder_rounded),
              label: Text(_creating ? 'Creating...' : 'Create Drive Folder'),
            ),
            const SizedBox(height: 28),
            const Divider(color: Color(0xFF2C2C30)),
            const SizedBox(height: 20),
            const Text(
              'Add existing Drive folder',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Folder name',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF18181B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF2A2A2E)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlController,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Drive folder link / raw folder ID',
                labelStyle: const TextStyle(color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF18181B),
                suffixIcon: IconButton(
                  onPressed: _paste,
                  icon: const Icon(Icons.paste_rounded, color: Colors.white),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: Color(0xFF2A2A2E)),
                ),
              ),
              onChanged: (_) {
                setState(() {
                  _verified = false;
                  _verifiedFolderId = null;
                });
              },
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    detectedFolderId == null
                        ? 'Folder ID not detected'
                        : 'Detected Folder ID: $detectedFolderId',
                    style: TextStyle(
                      color: detectedFolderId == null
                          ? Colors.redAccent
                          : Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (_verified)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF203320),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: const Text(
                      'Verified',
                      style: TextStyle(
                        color: Color(0xFF7CFF87),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _verifying ? null : _verifyFolder,
              icon: const Icon(Icons.verified_rounded),
              label: Text(_verifying ? 'Verifying...' : 'Verify Folder'),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving...' : 'Save Folder'),
            ),
          ],
        ),
      ),
    );
  }
}