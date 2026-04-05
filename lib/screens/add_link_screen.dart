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
  final _createFolderController = TextEditingController();
  final _existingNameController = TextEditingController();
  final _existingUrlController = TextEditingController();

  bool _creating = false;
  bool _verifying = false;
  bool _saving = false;
  bool _verified = false;
  String? _verifiedFolderId;
  bool _showExistingSection = false;

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _existingUrlController.text = data!.text!;
      setState(() {
        _verified = false;
        _verifiedFolderId = null;
      });
    }
  }

  Future<void> _createFolder() async {
    final name = _createFolderController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter folder name')),
      );
      return;
    }

    setState(() => _creating = true);

    final created = await DriveService.createFolder(folderName: name);

    if (created != null && created.id != null) {
      await context.read<LinksProvider>().addCreatedFolder(
        name: created.name ?? name,
        folderId: created.id!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Drive folder created successfully')),
        );
        Navigator.pop(context);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create folder')),
        );
      }
    }

    if (mounted) setState(() => _creating = false);
  }

  Future<void> _verifyExisting() async {
    final raw = _existingUrlController.text.trim();
    final folderId = DriveLink.extractFolderId(raw);

    if (folderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid folder link or ID')),
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
      SnackBar(content: Text(ok ? 'Folder verified' : 'Verification failed')),
    );
  }

  Future<void> _saveExisting() async {
    final name = _existingNameController.text.trim();
    final url = _existingUrlController.text.trim();

    if (name.isEmpty || url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fill all fields')),
      );
      return;
    }

    if (!_verified || _verifiedFolderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please verify folder first')),
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

    if (mounted) setState(() => _saving = false);
  }

  @override
  void dispose() {
    _createFolderController.dispose();
    _existingNameController.dispose();
    _existingUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detectedId = DriveLink.extractFolderId(_existingUrlController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add / Create Folder', style: TextStyle(color: Colors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Drive Folder',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use this for most cases',
                      style: TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _createFolderController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Folder name',
                        hintStyle: const TextStyle(color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0D1830),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _creating ? null : _createFolder,
                      icon: const Icon(Icons.create_new_folder_rounded),
                      label: Text(_creating ? 'Creating...' : 'Create Folder'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  ListTile(
                    title: const Text(
                      'Add Existing Drive Folder',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Rarely used option',
                      style: TextStyle(color: Colors.white54),
                    ),
                    trailing: Icon(
                      _showExistingSection
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.white,
                    ),
                    onTap: () {
                      setState(() {
                        _showExistingSection = !_showExistingSection;
                      });
                    },
                  ),
                  if (_showExistingSection)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: [
                          TextField(
                            controller: _existingNameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Folder display name',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF0D1830),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _existingUrlController,
                            maxLines: 3,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Paste Drive folder link or raw ID',
                              hintStyle: const TextStyle(color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF0D1830),
                              suffixIcon: IconButton(
                                onPressed: _paste,
                                icon: const Icon(Icons.paste, color: Colors.white),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (_) {
                              setState(() {
                                _verified = false;
                                _verifiedFolderId = null;
                              });
                            },
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              detectedId == null
                                  ? 'Folder ID not detected'
                                  : 'Detected ID: $detectedId',
                              style: TextStyle(
                                color: detectedId == null
                                    ? Colors.redAccent
                                    : Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _verifying ? null : _verifyExisting,
                            icon: const Icon(Icons.verified_rounded),
                            label: Text(_verifying ? 'Verifying...' : 'Verify Folder'),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton.icon(
                            onPressed: _saving ? null : _saveExisting,
                            icon: const Icon(Icons.save),
                            label: Text(_saving ? 'Saving...' : 'Save Existing Folder'),
                          ),
                          if (_verified)
                            const Padding(
                              padding: EdgeInsets.only(top: 10),
                              child: Text(
                                'Verified',
                                style: TextStyle(color: Colors.greenAccent),
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}