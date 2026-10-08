import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../models/gallery_album.dart';
import '../models/gallery_item.dart';
import '../viewmodels/gallery_view_model.dart';
import 'media_viewer_screen.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({required this.viewModel, super.key});

  final GalleryViewModel viewModel;

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  GalleryViewModel get vm => widget.viewModel;

  @override
  void initState() {
    super.initState();
    vm.load();
  }

  Future<void> _deleteSelected() async {
    final count = vm.selectedIds.length;
    if (!await _confirmDelete(count, all: false)) return;
    final deleted = await vm.deleteSelected();
    if (mounted) _showResult(deleted, count);
  }

  Future<void> _deleteAll() async {
    final count = vm.items.length;
    if (!await _confirmDelete(count, all: true)) return;
    final deleted = await vm.deleteAllInCurrentAlbum();
    if (mounted) _showResult(deleted, count);
  }

  Future<bool> _confirmDelete(int count, {required bool all}) async {
    if (count == 0) return false;
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(vm.usesFilePicker
                ? (all ? 'Remove all items?' : 'Remove selected items?')
                : (all ? 'Delete all items?' : 'Delete selected items?')),
            content: Text(
              vm.usesFilePicker
                  ? 'Remove $count ${count == 1 ? 'item' : 'items'} from this app session? The original files will not be changed.'
                  : all
                      ? 'Delete all $count items in “${vm.currentAlbum?.name ?? 'this album'}” from your device?'
                      : 'Delete $count selected ${count == 1 ? 'item' : 'items'} from your device?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton.tonal(
                style: FilledButton.styleFrom(foregroundColor: Colors.redAccent),
                onPressed: () => Navigator.pop(context, true),
                child: Text(vm.usesFilePicker ? 'Remove' : 'Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showResult(int deleted, int requested) {
    final message = deleted == 0
        ? 'No items were deleted. Your device may have cancelled the request.'
        : deleted == requested
            ? 'Deleted $deleted ${deleted == 1 ? 'item' : 'items'}.'
            : 'Deleted $deleted of $requested items.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: vm,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            titleSpacing: 18,
            title: vm.isSelecting
                ? Text('${vm.selectedIds.length} selected')
                : _albumDropdown(),
            actions: vm.isSelecting ? _selectionActions() : _normalActions(),
          ),
          body: _body(),
        ),
      );

  Widget _albumDropdown() {
    final selected = vm.currentAlbum;
    if (vm.albums.isEmpty || selected == null) {
      return const Text('Your gallery', style: TextStyle(fontWeight: FontWeight.w700));
    }
    return PopupMenuButton<GalleryAlbum>(
      tooltip: 'Choose album',
      initialValue: selected,
      onSelected: vm.selectAlbum,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: const Color(0xFF292432),
      elevation: 10,
      constraints: const BoxConstraints(minWidth: 230, maxWidth: 320),
      itemBuilder: (context) => vm.albums.map((album) {
        final active = album.id == selected.id;
        return PopupMenuItem<GalleryAlbum>(
          value: album,
          height: 54,
          child: Row(
            children: [
              Icon(_albumIcon(album.name), size: 19,
                  color: active ? const Color(0xFFF2B9D1) : Colors.white70),
              const SizedBox(width: 12),
              Expanded(
                child: Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
              ),
              const SizedBox(width: 12),
              Text('${album.count}', style: const TextStyle(color: Colors.white60, fontSize: 13)),
              if (active) ...[
                const SizedBox(width: 8),
                const Icon(Icons.check_rounded, size: 18, color: Color(0xFFF2B9D1)),
              ],
            ],
          ),
        );
      }).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFF292432),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0x55F2B9D1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_albumIcon(selected.name), size: 18, color: const Color(0xFFF2B9D1)),
            const SizedBox(width: 9),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: Text(selected.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: Color(0xFFD9C4E8)),
          ],
        ),
      ),
    );
  }

  IconData _albumIcon(String name) {
    final value = name.toLowerCase();
    if (value.contains('camera')) return Icons.photo_camera_outlined;
    if (value.contains('screenshot')) return Icons.screenshot_monitor_outlined;
    if (value.contains('whatsapp')) return Icons.chat_bubble_outline;
    if (value.contains('download')) return Icons.download_outlined;
    if (value.contains('video')) return Icons.movie_outlined;
    return Icons.photo_library_outlined;
  }

  List<Widget> _normalActions() => [
        if (vm.usesFilePicker)
          IconButton(
            tooltip: 'Choose photos and videos',
            icon: const Icon(Icons.add_photo_alternate_outlined),
            onPressed: vm.isLoading ? null : vm.pickSessionFiles,
          ),
        if (vm.items.isNotEmpty)
          IconButton(
            tooltip: 'Select items',
            icon: const Icon(Icons.checklist),
            onPressed: vm.startSelection,
          ),
        PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'refresh') vm.load();
            if (value == 'delete_all') _deleteAll();
            if (value == 'settings') vm.openSettings();
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            if (vm.hasAccess && vm.items.isNotEmpty)
              PopupMenuItem(
                value: 'delete_all',
                child: Text(vm.usesFilePicker ? 'Remove all from session' : 'Delete all in album'),
              ),
            if (!vm.hasAccess)
              const PopupMenuItem(value: 'settings', child: Text('Open app settings')),
          ],
        ),
      ];

  List<Widget> _selectionActions() => [
        TextButton(
          onPressed: vm.allSelected ? vm.clearSelection : vm.selectAll,
          child: Text(vm.allSelected ? 'Clear' : 'Select all'),
        ),
        IconButton(
          tooltip: vm.usesFilePicker ? 'Remove selected' : 'Delete selected',
          onPressed: vm.isDeleting || vm.selectedIds.isEmpty ? null : _deleteSelected,
          icon: vm.isDeleting
              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.delete_outline),
        ),
        IconButton(
          tooltip: 'Cancel selection',
          onPressed: vm.clearSelection,
          icon: const Icon(Icons.close),
        ),
      ];

  Widget _body() {
    if (vm.isLoading && vm.albums.isEmpty && vm.items.isEmpty) {
      return const _GalleryLoadingState();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: _galleryContent()),
      ],
    );
  }

  Widget _galleryContent() {
    if (vm.isLoading && vm.items.isEmpty) {
      return const _GalleryLoadingState(compact: true);
    }
    if (!vm.hasAccess) {
      return _MessageState(
        icon: Icons.photo_library_outlined,
        title: 'Allow photo access',
        message: 'Simple Gallery needs access to your photos and videos to show them here.',
        actionLabel: 'Try again',
        onAction: vm.load,
      );
    }
    if (vm.errorMessage != null && vm.items.isEmpty) {
      return _MessageState(
        icon: Icons.error_outline,
        title: 'Could not load gallery',
        message: vm.errorMessage!,
        actionLabel: 'Retry',
        onAction: vm.load,
      );
    }
    if (vm.items.isEmpty) {
      return _MessageState(
        icon: Icons.photo_library_outlined,
        title: vm.usesFilePicker ? 'Choose photos and videos' : 'No media in this album',
        message: vm.usesFilePicker
            ? 'Pick image and video files to view them here. They stay in this app session only.'
            : 'Photos and videos on your device will appear here.',
        actionLabel: vm.usesFilePicker ? 'Choose files' : null,
        onAction: vm.usesFilePicker ? vm.pickSessionFiles : null,
      );
    }
    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            childAspectRatio: 1,
          ),
          itemCount: vm.items.length,
          itemBuilder: (context, index) => _MediaTile(
            item: vm.items[index],
            selected: vm.selectedIds.contains(vm.items[index].id),
            selecting: vm.isSelecting,
            onTap: () {
              final item = vm.items[index];
              if (vm.isSelecting) {
                vm.toggleSelection(item.id);
              } else {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => MediaViewerScreen(items: vm.items, initialIndex: index),
                ));
              }
            },
            onLongPress: () => vm.toggleSelection(vm.items[index].id),
          ),
        ),
        if (vm.isLoading || vm.isDeleting)
          const Align(
            alignment: Alignment.topCenter,
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (vm.isLimitedAccess)
          Positioned(
            left: 12,
            right: 12,
            bottom: 12,
            child: Material(
              color: const Color(0xFF28252F),
              borderRadius: BorderRadius.circular(16),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.info_outline),
                title: const Text('Showing only items you allowed'),
                trailing: TextButton(
                  onPressed: () async {
                    await PhotoManager.presentLimited();
                    await vm.load();
                  },
                  child: const Text('Manage'),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MediaTile extends StatelessWidget {
  const _MediaTile({
    required this.item,
    required this.selected,
    required this.selecting,
    required this.onTap,
    required this.onLongPress,
  });

  final GalleryItem item;
  final bool selected;
  final bool selecting;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (item.asset != null)
              AssetEntityImage(
                item.asset!,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(360),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFF24242B),
                  child: Icon(Icons.broken_image_outlined),
                ),
              )
            else if (item.bytes != null)
              Image.memory(item.bytes!, fit: BoxFit.cover)
            else if (item.isVideo)
              const ColoredBox(
                color: Color(0xFF24242B),
                child: Center(child: Icon(Icons.movie_outlined, size: 42)),
              )
            else
              const ColoredBox(color: Color(0xFF24242B)),
            if (item.isVideo)
              Positioned(
                right: 7,
                bottom: 7,
                child: Row(
                  children: [
                    const Icon(Icons.play_arrow, size: 17),
                    Text(_formatDuration(item.duration), style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            if (selecting || selected)
              Positioned(
                top: 7,
                right: 7,
                child: Icon(
                  selected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: selected ? Theme.of(context).colorScheme.primary : Colors.white,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 5)],
                ),
              ),
            if (selected) const ColoredBox(color: Color(0x44E7A9C2)),
          ],
        ),
      );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 52, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withValues(alpha: .7))),
              if (actionLabel != null) ...[
                const SizedBox(height: 18),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      );
}

class _GalleryLoadingState extends StatelessWidget {
  const _GalleryLoadingState({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: .55),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library_rounded, size: 34, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 20),
              Text(compact ? 'Opening album…' : 'Getting your gallery ready',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 7),
              Text('Gathering your photos and videos',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
              const SizedBox(height: 20),
              const SizedBox(width: 100, child: LinearProgressIndicator(minHeight: 3)),
            ],
          ),
        ),
      );
}
