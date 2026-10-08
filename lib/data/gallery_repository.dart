import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../models/gallery_album.dart';
import '../models/gallery_item.dart';
import 'device_media_service.dart';

/// Converts plugin entities into app models and hides plugin details from the UI.
class GalleryRepository {
  GalleryRepository(this._deviceMediaService);

  final DeviceMediaService _deviceMediaService;
  final List<GalleryItem> _browserItems = [];

  bool get isBrowser => kIsWeb;
  bool get usesFilePicker =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.windows;

  Future<PermissionState?> requestAccess() async {
    if (usesFilePicker) return null;
    return _deviceMediaService.requestAccess();
  }

  Future<List<GalleryAlbum>> getAlbums() async {
    if (usesFilePicker) {
      return [GalleryAlbum.browser(count: _browserItems.length)];
    }
    final paths = await _deviceMediaService.getAlbums();
    final albums = <GalleryAlbum>[];
    for (final path in paths) {
      albums.add(GalleryAlbum.device(path: path, count: await path.assetCountAsync));
    }
    return albums;
  }

  Future<List<GalleryItem>> getItems(GalleryAlbum album) async {
    if (usesFilePicker) return List.unmodifiable(_browserItems);
    final path = album.path;
    if (path == null) return const [];
    return (await _deviceMediaService.getAssets(path))
        .map(GalleryItem.fromAsset)
        .toList(growable: false);
  }

  Future<void> pickSessionFiles() async {
    if (!usesFilePicker) return;
    final result = await FilePicker.pickFiles(
      type: FileType.media,
    );
    if (result.isEmpty) return;
    final stamp = DateTime.now().microsecondsSinceEpoch;
    for (final (index, file) in result.indexed) {
      final extension = (file.extension ?? '').toLowerCase();
      final isVideo = const {'mp4', 'mov', 'webm', 'm4v', 'ogv'}.contains(extension);
      final isImage = const {
        'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'avif', 'heic'
      }.contains(extension);
      if (!isImage && !isVideo) continue;
      final bytes = isVideo ? null : await file.readAsBytes();
      if (!isVideo && (bytes == null || bytes.isEmpty)) continue;
      _browserItems.add(GalleryItem.fromBrowser(
        id: 'browser-$stamp-$index',
        name: file.name,
        bytes: bytes,
        sourceUri: file.uri,
        mimeType: _mimeType(extension, isVideo),
        isVideo: isVideo,
      ));
    }
  }

  String _mimeType(String extension, bool isVideo) => switch (extension) {
        'jpg' || 'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'gif' => 'image/gif',
        'webp' => 'image/webp',
        'mp4' => 'video/mp4',
        'mov' => 'video/quicktime',
        'webm' => 'video/webm',
        'm4v' => 'video/x-m4v',
        'ogv' => 'video/ogg',
        _ => isVideo ? 'video/mp4' : 'image/jpeg',
      };

  Future<Set<String>> deleteItems(Iterable<String> ids) async {
    if (usesFilePicker) {
      final removed = ids.toSet();
      _browserItems.removeWhere((item) => removed.contains(item.id));
      return removed;
    }
    return (await _deviceMediaService.deleteAssets(ids.toList())).toSet();
  }

  Future<void> openSettings() => _deviceMediaService.openSettings();
}
