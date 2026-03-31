import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drive_link.dart';
import '../providers/links_provider.dart';
import 'add_link_screen.dart';

class ManageLinksScreen extends StatelessWidget {
  const ManageLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LinksProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Drive Folders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddLinkScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Link'),
      ),
      body: provider.links.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.folder_off, size: 64, color: cs.outline),
            const SizedBox(height: 16),
            const Text('No folders added yet'),
            const SizedBox(height: 8),
            const Text('Tap + to add a Drive folder'),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: provider.links.length,
        itemBuilder: (context, index) {
          final link = provider.links[index];
          return _LinkTile(
            link: link,
            onSelect: () => provider.selectLink(link.id),
            onDelete: () => _confirmDelete(context, provider, link),
          );
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context,
      LinksProvider provider,
      DriveLink link,
      ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete folder?'),
        content: Text('Remove "${link.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              provider.deleteLink(link.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  final DriveLink link;
  final VoidCallback onSelect;
  final VoidCallback onDelete;

  const _LinkTile({
    required this.link,
    required this.onSelect,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      color: link.isSelected ? cs.primaryContainer : null,
      child: ListTile(
        leading: Icon(
          link.isSelected ? Icons.folder_special : Icons.folder,
          color: link.isSelected ? cs.primary : cs.outline,
        ),
        title: Text(
          link.name,
          style: TextStyle(
            fontWeight:
            link.isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          link.folderId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (link.isSelected)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: onDelete,
            ),
          ],
        ),
        onTap: onSelect,
      ),
    );
  }
}