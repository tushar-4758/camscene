import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/links_provider.dart';
import 'add_link_screen.dart';
import 'folder_detail_screen.dart';

class ManageLinksScreen extends StatefulWidget {
  const ManageLinksScreen({super.key});

  @override
  State<ManageLinksScreen> createState() => _ManageLinksScreenState();
}

class _ManageLinksScreenState extends State<ManageLinksScreen> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LinksProvider>();

    final filtered = provider.links
        .where((e) => e.name.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Drive Folders', style: TextStyle(color: Colors.white)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF081120),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLinkScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Column(
          children: [
            TextField(
              onChanged: (v) => setState(() => query = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search folder by name',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: const Color(0xFF10203B),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                child: Text(
                  'No folders found',
                  style: TextStyle(color: Colors.white70),
                ),
              )
                  : ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final link = filtered[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () async {
                      await provider.selectLink(link.id);
                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FolderDetailScreen(link: link),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: link.isSelected
                            ? const Color(0xFF16315B)
                            : const Color(0xFF10203B),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: link.isSelected
                              ? Colors.white
                              : const Color(0xFF1E335A),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C315A),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.folder_rounded, color: Colors.white),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              link.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          if (link.isVerified)
                            const Icon(Icons.verified, color: Colors.greenAccent),
                          if (link.isSelected)
                            const Padding(
                              padding: EdgeInsets.only(left: 8),
                              child: Icon(Icons.check_circle, color: Colors.white),
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
      ),
    );
  }
}