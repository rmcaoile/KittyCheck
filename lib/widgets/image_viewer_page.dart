import 'dart:io';
import 'package:flutter/material.dart';

class ImageViewerPage extends StatefulWidget {
  final String? imagePath;
  final bool isAsset;
  final List<String>? imagePaths;
  final List<bool>? isAssetList;
  final int initialIndex;
  final List<String>? labels;
  final List<String>? descriptions;

  const ImageViewerPage({
    super.key,
    this.imagePath,
    this.isAsset = false,
    this.imagePaths,
    this.isAssetList,
    this.initialIndex = 0,
    this.labels,
    this.descriptions,
  }) : assert(imagePath != null || imagePaths != null);

  @override
  State<ImageViewerPage> createState() => _ImageViewerPageState();
}

class _ImageViewerPageState extends State<ImageViewerPage> {
  final TransformationController _transformationController =
      TransformationController();
  late PageController _pageController;
  late int _currentIndex;
  bool _isZoomedIn = false;
  Offset? _lastZoomPosition;

  @override
  void initState() {
    super.initState();
    _transformationController.addListener(_onTransformationChanged);
    if (widget.imagePaths != null) {
      _currentIndex = widget.initialIndex;
      _pageController = PageController(initialPage: _currentIndex);
    } else {
      _currentIndex = 0;
      _pageController = PageController();
    }
  }

  @override
  void dispose() {
    _transformationController.removeListener(_onTransformationChanged);
    _transformationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onTransformationChanged() {
    final scale = _transformationController.value.getMaxScaleOnAxis();
    final zoomed = scale > 1.05;
    if (zoomed != _isZoomedIn) {
      setState(() {
        _isZoomedIn = zoomed;
      });
    }
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
          _transformationController.value = Matrix4.identity()
            ..scale(zoomScale);
        }
      }
    });
  }

  List<String> get _imagePaths {
    if (widget.imagePaths != null) return widget.imagePaths!;
    return [widget.imagePath!];
  }

  List<bool> get _isAssetList {
    if (widget.isAssetList != null) return widget.isAssetList!;
    return [widget.isAsset];
  }

  List<String> get _labels {
    if (widget.labels != null) return widget.labels!;
    return [];
  }

  List<String> get _descriptions {
    if (widget.descriptions != null) return widget.descriptions!;
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final hasMultipleImages = _imagePaths.length > 1;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: hasMultipleImages
            ? Text(
                '${_currentIndex + 1}/${_imagePaths.length}',
                style: const TextStyle(color: Colors.white),
              )
            : null,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: _isZoomedIn
                  ? const NeverScrollableScrollPhysics()
                  : const BouncingScrollPhysics(),
              itemCount: _imagePaths.length,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                  _isZoomedIn = false;
                  _transformationController.value = Matrix4.identity();
                });
              },
              itemBuilder: (context, index) {
                final imagePath = _imagePaths[index];
                final isAsset = _isAssetList[index];

                return GestureDetector(
                  onDoubleTapDown: _onDoubleTapDown,
                  onDoubleTap: _onDoubleTap,
                  child: InteractiveViewer(
                    transformationController: _transformationController,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: isAsset
                        ? Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                          )
                        : Image.file(
                            File(imagePath),
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
                );
              },
            ),
          ),
          if (!_isZoomedIn && _labels.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black.withValues(alpha: 0.7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _labels[_currentIndex],
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_descriptions.isNotEmpty &&
                      _currentIndex < _descriptions.length &&
                      _descriptions[_currentIndex].isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      _descriptions[_currentIndex],
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          if (hasMultipleImages)
            Padding(
              padding: const EdgeInsets.only(bottom: 20, top: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_imagePaths.length, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentIndex == index ? 12 : 8,
                    height: _currentIndex == index ? 12 : 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentIndex == index
                          ? Colors.white
                          : Colors.grey[600],
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}
