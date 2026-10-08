import 'dart:typed_data';

import 'package:photo_manager/photo_manager.dart';

class GalleryItem {
  GalleryItem.fromAsset(AssetEntity this.asset)
      : id = asset.id,
        name = asset.title ?? asset.id,
        bytes = null,
        sourceUri = null,
        mimeType = null,
        isVideo = asset.type == AssetType.video,
        duration = Duration(seconds: asset.duration);

  const GalleryItem.fromBrowser({
    required this.id,
    required this.name,
    required this.bytes,
    required this.sourceUri,
    required this.mimeType,
    required this.isVideo,
  })  : asset = null,
        duration = Duration.zero;

  final AssetEntity? asset;
  final String id;
  final String name;
  final Uint8List? bytes;
  final Uri? sourceUri;
  final String? mimeType;
  final bool isVideo;
  final Duration duration;
}
