import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  bool _capturing = false;
  bool _showFlash = false;
  int _camIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      _controller?.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;

    _controller = CameraController(
      cameras[_camIndex],
      ResolutionPreset.high,
      enableAudio: false,
    );

    try {
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _switchCamera() async {
    if (cameras.length < 2) return;
    _camIndex = (_camIndex + 1) % cameras.length;
    await _controller?.dispose();
    await _initCamera();
  }

  Future<void> _capture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _capturing) return;

    final folderId = context.read<LinksProvider>().activeLink?.folderId;
    if (folderId == null) return;

    setState(() => _capturing = true);

    try {
      final xFile = await _controller!.takePicture();

      // Save to temp dir only
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/IMG_${DateTime.now().millisecondsSinceEpoch}.jpg';

      await File(xFile.path).copy(tempPath);

      // Delete original camera file
      try {
        await File(xFile.path).delete();
      } catch (_) {}

      // Flash animation
      setState(() => _showFlash = true);
      await Future.delayed(const Duration(milliseconds: 80));
      if (mounted) setState(() => _showFlash = false);

      HapticFeedback.mediumImpact();

      // Upload to Drive and delete temp file
      if (mounted) {
        context.read<UploadProvider>().addAndUpload(
          path: tempPath,
          folderId: folderId,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Capture failed: $e')),
        );
      }
    }

    if (mounted) setState(() => _capturing = false);
  }

  @override
  Widget build(BuildContext context) {
    final uploads = context.watch<UploadProvider>();
    final cs = Theme.of(context).colorScheme;
    final isReady =
        _controller != null && _controller!.value.isInitialized;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (isReady)
            Center(
              child: AspectRatio(
                aspectRatio: 1 / _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            )
          else
            const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),

          // Flash effect
          if (_showFlash) Container(color: Colors.white70),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                // Upload badge
                if (uploads.hasItems)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: uploads.failedCount > 0
                          ? Colors.red
                          : cs.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (uploads.isUploading)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(Icons.cloud_done,
                              color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '${uploads.successCount}/${uploads.total}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
                // Switch camera
                IconButton(
                  icon: const Icon(Icons.flip_camera_android,
                      color: Colors.white),
                  onPressed: _switchCamera,
                ),
              ],
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Text(
                  uploads.hasItems
                      ? 'Uploading to Drive...'
                      : 'Tap to capture',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _capture,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _capturing ? Colors.grey : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}