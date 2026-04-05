import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/links_provider.dart';
import 'add_link_screen.dart';

class ManageLinksScreen extends StatelessWidget {
  const ManageLinksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LinksProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Drive Folders',
          style: TextStyle(color: Colors.white),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddLinkScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: provider.links.isEmpty
          ? const Center(
        child: Text(
          'No links added',
          style: TextStyle(color: Colors.white70),
        ),
      )
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: provider.links.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final link = provider.links[index];
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => provider.selectLink(link.id),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: link.isSelected
                    ? const Color(0xFF24262A)
                    : const Color(0xFF18181B),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: link.isSelected
                      ? Colors.white
                      : const Color(0xFF2B2B30),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.folder_rounded,
                    color: link.isSelected ? Colors.white : Colors.white70,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                link.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: link.isVerified
                                    ? const Color(0xFF203320)
                                    : const Color(0xFF332020),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Text(
                                link.isVerified ? 'Verified' : 'Unknown',
                                style: TextStyle(
                                  color: link.isVerified
                                      ? const Color(0xFF7CFF87)
                                      : const Color(0xFFFF8A8A),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          link.folderId,
                          style: const TextStyle(
                            color: Color(0xFF9A9A9A),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}