import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cat_pain_detector/theme.dart';

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
  final GlobalKey _interactiveViewerKey = GlobalKey();
  double _currentScale = 1.0;
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
      if (!_isZoomedIn) {
        // Zoom in at tap location
        _isZoomedIn = true;
        _currentScale = zoomScale;

        if (_lastZoomPosition != null) {
          final double px = _lastZoomPosition!.dx;
          final double py = _lastZoomPosition!.dy;

          // Zoom at the tapped point: translate so point becomes origin, scale, translate back
          _transformationController.value = Matrix4.identity()
            ..translate(px, py)
            ..scale(zoomScale)
            ..translate(-px, -py);
        } else {
          // Fallback to center zoom if no position available
          final RenderBox? renderBox = _interactiveViewerKey.currentContext?.findRenderObject() as RenderBox?;
          if (renderBox != null) {
            final Size size = renderBox.size;
            final double centerX = size.width / 2;
            final double centerY = size.height / 2;

            _transformationController.value = Matrix4.identity()
              ..translate(centerX, centerY)
              ..scale(zoomScale)
              ..translate(-centerX, -centerY);
          } else {
            _transformationController.value = Matrix4.identity()..scale(zoomScale);
          }
        }
      } else {
        // Zoom out to fit
        _isZoomedIn = false;
        _currentScale = 1.0;
        _transformationController.value = Matrix4.identity();
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
            key: _interactiveViewerKey,
            transformationController: _transformationController,
            minScale: 0.5,
            maxScale: 4.0,
            onInteractionUpdate: (details) {
              _currentScale = details.scale;
            },
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
