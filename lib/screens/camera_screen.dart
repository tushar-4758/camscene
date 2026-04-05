import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../main.dart';
import '../providers/links_provider.dart';
import '../providers/upload_provider.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  bool _capturing = false;
  bool _submitting = false;
  int _cameraIndex = 0;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[_cameraIndex],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _controller!.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    if (cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % cameras.length;
    await _controller?.dispose();
    await _initCamera();
  }

  Future<void> _capturePhoto() async {
    final uploads = context.read<UploadProvider>();
    final folderId = context.read<LinksProvider>().activeLink?.folderId;

    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _capturing ||
        folderId == null) {
      return;
    }

    if (uploads.pendingCount >= 15) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1B1B1D),
          title: const Text('Please wait', style: TextStyle(color: Colors.white)),
          content: Text(
            'Your last ${uploads.pendingCount} photos are not uploaded yet. Please wait a few seconds before capturing more.',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _capturing = true);

    try {
      final xFile = await _controller!.takePicture();

      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      await File(xFile.path).copy(file.path);

      try {
        await File(xFile.path).delete();
      } catch (_) {}

      uploads.addCapturedPhoto(file.path);

      await uploads.triggerRollingUpload(folderId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    }

    if (mounted) setState(() => _capturing = false);
  }

  Future<void> _submitAll() async {
    final folderId = context.read<LinksProvider>().activeLink?.folderId;
    if (folderId == null) return;

    final uploads = context.read<UploadProvider>();
    if (!uploads.hasItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photos captured')),
      );
      return;
    }

    setState(() => _submitting = true);
    await uploads.submitAll(folderId);

    if (mounted) {
      setState(() => _submitting = false);

      final failed = uploads.failedCount;
      final success = uploads.successCount;
      final total = uploads.total;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF1B1B1D),
          title: const Text('Upload Summary', style: TextStyle(color: Colors.white)),
          content: Text(
            'Captured: $total\nUploaded: $success\nFailed: $failed',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            if (failed > 0)
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await uploads.retryFailed(folderId);
                },
                child: const Text('Retry Failed'),
              ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (failed == 0) {
                  uploads.clearCompleted();
                  Navigator.pop(context);
                }
              },
              child: Text(failed == 0 ? 'Done' : 'Close'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploads = context.watch<UploadProvider>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: _controller == null || !_controller!.value.isInitialized
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
        children: [
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                _TopBadge(
                  label: '${uploads.total}',
                  title: 'Captured',
                  bg: const Color(0xAA2A2A2E),
                ),
                const SizedBox(width: 10),
                _TopBadge(
                  label: '${uploads.successCount}',
                  title: 'Uploaded',
                  bg: const Color(0xAA17351A),
                  textColor: const Color(0xFF79FF8B),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: _submitting ? null : _submitAll,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text(
                    'Submit',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          if (uploads.pendingCount > 0)
            Positioned(
              top: 118,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xAA2A2A2E),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  'Pending ${uploads.pendingCount}',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (uploads.pendingCount >= 10)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      'Please wait... pending uploads: ${uploads.pendingCount}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 30),
                    ),
                    GestureDetector(
                      onTap: _capturing ? null : _capturePhoto,
                      child: Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _capturing ? Colors.grey : Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBadge extends StatelessWidget {
  final String label;
  final String title;
  final Color bg;
  final Color textColor;

  const _TopBadge({
    required this.label,
    required this.title,
    required this.bg,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}