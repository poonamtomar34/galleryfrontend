import 'package:photo_manager/photo_manager.dart';

class GalleryAlbum {
  GalleryAlbum.device({required AssetPathEntity path, required this.count})
      : id = path.id,
        name = path.name,
        path = path;

  GalleryAlbum.browser({required this.count})
      : id = 'browser-files',
        name = 'Selected files',
        path = null;

  final AssetPathEntity? path;
  final String id;
  final String name;
  final int count;
}
