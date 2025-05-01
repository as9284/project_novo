import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import '../utils/utils.dart';

class PdfViewerPage extends StatelessWidget {
  final String filePath;

  const PdfViewerPage({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    final documentRef = PdfDocumentRefFile(filePath);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          fileNameFromPath(filePath),
          style: const TextStyle(fontSize: 16),
        ),
      ),
      body: PdfViewer(
        documentRef,
        initialPageNumber: 1,
        params: const PdfViewerParams(
          maxScale: 3.0,
          minScale: 1.0,
          margin: 20,
          enableTextSelection: true,
        ),
      ),
    );
  }
}
