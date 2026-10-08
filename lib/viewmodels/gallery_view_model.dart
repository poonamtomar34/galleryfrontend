import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';

import '../data/gallery_repository.dart';
import '../models/gallery_album.dart';
import '../models/gallery_item.dart';

class GalleryViewModel extends ChangeNotifier {
  GalleryViewModel(this._repository);

  final GalleryRepository _repository;
  List<GalleryAlbum> albums = const [];
  List<GalleryItem> items = const [];
  final Set<String> selectedIds = {};
  GalleryAlbum? currentAlbum;
  bool isLoading = false;
  bool isDeleting = false;
  bool isSelectionMode = false;
  bool hasAccess = false;
  bool isLimitedAccess = false;
  String? errorMessage;

  bool get isSelecting => isSelectionMode;
  bool get allSelected => items.isNotEmpty && selectedIds.length == items.length;
  bool get isBrowser => _repository.isBrowser;
  bool get usesFilePicker => _repository.usesFilePicker;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      final permission = await _repository.requestAccess();
      hasAccess = usesFilePicker || (permission?.isAuth ?? false) || (permission?.hasAccess ?? false);
      isLimitedAccess = permission == PermissionState.limited;
      if (!hasAccess) {
        albums = const [];
        items = const [];
        currentAlbum = null;
        return;
      }
      albums = await _repository.getAlbums();
      currentAlbum = _preserveOrChooseAlbum();
      await _loadCurrentAlbum();
    } catch (error) {
      errorMessage = 'Could not load your media. Please try again.';
      debugPrint('Gallery load failed: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  GalleryAlbum? _preserveOrChooseAlbum() {
    for (final album in albums) {
      if (album.id == currentAlbum?.id) return album;
    }
    return albums.isEmpty ? null : albums.first;
  }

  Future<void> _loadCurrentAlbum() async {
    final album = currentAlbum;
    items = album == null ? const [] : await _repository.getItems(album);
    selectedIds.clear();
    isSelectionMode = false;
  }

  Future<void> selectAlbum(GalleryAlbum album) async {
    if (album.id == currentAlbum?.id) return;
    currentAlbum = album;
    selectedIds.clear();
    isLoading = true;
    notifyListeners();
    try {
      await _loadCurrentAlbum();
    } catch (error) {
      errorMessage = 'Could not load this album.';
      debugPrint('Album load failed: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> pickSessionFiles() async {
    if (!usesFilePicker || isLoading) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _repository.pickSessionFiles();
      albums = await _repository.getAlbums();
      currentAlbum = albums.first;
      items = await _repository.getItems(currentAlbum!);
      selectedIds.clear();
      isSelectionMode = false;
    } catch (error) {
      errorMessage = 'Could not open the selected media files.';
      debugPrint('Browser media selection failed: $error');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void toggleSelection(String id) {
    isSelectionMode = true;
    if (!selectedIds.add(id)) selectedIds.remove(id);
    notifyListeners();
  }

  void startSelection() {
    isSelectionMode = true;
    notifyListeners();
  }

  void selectAll() {
    isSelectionMode = true;
    selectedIds
      ..clear()
      ..addAll(items.map((item) => item.id));
    notifyListeners();
  }

  void clearSelection() {
    selectedIds.clear();
    isSelectionMode = false;
    notifyListeners();
  }

  Future<int> deleteSelected() async => _delete(selectedIds.toSet());

  Future<int> deleteAllInCurrentAlbum() async =>
      _delete(items.map((item) => item.id).toSet());

  Future<int> _delete(Set<String> ids) async {
    if (ids.isEmpty || isDeleting) return 0;
    isDeleting = true;
    notifyListeners();
    try {
      final deletedIds = await _repository.deleteItems(ids);
      items = items.where((item) => !deletedIds.contains(item.id)).toList();
      selectedIds.removeAll(deletedIds);
      albums = await _repository.getAlbums();
      currentAlbum = _preserveOrChooseAlbum();
      if (currentAlbum != null && deletedIds.isNotEmpty) {
        await _loadCurrentAlbum();
      }
      return deletedIds.length;
    } catch (error) {
      errorMessage = 'The system could not delete those items.';
      debugPrint('Media deletion failed: $error');
      return 0;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  Future<void> openSettings() => _repository.openSettings();
}
