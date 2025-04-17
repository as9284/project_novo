import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pdf_viewer_page.dart';
import '../utils/utils.dart';
import 'dart:io';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const String prefsKey = 'recent_files';
  static const int maxRecentFiles = 10;
  List<String> recentFiles = [];

  @override
  void initState() {
    super.initState();
    loadRecentFiles();
  }

  Future<void> loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final files = prefs.getStringList(prefsKey) ?? [];

    // Filter only valid PDF files that still exist
    final validFiles =
        files
            .where(
              (path) =>
                  path.toLowerCase().endsWith('.pdf') &&
                  File(path).existsSync(),
            )
            .toList();

    // Update prefs if we filtered out any invalid files
    if (validFiles.length != files.length) {
      await prefs.setStringList(prefsKey, validFiles);
    }

    setState(() {
      recentFiles = validFiles;
    });
  }

  Future<void> updateRecentFiles(String filePath) async {
    final prefs = await SharedPreferences.getInstance();

    // Create a new list without the current path (if it exists)
    final updatedList = recentFiles.where((path) => path != filePath).toList();

    // Add the new path at the beginning
    updatedList.insert(0, filePath);

    // Trim to max length
    final trimmedList = updatedList.take(maxRecentFiles).toList();

    // Save to prefs
    await prefs.setStringList(prefsKey, trimmedList);

    setState(() {
      recentFiles = trimmedList;
    });
  }

  Future<void> clearRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(prefsKey, []);

    setState(() {
      recentFiles = [];
    });

    // Show confirmation to user
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recent files list cleared')),
      );
    }
  }

  Future<void> openPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;

      if (!filePath.toLowerCase().endsWith('.pdf')) return;

      // Update recent files
      await updateRecentFiles(filePath);

      if (mounted) {
        // Navigate to PDF viewer
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfViewerPage(filePath: filePath)),
        );
      }
    }
  }

  Future<void> openRecentFile(String path) async {
    if (!File(path).existsSync()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('File not found')));
      loadRecentFiles();
      return;
    }

    // Update recent files to move this to the top
    await updateRecentFiles(path);

    if (mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PdfViewerPage(filePath: path)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Novo',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, "/settings");
            },
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: openPdfFile,
        icon: const Icon(Icons.folder_open),
        label: const Text('Open PDF'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with title and clear button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Recently Opened', style: TextStyle(fontSize: 18)),
                if (recentFiles.isNotEmpty)
                  TextButton.icon(
                    onPressed: () {
                      // Show confirmation dialog
                      showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Clear Recent Files'),
                              content: const Text(
                                'Are you sure you want to clear the list of recently opened files?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text('CANCEL'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    clearRecentFiles();
                                  },
                                  child: const Text('CLEAR'),
                                ),
                              ],
                            ),
                      );
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child:
                  recentFiles.isEmpty
                      ? const Center(child: Text('No recent files'))
                      : ListView.builder(
                        itemCount: recentFiles.length,
                        itemBuilder: (context, index) {
                          final path = recentFiles[index];
                          return ListTile(
                            leading: const Icon(Icons.picture_as_pdf),
                            title: Text(fileNameFromPath(path)),
                            onTap: () => openRecentFile(path),
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
