import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/links_provider.dart';
import '../providers/upload_provider.dart';
import 'add_link_screen.dart';
import 'camera_screen.dart';
import 'folder_detail_screen.dart';
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isSignedIn) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F8),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ElevatedButton.icon(
              onPressed: () => auth.signIn(),
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
            ),
          ),
        ),
      );
    }

    final selectedLink = links.activeLink;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopHeader(
                email: auth.email,
                photoUrl: auth.photoUrl,
                onLogout: () => auth.signOut(),
              ),
              const SizedBox(height: 20),
              _SectionTitle('Active Destination'),
              const SizedBox(height: 10),

              if (selectedLink != null)
                _ActiveFolderCard(
                  name: selectedLink.name,
                  isVerified: selectedLink.isVerified,
                )
              else
                const _NoFolderCard(),

              const SizedBox(height: 14),

              if (uploads.hasItems)
                _PendingStatusCard(
                  total: uploads.total,
                  success: uploads.successCount,
                  failed: uploads.failedCount,
                ),

              const SizedBox(height: 14),

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

              const SizedBox(height: 12),

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

              const SizedBox(height: 14),

              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: const Color(0xFFE4E4E7)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Text(
                          'Saved Drive Folders',
                          style: TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        child: links.links.isEmpty
                            ? const Center(
                          child: Text(
                            'No folder added yet',
                            style: TextStyle(color: Colors.black45),
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
                              isSelected: link.isSelected,
                              isVerified: link.isVerified,
                              onTap: () {
                                links.selectLink(link.id);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FolderDetailScreen(link: link),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 14),

              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ManageLinksScreen()),
                  );
                },
                icon: const Icon(Icons.folder_open_rounded),
                label: const Text('Manage Drive Links'),
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
                  color: Colors.black87,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Capture, queue and upload',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.white,
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
                        backgroundColor: const Color(0xFFEDEDED),
                        backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
                        child: photoUrl == null
                            ? const Icon(Icons.person, color: Colors.black87)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.black87,
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
            backgroundColor: const Color(0xFFE8E8E8),
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? const Icon(Icons.person, color: Colors.black87)
                : null,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.black87,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ActiveFolderCard extends StatelessWidget {
  final String name;
  final bool isVerified;

  const _ActiveFolderCard({
    required this.name,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.folder_rounded, color: Colors.black87),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isVerified ? const Color(0xFFE7F8EA) : const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Text(
                isVerified ? 'Verified' : 'Unknown',
                style: TextStyle(
                  color: isVerified ? const Color(0xFF1E8E3E) : const Color(0xFFB3261E),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
    return const Card(
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.folder_off_rounded, color: Colors.black54),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No folder selected',
                style: TextStyle(color: Colors.black87),
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
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          'Captured: $total • Uploaded: $success • Pending: $pending • Failed: $failed',
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }
}

class _FolderCard extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool isVerified;
  final VoidCallback onTap;

  const _FolderCard({
    required this.name,
    required this.isSelected,
    required this.isVerified,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF4F4F5) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? Colors.black54 : const Color(0xFFE4E4E7),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F1F1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.folder_rounded, color: Colors.black87),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isVerified ? const Color(0xFFE7F8EA) : const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                isVerified ? 'Verified' : 'Unknown',
                style: TextStyle(
                  color: isVerified ? const Color(0xFF1E8E3E) : const Color(0xFFB3261E),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(Icons.check_circle, color: Colors.green),
              ),
          ],
        ),
      ),
    );
  }
}