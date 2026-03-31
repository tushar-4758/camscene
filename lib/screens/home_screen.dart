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
    final cs = Theme.of(context).colorScheme;

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!auth.isSignedIn) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.camera_alt_rounded,
                    size: 80, color: cs.primary),
                const SizedBox(height: 24),
                Text(
                  'Capiktoy',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Capture → Upload to Drive → Done',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 48),
                FilledButton.icon(
                  onPressed: () => auth.signIn(),
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final activeLink = links.activeLink;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Capiktoy'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => auth.signOut(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // User info
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: auth.photoUrl != null
                      ? NetworkImage(auth.photoUrl!)
                      : null,
                  child: auth.photoUrl == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(auth.email),
              ],
            ),

            const SizedBox(height: 16),

            // Active folder card
            Card(
              child: ListTile(
                leading: Icon(
                  Icons.folder,
                  color: activeLink != null ? cs.primary : cs.outline,
                ),
                title: Text(activeLink?.name ?? 'No folder selected'),
                subtitle: Text(
                  activeLink?.folderId ?? 'Add a Drive folder link',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ManageLinksScreen(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Upload status
            if (uploads.hasItems)
              Card(
                color: uploads.failedCount > 0
                    ? cs.errorContainer
                    : cs.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Uploaded: ${uploads.successCount}/${uploads.total}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (uploads.isUploading)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: LinearProgressIndicator(),
                        ),
                      if (uploads.failedCount > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Row(
                            children: [
                              Text(
                                'Failed: ${uploads.failedCount}',
                                style: TextStyle(color: cs.error),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: activeLink != null
                                    ? () => uploads.retryFailed(
                                  activeLink.folderId,
                                )
                                    : null,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      if (!uploads.isUploading && uploads.failedCount == 0)
                        TextButton(
                          onPressed: () => uploads.clearAll(),
                          child: const Text('Clear'),
                        ),
                    ],
                  ),
                ),
              ),

            const Spacer(),

            // Camera button
            SizedBox(
              width: 160,
              height: 160,
              child: ElevatedButton(
                onPressed: activeLink == null
                    ? null
                    : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CameraScreen(),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  backgroundColor: cs.primaryContainer,
                  elevation: 4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.camera_alt_rounded,
                      size: 48,
                      color: activeLink != null ? cs.primary : cs.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'CAPTURE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: activeLink != null ? cs.primary : cs.outline,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            if (activeLink == null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Add a Drive folder to start',
                  style: TextStyle(color: cs.error),
                ),
              ),

            const Spacer(),

            // Manage links button
            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ManageLinksScreen(),
                ),
              ),
              icon: const Icon(Icons.folder_open),
              label: const Text('Manage Drive Links'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}