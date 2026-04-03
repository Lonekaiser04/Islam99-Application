import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

class PDFScreen extends StatefulWidget {
  @override
  _PDFScreenState createState() => _PDFScreenState();
}

class _PDFScreenState extends State<PDFScreen> {
  String? localFilePath;
  int totalPages = 0;
  int currentPage = 0;
  late PDFViewController pdfController;
  bool _isBookmarked = false;
  final _pageController = TextEditingController();

  // Gradient colors
  final _mainGradient = LinearGradient(
    colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  final _appBarGradient = LinearGradient(
    colors: [Color(0xFF0F3443), Color(0xFF34E89E)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  @override
  void initState() {
    super.initState();
    _loadPDF();
    _loadBookmark();
  }

  Future<void> _loadPDF() async {
    try {
      final ByteData bytes = await rootBundle.load(
        "assets/books/auradefatiha.pdf",
      );
      final Uint8List pdfBytes = bytes.buffer.asUint8List();
      final Directory dir = await getApplicationDocumentsDirectory();
      final File file = File("${dir.path}/auradefatiha.pdf");
      await file.writeAsBytes(pdfBytes, flush: true);

      setState(() => localFilePath = file.path);
    } catch (e) {
      print("Error loading PDF: $e");
      _showErrorSnackbar();
    }
  }

  Future<void> _loadBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _isBookmarked = prefs.getInt('bookmark_page') != null);
  }

  Future<void> _saveBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bookmark_page', currentPage - 1); // Save 0-based index
    setState(() => _isBookmarked = true);
  }

  Future<void> _removeBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('bookmark_page');
    setState(() => _isBookmarked = false);
  }

  Future<void> _jumpToBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    final bookmarkedPage = prefs.getInt('bookmark_page');
    if (bookmarkedPage != null) {
      pdfController.setPage(bookmarkedPage);
    }
  }

  void _toggleBookmark() async {
    if (_isBookmarked) {
      await _removeBookmark();
    } else {
      await _saveBookmark();
    }
  }

  void _showErrorSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to load PDF"),
        backgroundColor: Colors.red,
        action: SnackBarAction(label: "Retry", onPressed: _loadPDF),
      ),
    );
  }

  void _showPageJumpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text("Jump to Page"),
            backgroundColor: Colors.tealAccent,
            content: TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter page number (1-$totalPages)",
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  final page = int.tryParse(_pageController.text);
                  if (page != null && page > 0 && page <= totalPages) {
                    pdfController.setPage(page - 1);
                    Navigator.pop(context);
                  }
                },
                child: Text("Go"),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.book, color: Colors.white),
            SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    text: "Aurad-e-Fatiha\n",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    children: [
                      TextSpan(
                        text:
                            totalPages > 0
                                ? "Page $currentPage/$totalPages"
                                : "",
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: _appBarGradient),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.bookmark,
              color: _isBookmarked ? Colors.amber : Colors.white,
            ),
            onPressed: _toggleBookmark,
            tooltip: _isBookmarked ? 'Remove bookmark' : 'Add bookmark',
          ),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: _showPageJumpDialog,
            tooltip: 'Jump to page',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: _mainGradient),
        child:
            localFilePath == null
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : Stack(
                  children: [
                    PDFView(
                      filePath: localFilePath!,
                      enableSwipe: true,
                      swipeHorizontal: false,
                      autoSpacing: true,
                      pageFling: true,
                      nightMode: false,
                      onRender:
                          (pages) => setState(() => totalPages = pages ?? 0),
                      onViewCreated: (controller) => pdfController = controller,
                      onPageChanged:
                          (page, _) => setState(() => currentPage = page! + 1),
                    ),
                    if (totalPages > 0)
                      Positioned(
                        bottom: 20,
                        left: 20,
                        right: 20,
                        child: LinearProgressIndicator(
                          value: currentPage / totalPages,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber,
                          ),
                        ),
                      ),
                  ],
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isBookmarked ? _jumpToBookmark : _saveBookmark,
        child: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
        backgroundColor: Colors.amber,
        tooltip: _isBookmarked ? 'Jump to bookmark' : 'Set bookmark',
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
