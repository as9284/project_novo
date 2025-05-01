import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:io';

import './views/home_page.dart';
import './views/settings_page.dart';
import './views/pdf_viewer_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkMode') ?? false;

  runApp(MainApp(initialThemeMode: isDark ? ThemeMode.dark : ThemeMode.light));
}

class MainApp extends StatefulWidget {
  final ThemeMode initialThemeMode;

  const MainApp({super.key, required this.initialThemeMode});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  late ThemeMode _themeMode;

  static const String prefsKey = 'recent_files';
  static const int maxRecentFiles = 10;

  @override
  void initState() {
    super.initState();
    _themeMode = widget.initialThemeMode;
    _handleInitialAndActiveSharing();
  }

  void _handleInitialAndActiveSharing() async {
    final initialMedia = await ReceiveSharingIntent.instance.getInitialMedia();
    if (initialMedia.isNotEmpty &&
        initialMedia.first.path.toLowerCase().endsWith('.pdf')) {
      final path = initialMedia.first.path;
      _openSharedPdf(path);
    }

    ReceiveSharingIntent.instance.getMediaStream().listen((media) {
      if (media.isNotEmpty && media.first.path.toLowerCase().endsWith('.pdf')) {
        final path = media.first.path;
        _openSharedPdf(path);
      }
    });
  }

  Future<void> _openSharedPdf(String path) async {
    if (!File(path).existsSync()) return;

    final prefs = await SharedPreferences.getInstance();
    final recentFiles = prefs.getStringList(prefsKey) ?? [];

    final updated =
        [
          path,
          ...recentFiles.where((p) => p != path),
        ].take(maxRecentFiles).toList();
    await prefs.setStringList(prefsKey, updated);

    await Future.delayed(const Duration(milliseconds: 300));
    if (_navigatorKey.currentState?.context != null) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => PdfViewerPage(filePath: path)),
      );
    }
  }

  Future<void> _toggleTheme(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Minimal PDF Viewer',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      routes: {
        '/home': (context) => const HomePage(),
        '/settings':
            (context) => SettingsPage(
              onThemeChanged: _toggleTheme,
              isDarkMode: _themeMode == ThemeMode.dark,
            ),
      },
      home: const HomePage(),
    );
  }
}
