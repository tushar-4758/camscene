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
  FlashMode _flashMode = FlashMode.off;

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
    await _controller!.setFlashMode(_flashMode);
    if (mounted) setState(() {});
  }

  Future<void> _switchCamera() async {
    if (cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % cameras.length;
    await _controller?.dispose();
    await _initCamera();
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    _flashMode = _flashMode == FlashMode.off ? FlashMode.always : FlashMode.off;
    await _controller!.setFlashMode(_flashMode);
    setState(() {});
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
      uploads.processQueue(folderId);
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

    await uploads.processQueue(folderId);

    if (uploads.failedCount > 0) {
      await uploads.retryFailed(folderId);
    }

    if (mounted) {
      setState(() => _submitting = false);

      final total = uploads.total;
      final uploaded = uploads.successCount;
      final failed = uploads.failedCount;
      final pending = uploads.pendingCount;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF10203B),
          title: const Text('Upload Summary', style: TextStyle(color: Colors.white)),
          content: Text(
            'Captured: $total\nUploaded: $uploaded\nPending: $pending\nFailed: $failed',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (failed == 0 && pending == 0) {
                  uploads.clearCompleted();
                  Navigator.pop(context);
                }
              },
              child: const Text('Done'),
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
          Positioned.fill(child: CameraPreview(_controller!)),
          Positioned(
            top: 48,
            left: 16,
            right: 16,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const Spacer(),
                _CounterBadge(title: 'Captured', value: uploads.total.toString()),
                const SizedBox(width: 8),
                _CounterBadge(
                  title: 'Uploaded',
                  value: uploads.successCount.toString(),
                  color: const Color(0xFF17381E),
                  textColor: Colors.greenAccent,
                ),
                const SizedBox(width: 8),
                _CounterBadge(
                  title: 'Pending',
                  value: uploads.pendingCount.toString(),
                  color: const Color(0xFF1B2742),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _submitting ? null : _submitAll,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                      : const Text('Submit'),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: _toggleFlash,
                  icon: Icon(
                    _flashMode == FlashMode.off
                        ? Icons.flash_off
                        : Icons.flash_on,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                GestureDetector(
                  onTap: _capturing ? null : _capturePhoto,
                  child: Container(
                    width: 84,
                    height: 84,
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
                IconButton(
                  onPressed: _switchCamera,
                  icon: const Icon(Icons.flip_camera_android,
                      color: Colors.white, size: 30),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CounterBadge extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final Color textColor;

  const _CounterBadge({
    required this.title,
    required this.value,
    this.color = const Color(0xAA10203B),
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w700,
              fontSize: 15,
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