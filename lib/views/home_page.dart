import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'pdf_viewer_page.dart';
import '../utils/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<String> recentFiles = [];

  @override
  void initState() {
    super.initState();
    loadRecentFiles();
  }

  Future<void> loadRecentFiles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      recentFiles = prefs.getStringList('recent_files') ?? [];
    });
  }

  Future<void> openPdfFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final filePath = result.files.single.path!;
      await addToRecentFiles(filePath);
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfViewerPage(filePath: filePath)),
        );
      }
    }
  }

  Future<void> addToRecentFiles(String path) async {
    final prefs = await SharedPreferences.getInstance();
    final files = prefs.getStringList('recent_files') ?? [];

    files.remove(path);
    files.insert(0, path);
    if (files.length > 5) files.removeLast();

    await prefs.setStringList('recent_files', files);
    setState(() {
      recentFiles = files;
    });
  }

  void openRecentFile(String path) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PdfViewerPage(filePath: path)),
    );
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
            icon: Icon(Icons.settings),
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
            const Text('Recently Opened', style: TextStyle(fontSize: 18)),
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
