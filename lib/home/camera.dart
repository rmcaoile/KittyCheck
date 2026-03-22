import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cat_pain_detector/theme.dart';
import 'package:cat_pain_detector/home/confirmation.dart';
import 'package:cat_pain_detector/home/upload_image.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  bool _isPermissionGranted = false;
  int _currentCameraIndex = 0;
  FlashMode _currentFlashMode = FlashMode.off;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // TODO: permissions
  Future<void> _initializeCamera() async {
    // Request camera permission
    final status = await Permission.camera.request();
    if (status.isGranted) {
      setState(() {
        _isPermissionGranted = true;
      });

      // Get available cameras
      cameras = await availableCameras();

      if (cameras != null && cameras!.isNotEmpty) {
        _controller = CameraController(
          cameras![0], // Use the first camera (back camera)
          ResolutionPreset.high,
        );

        await _controller!.initialize();
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } else {
      // Permission denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required to use this feature'),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _controller == null) return;

    try {
      // Set flash mode before taking picture
      await _controller!.setFlashMode(_currentFlashMode);
      final image = await _controller!.takePicture();
      if (mounted) {
        // Navigate to result page
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ConfirmationPage(imagePath: image.path),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking picture: $e')),
        );
      }
    }
  }

  Future<void> _switchCamera() async {
    if (cameras == null || cameras!.length < 2) return;

    setState(() {
      _isCameraInitialized = false;
    });

    // Dispose current controller
    await _controller?.dispose();

    // Switch to next camera
    _currentCameraIndex = (_currentCameraIndex + 1) % cameras!.length;

    // Initialize new camera
    _controller = CameraController(
      cameras![_currentCameraIndex],
      ResolutionPreset.high,
    );

    try {
      await _controller!.initialize();
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error switching camera: $e')),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final imagePath = await ImagePickerService.pickImage(context);
    if (imagePath != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConfirmationPage(imagePath: imagePath),
        ),
      );
    }
  }

  void _toggleFlash() {
    setState(() {
      _currentFlashMode = _currentFlashMode == FlashMode.off
          ? FlashMode.always
          : FlashMode.off;
    });
  }

  IconData _getFlashIcon() {
    return _currentFlashMode == FlashMode.off
        ? Icons.flash_off
        : Icons.flash_on;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: lightBlue,
        centerTitle: true,
        title: const Text(
          'KittyCheck',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            onPressed: _toggleFlash,
            icon: Icon(
              _getFlashIcon(),
              color: darkBlue,
            ),
          ),
        ],
      ),
      body: _isPermissionGranted
          ? _isCameraInitialized && _controller != null
              ? Stack(
                  children: [
                    // TODO: fix aspect ratio
                    // Camera preview
                    CameraPreview(_controller!),
                    // Grid overlay
                    CustomPaint(
                      size: Size.infinite,
                      painter: GridPainter(),
                    ),
                    // Bottom controls
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.8),
                          border: Border(
                            top: BorderSide(color: lightBlue, width: 2),
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Gallery button
                            IconButton(
                              onPressed: _pickFromGallery,
                              icon: Icon(
                                Icons.photo_library,
                                color: darkBlue,
                                size: 40,
                              ),
                            ),
                            // TODO: add loading screen after capturing image
                            // Capture button
                            GestureDetector(
                              onTap: _takePicture,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: darkBlue,
                                    width: 5,
                                  ),
                                ),
                                child: Center(
                                  child: Container(
                                    width: 60,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: darkBlue,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // TODO: add proper loading screen when changing camera
                            // Switch camera button
                            IconButton(
                              onPressed: _switchCamera,
                              icon: Icon(
                                Icons.flip_camera_ios,
                                color: darkBlue,
                                size: 40,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              : const Center(child: CircularProgressIndicator())
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Camera permission is required'),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => openAppSettings(),
                    child: const Text('Open Settings'),
                  ),
                ],
              ),
            ),
    );
  }
}

class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.0;

    // Draw vertical lines
    for (int i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Draw horizontal lines
    for (int i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}