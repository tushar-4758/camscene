import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/links_provider.dart';
import '../providers/upload_provider.dart';
import 'add_link_screen.dart';
import 'camera_screen.dart';
import 'manage_links_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final links = context.watch<LinksProvider>();
    final uploads = context.watch<UploadProvider>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    if (!auth.isSignedIn) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                const Icon(Icons.camera_alt_rounded, size: 90, color: Colors.white),
                const SizedBox(height: 18),
                const Text(
                  'CamScene',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Capture. Queue. Upload.',
                  style: TextStyle(color: Color(0xFFB8B8B8), fontSize: 15),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => auth.signIn(),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      );
    }

    final selectedLink = links.activeLink;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopHeader(
                email: auth.email,
                photoUrl: auth.photoUrl,
                onLogout: () => auth.signOut(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Active Destination',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              if (selectedLink != null)
                _ActiveFolderCard(
                  name: selectedLink.name,
                  folderId: selectedLink.folderId,
                  isVerified: selectedLink.isVerified,
                )
              else
                const _NoFolderCard(),
              const SizedBox(height: 18),
              if (uploads.hasItems)
                _PendingStatusCard(
                  total: uploads.total,
                  success: uploads.successCount,
                  failed: uploads.failedCount,
                ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                onPressed: selectedLink == null
                    ? null
                    : () {
                  if (uploads.hasUnfinished) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Upload pending photos first before starting next session',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CameraScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Open Camera'),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddLinkScreen()),
                  );
                },
                icon: const Icon(Icons.add_link_rounded),
                label: const Text('Add or Create Folder'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF121214),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFF232327)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Saved Drive Folders',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: links.links.isEmpty
                            ? const Center(
                          child: Text(
                            'No folder added yet',
                            style: TextStyle(color: Color(0xFF909090)),
                          ),
                        )
                            : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          itemCount: links.links.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final link = links.links[index];
                            return _FolderCard(
                              name: link.name,
                              folderId: link.folderId,
                              isSelected: link.isSelected,
                              isVerified: link.isVerified,
                              onTap: () => links.selectLink(link.id),
                              onDelete: () => links.deleteLink(link.id),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ManageLinksScreen()),
                    );
                  },
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('Manage Drive Links'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopHeader extends StatelessWidget {
  final String email;
  final String? photoUrl;
  final VoidCallback onLogout;

  const _TopHeader({
    required this.email,
    required this.photoUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CamScene',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Smart rolling upload workflow',
                style: TextStyle(color: Color(0xFF9D9D9D), fontSize: 13),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: const Color(0xFF1B1B1D),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              builder: (_) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: const Color(0xFF2C2C30),
                        backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl!) : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 18),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          onLogout();
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('Logout'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          child: CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFF2A2A2E),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? const Icon(Icons.person, color: Colors.white)
                : null,
          ),
        ),
      ],
    );
  }
}

class _ActiveFolderCard extends StatelessWidget {
  final String name;
  final String folderId;
  final bool isVerified;

  const _ActiveFolderCard({
    required this.name,
    required this.folderId,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.folder_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    folderId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFA5A5A5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF203320),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Text(
                    'Active',
                    style: TextStyle(
                      color: Color(0xFF7CFF87),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: isVerified
                        ? const Color(0xFF203320)
                        : const Color(0xFF332020),
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: Text(
                    isVerified ? 'Verified' : 'Unknown',
                    style: TextStyle(
                      color: isVerified
                          ? const Color(0xFF7CFF87)
                          : const Color(0xFFFF8A8A),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

class _NoFolderCard extends StatelessWidget {
  const _NoFolderCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.folder_off_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No folder selected',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add and select a Drive folder to continue',
                    style: TextStyle(color: Color(0xFFA0A0A0), fontSize: 12),
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

class _PendingStatusCard extends StatelessWidget {
  final int total;
  final int success;
  final int failed;

  const _PendingStatusCard({
    required this.total,
    required this.success,
    required this.failed,
  });

  @override
  Widget build(BuildContext context) {
    final pending = total - success - failed;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.cloud_upload_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Captured: $total  •  Uploaded: $success  •  Pending: $pending  •  Failed: $failed',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String name;
  final String folderId;
  final bool isSelected;
  final bool isVerified;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _FolderCard({
    required this.name,
    required this.folderId,
    required this.isSelected,
    required this.isVerified,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF24262A) : const Color(0xFF18181B),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.white : const Color(0xFF2B2B30),
            width: isSelected ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : const Color(0xFF2A2A2E),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.folder_rounded,
                color: isSelected ? Colors.black : Colors.white,
              ),
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
                          name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isVerified
                              ? const Color(0xFF203320)
                              : const Color(0xFF332020),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          isVerified ? 'Verified' : 'Unknown',
                          style: TextStyle(
                            color: isVerified
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
                    folderId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF9E9E9E),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(Icons.check_circle, color: Color(0xFF79FF8B)),
              ),
            const SizedBox(width: 6),
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, color: Color(0xFFB8B8B8)),
            ),
          ],
        ),
      ),
    );
  }
}