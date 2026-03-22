import 'dart:io';
import 'package:flutter/material.dart';

class ImageViewerPage extends StatefulWidget {
  final String imagePath;
  final bool isAsset;

  const ImageViewerPage({
    super.key,
    required this.imagePath,
    this.isAsset = false,
  });

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  final TransformationController _transformationController = TransformationController();
  bool _isZoomedIn = false;
  Offset? _lastZoomPosition;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _onDoubleTapDown(TapDownDetails details) {
    _lastZoomPosition = details.localPosition;
  }

  void _onDoubleTap() {
    const double zoomScale = 2.0;

    setState(() {
      if (_isZoomedIn) {
        // Zoom out to original size
        _isZoomedIn = false;
        _transformationController.value = Matrix4.identity();
      } else {
        // Zoom in at tap location or center
        _isZoomedIn = true;

        if (_lastZoomPosition != null) {
          // Zoom at the tapped point
          final px = _lastZoomPosition!.dx;
          final py = _lastZoomPosition!.dy;
          _transformationController.value = Matrix4.identity()
            ..translate(px, py)
            ..scale(zoomScale)
            ..translate(-px, -py);
        } else {
          // Zoom from origin if no tap position
          _transformationController.value = Matrix4.identity()..scale(zoomScale);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: GestureDetector(
          onDoubleTapDown: _onDoubleTapDown,
          onDoubleTap: _onDoubleTap,
          child: InteractiveViewer(
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            child: widget.isAsset
                ? Image.asset(
                    widget.imagePath,
                    fit: BoxFit.contain,
                  )
                : Image.file(
                    File(widget.imagePath),
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.white,
                          size: 48,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
