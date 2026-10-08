# Simple Gallery

Mostly mobile phones have stopped providing default gallery apps and most apps in the google play store are filled with ads so I just decided to create my own simple gallery app. This is the first version, will add new features in coming weeks.

## Features currently implemented

- Reads photos and videos from the device media library on Android and iOS.
- Shows device albums, such as Recent, Camera, Screenshots, and messaging app folders when the device reports them. Album names and availability depend on the device and granted media access.
- Displays images and videos in a thumbnail grid, with a video duration indicator.
- Opens images in a full-screen viewer with pinch-to-zoom and swipe navigation.
- Plays videos with playback controls and a seek bar.
- Supports selecting one or more items, selecting all, and deleting selected items or the current album's items after confirmation on mobile.
- Handles limited photo access and provides a way to manage the allowed items.
- Lets users choose image and video files on the web and Windows builds. Those selections live only in the current app session. Remove actions do not delete the original files on those platforms.
- Shows loading, permission, empty-gallery, and error states.

## Platforms and run commands

### Web

```powershell
flutter pub get
flutter run -d chrome
```

Web uses the browser file picker. Selected files are held in memory for the current session; they are not automatically saved between sessions.

### Windows

```powershell
flutter run -d windows
```

Windows uses the file picker and session-only storage. Enable Windows Developer Mode if Flutter reports that it cannot create plugin symlinks.

### Android or iOS

```powershell
flutter run
```

Connect a device or start an emulator. The app requests access to photos and videos. On mobile, delete actions are applied to the device media library after confirmation.

## Project structure

- `lib/views/`: gallery and full-screen media viewer UI.
- `lib/viewmodels/`: gallery loading, album selection, selection, and deletion state.
- `lib/data/`: repository and platform media library access.
- `lib/models/`: gallery albums and media items.
- `lib/main.dart`: app setup, theme, and dependency wiring.

## Ideas for future features

Suggested in a practical order:

1. **Search and sorting** — find items by name or date and sort newest/oldest first.
2. **Favorites** — mark and filter favorite items. Persist favorite IDs locally so they remain after restarting the app.
3. **Album overview** — show album cover thumbnails and item counts in a dedicated album screen.
4. **Date grouping** — group the gallery grid under date headings, such as Today, Yesterday, and earlier months.
5. **Share and save actions** — share media or save a copy through the platform's supported APIs.
6. **Faster large-library loading** — fetch media in pages and load more as the user scrolls, rather than waiting for the complete album list.
7. **Settings** — let users choose grid density, theme mode, and default album.
8. **Persistent file-picker library** — optionally remember imported files on platforms where the app cannot read the device photo library directly.

## Does the app need a database?

Not for displaying the device's existing albums. Android and iOS already provide the media library and album information through the platform APIs used by this app. A local database becomes useful if the app adds its own persistent data, such as favorites, custom albums, tags, or saved preferences. The database would store that app-specific information; it would not replace the device media library.
