import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:video_player/video_player.dart';

import '../models/gallery_item.dart';

class MediaViewerScreen extends StatefulWidget {
  const MediaViewerScreen({required this.items, required this.initialIndex, super.key});

  final List<GalleryItem> items;
  final int initialIndex;

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  late final PageController _pageController;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('${_index + 1} / ${widget.items.length}'),
          centerTitle: true,
        ),
        body: PageView.builder(
          controller: _pageController,
          itemCount: widget.items.length,
          onPageChanged: (index) => setState(() => _index = index),
          itemBuilder: (context, index) => _ViewerPage(item: widget.items[index]),
        ),
      );
}

class _ViewerPage extends StatelessWidget {
  const _ViewerPage({required this.item});

  final GalleryItem item;

  @override
  Widget build(BuildContext context) {
    if (item.isVideo) return _VideoPlayerView(item: item);
    final asset = item.asset;
    final ImageProvider<Object> imageProvider = asset == null
        ? MemoryImage(item.bytes!)
        : AssetEntityImageProvider(
            asset,
            isOriginal: true,
            thumbnailSize: const ThumbnailSize(1600, 1600),
          );
    return PhotoView(
      imageProvider: imageProvider,
      backgroundDecoration: const BoxDecoration(color: Colors.black),
      minScale: PhotoViewComputedScale.contained,
      maxScale: PhotoViewComputedScale.covered * 3,
      loadingBuilder: (context, event) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stackTrace) => const Center(
        child: Text('This item could not be opened', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _VideoPlayerView extends StatefulWidget {
  const _VideoPlayerView({required this.item});

  final GalleryItem item;

  @override
  State<_VideoPlayerView> createState() => _VideoPlayerViewState();
}

class _VideoPlayerViewState extends State<_VideoPlayerView> {
  VideoPlayerController? _controller;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final sourceUri = widget.item.sourceUri;
      final controller = sourceUri != null
          ? sourceUri.scheme == 'file'
              ? VideoPlayerController.file(File.fromUri(sourceUri))
              : VideoPlayerController.networkUrl(sourceUri)
          : widget.item.bytes != null
              ? VideoPlayerController.networkUrl(
                  Uri.dataFromBytes(
                    widget.item.bytes!,
                    mimeType: widget.item.mimeType ?? 'video/mp4',
                  ),
                )
              : await _nativeVideoController();
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } catch (_) {
      if (mounted) setState(() => _error = 'This video could not be opened.');
    }
  }

  Future<VideoPlayerController> _nativeVideoController() async {
    final file = await widget.item.asset?.file;
    if (file == null) throw StateError('Media file unavailable');
    return VideoPlayerController.file(file);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (_error != null) return Center(child: Text(_error!, style: const TextStyle(color: Colors.white)));
    if (controller == null) return const Center(child: CircularProgressIndicator());
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            IconButton.filledTonal(
              iconSize: 34,
              onPressed: () => setState(() {
                controller.value.isPlaying ? controller.pause() : controller.play();
              }),
              icon: Icon(controller.value.isPlaying ? Icons.pause : Icons.play_arrow),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 8,
              child: VideoProgressIndicator(controller, allowScrubbing: true),
            ),
          ],
        ),
      ),
    );
  }
}
