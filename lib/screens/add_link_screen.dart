import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/drive_link.dart';
import '../providers/links_provider.dart';

class AddLinkScreen extends StatefulWidget {
  final DriveLink? editLink;

  const AddLinkScreen({super.key, this.editLink});

  @override
  State<AddLinkScreen> createState() => _AddLinkScreenState();
}

class _AddLinkScreenState extends State<AddLinkScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _urlCtrl;
  bool _saving = false;

  bool get _isEdit => widget.editLink != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.editLink?.name ?? '');
    _urlCtrl = TextEditingController(text: widget.editLink?.url ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData('text/plain');
    if (data?.text != null) {
      _urlCtrl.text = data!.text!;
      setState(() {});
    }
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final url = _urlCtrl.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter folder name')),
      );
      return;
    }

    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter Drive folder link')),
      );
      return;
    }

    final folderId = DriveLink.extractFolderId(url);
    if (folderId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid Drive folder link')),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final provider = context.read<LinksProvider>();
      if (_isEdit) {
        await provider.updateLink(
          id: widget.editLink!.id,
          name: name,
          url: url,
        );
      } else {
        await provider.addLink(name: name, url: url);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }

    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final folderId = DriveLink.extractFolderId(_urlCtrl.text);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Link' : 'Add Drive Link'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info
            Card(
              color: cs.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        color: cs.onSecondaryContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Paste a Google Drive folder link.\n'
                            'Make sure your Google account has edit access to the folder.',
                        style: TextStyle(
                          color: cs.onSecondaryContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Name field
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Folder Name',
                hintText: 'e.g. Wedding, Office Work...',
                prefixIcon: Icon(Icons.label_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // URL field
            TextField(
              controller: _urlCtrl,
              maxLines: 3,
              minLines: 1,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Drive Folder Link',
                hintText: 'https://drive.google.com/drive/folders/...',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.paste),
                  onPressed: _paste,
                ),
                border: const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 8),

            // Folder ID preview
            if (_urlCtrl.text.isNotEmpty)
              Row(
                children: [
                  Icon(
                    folderId != null ? Icons.check_circle : Icons.error,
                    size: 16,
                    color: folderId != null ? Colors.green : cs.error,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      folderId != null
                          ? 'Folder ID: $folderId'
                          : 'Cannot read folder ID from this link',
                      style: TextStyle(
                        fontSize: 12,
                        color: folderId != null ? Colors.green : cs.error,
                      ),
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 32),

            // Save button
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.save),
              label: Text(_isEdit ? 'Update' : 'Save'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}