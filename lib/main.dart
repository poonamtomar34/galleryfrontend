import 'package:flutter/material.dart';

import 'data/device_media_service.dart';
import 'data/gallery_repository.dart';
import 'viewmodels/gallery_view_model.dart';
import 'views/gallery_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = GalleryRepository(DeviceMediaService());
  runApp(SimpleGalleryApp(viewModel: GalleryViewModel(repository)));
}

class SimpleGalleryApp extends StatelessWidget {
  const SimpleGalleryApp({required this.viewModel, super.key});

  final GalleryViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFFE7A9C2);
    return MaterialApp(
      title: 'Simple Gallery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark),
        scaffoldBackgroundColor: const Color(0xFF17151D),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF17151D),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
        ),
        chipTheme: ChipThemeData(
          side: BorderSide.none,
          backgroundColor: const Color(0xFF292432),
          selectedColor: const Color(0xFF4B3D56),
          shape: const StadiumBorder(),
        ),
        useMaterial3: true,
      ),
      home: GalleryScreen(viewModel: viewModel),
    );
  }
}
