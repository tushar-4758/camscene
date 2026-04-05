import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/links_provider.dart';
import '../providers/upload_provider.dart';
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isSignedIn) {
      return Scaffold(
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

    final selected = links.activeLink;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(
                email: auth.email,
                photoUrl: auth.photoUrl,
                onLogout: () => auth.signOut(),
              ),
              const SizedBox(height: 24),

              if (selected != null)
                _SelectedFolderCard(
                  name: selected.name,
                  isVerified: selected.isVerified,
                )
              else
                const _NoFolderCard(),

              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      title: 'Captured',
                      value: '${uploads.total}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      title: 'Uploaded',
                      value: '${uploads.successCount}',
                    ),
                  ),
                ],
              ),

              const Spacer(),

              ElevatedButton.icon(
                onPressed: selected == null
                    ? null
                    : () {
                  if (uploads.hasUnfinished) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Pending uploads exist. Please finish them first.',
                        ),
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CameraScreen(),
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
                    MaterialPageRoute(
                      builder: (_) => const ManageLinksScreen(),
                    ),
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

class _Header extends StatelessWidget {
  final String email;
  final String? photoUrl;
  final VoidCallback onLogout;

  const _Header({
    required this.email,
    required this.photoUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CamScene',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Capture and upload smartly',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
              ),
              builder: (_) => SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage:
                        photoUrl != null ? NetworkImage(photoUrl!) : null,
                        backgroundColor: const Color(0xFFEAEAEA),
                        child: photoUrl == null
                            ? const Icon(Icons.person, color: Colors.black)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
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
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl!) : null,
            backgroundColor: const Color(0xFFEAEAEA),
            child: photoUrl == null
                ? const Icon(Icons.person, color: Colors.black)
                : null,
          ),
        ),
      ],
    );
  }
}

class _SelectedFolderCard extends StatelessWidget {
  final String name;
  final bool isVerified;

  const _SelectedFolderCard({
    required this.name,
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
                color: Colors.black,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.folder_rounded, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isVerified
                    ? const Color(0xFFEAF9EE)
                    : const Color(0xFFFFEEEE),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Text(
                isVerified ? 'Verified' : 'Unknown',
                style: TextStyle(
                  color: isVerified ? Colors.green : Colors.red,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
          children: const [
            Icon(Icons.folder_off_rounded, color: Colors.black54),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No folder selected',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;

  const _StatCard({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}