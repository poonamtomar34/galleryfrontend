import 'package:photo_manager/photo_manager.dart';

/// The only layer that talks directly to the device media library.
class DeviceMediaService {
  Future<PermissionState> requestAccess() =>
      PhotoManager.requestPermissionExtend();

  Future<List<AssetPathEntity>> getAlbums() => PhotoManager.getAssetPathList(
        type: RequestType.common,
        hasAll: true,
        onlyAll: false,
      );

  Future<List<AssetEntity>> getAssets(AssetPathEntity album) async {
    final count = await album.assetCountAsync;
    const pageSize = 200;
    final assets = <AssetEntity>[];
    for (var page = 0; page * pageSize < count; page++) {
      assets.addAll(await album.getAssetListPaged(page: page, size: pageSize));
    }
    return assets;
  }

  Future<List<String>> deleteAssets(List<String> ids) =>
      PhotoManager.editor.deleteWithIds(ids);

  Future<void> openSettings() => PhotoManager.openSetting();
}
