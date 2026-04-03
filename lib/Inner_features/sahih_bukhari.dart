import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
// import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class SahihBukhariScreen extends StatelessWidget {
  final List<Map<String, dynamic>> volumes = [
    {
      'volume': 1,
      'hadithStart': 1,
      'hadithEnd': 875,
      'icon': Icons.library_books,
      'color': Colors.blue[800],
      'pdfPath': 'assets/book/vol1.pdf',
    },
    {
      'volume': 2,
      'hadithStart': 876,
      'hadithEnd': 1772,
      'icon': Icons.library_books,
      'color': Colors.green[800],
      'pdfPath': 'assets/book/vol2.pdf',
    },
    {
      'volume': 3,
      'hadithStart': 1773,
      'hadithEnd': 2737,
      'icon': Icons.library_books,
      'color': Colors.orange[800],
      'pdfPath': 'assets/book/vol3.pdf',
    },
    {
      'volume': 4,
      'hadithStart': 2738,
      'hadithEnd': 3648,
      'icon': Icons.library_books,
      'color': Colors.purple[800],
      'pdfPath': 'assets/book/vol4.pdf',
    },
    {
      'volume': 5,
      'hadithStart': 3649,
      'hadithEnd': 4473,
      'icon': Icons.library_books,
      'color': Colors.red[800],
      'pdfPath': 'assets/book/vol5.pdf',
    },
    {
      'volume': 6,
      'hadithStart': 4474,
      'hadithEnd': 5062,
      'icon': Icons.library_books,
      'color': Colors.teal[800],
      'pdfPath': 'assets/book/vol6.pdf',
    },
    {
      'volume': 7,
      'hadithStart': 5063,
      'hadithEnd': 5969,
      'icon': Icons.library_books,
      'color': Colors.indigo[800],
      'pdfPath': 'assets/book/vol7.pdf',
    },
    {
      'volume': 8,
      'hadithStart': 5970,
      'hadithEnd': 6860,
      'icon': Icons.library_books,
      'color': Colors.deepOrange[800],
      'pdfPath': 'assets/book/vol8.pdf',
    },
    {
      'volume': 9,
      'hadithStart': 6861,
      'hadithEnd': 7563,
      'icon': Icons.library_books,
      'color': Colors.cyan[800],
      'pdfPath': 'assets/book/vol9.pdf',
    },
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sahih Bukhari'),
        backgroundColor: const Color(0xFF0F3443),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf0f4f7), Color(0xFFd9e3f0)],
          ),
        ),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Text(
                'Sahih al-Bukhari English\n The Authentic Hadith Collection',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F3443),
                  height: 1.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 0.82,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemCount: volumes.length,
                    itemBuilder:
                        (context, index) => VolumeCard(volume: volumes[index]),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VolumeCard extends StatelessWidget {
  final Map<String, dynamic> volume;

  const VolumeCard({required this.volume});

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.transparent,
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAliasWithSaveLayer,
      child: Container(
        decoration: BoxDecoration(
          color: volume['color'],
          border: Border.all(
            color: volume['color'].withOpacity(0.9),
            width: 2.0,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openPdf(context, volume['pdfPath']),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white38, width: 1.5),
                    ),
                    child: Icon(volume['icon'], color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: Text(
                      'Volume ${volume['volume']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Hadiths ${volume['hadithStart']}-${volume['hadithEnd']}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.95),
                      fontSize: 12,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openPdf(BuildContext context, String pdfPath) async {
    try {
      final ByteData bytes = await rootBundle.load(pdfPath);
      final Uint8List pdfBytes = bytes.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final filename = pdfPath.split('/').nonNulls;
      final file = File("${dir.path}/$filename");

      if (!await file.exists()) {
        await file.writeAsBytes(pdfBytes, flush: true);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EnhancedPDFScreen(filePath: file.path),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red[700],
        ),
      );
    }
  }
}

class EnhancedPDFScreen extends StatefulWidget {
  final String filePath;

  const EnhancedPDFScreen({required this.filePath});

  @override
  _EnhancedPDFScreenState createState() => _EnhancedPDFScreenState();
}

class _EnhancedPDFScreenState extends State<EnhancedPDFScreen> {
  final TextEditingController _pageController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  PDFViewController? _pdfViewController;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isNightMode = false;
  List<int> _bookmarks = [];
  String? _searchText;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadBookmarks();
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bookmarks =
          prefs.getStringList('bookmarks')?.map(int.parse).toList() ?? [];
    });
  }

  Future<void> _toggleBookmark() async {
    final prefs = await SharedPreferences.getInstance();
    if (_bookmarks.contains(_currentPage)) {
      _bookmarks.remove(_currentPage);
    } else {
      _bookmarks.add(_currentPage);
    }
    await prefs.setStringList(
      'bookmarks',
      _bookmarks.map((e) => e.toString()).toList(),
    );
    setState(() {});
  }

  void _showPageJumpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            iconColor: Colors.blueGrey,
            title: const Text("Jump to Page"),
            content: TextField(
              controller: _pageController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "Enter page (1-$_totalPages)",
                suffixIcon: const Icon(Icons.numbers),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () {
                  final page = int.tryParse(_pageController.text);
                  if (page != null && page > 0 && page <= _totalPages) {
                    _pdfViewController?.setPage(page - 1);
                    Navigator.pop(context);
                  }
                },
                child: const Text("Go"),
              ),
            ],
          ),
    );
  }

  void _handleSearch() async {
    if (_searchController.text.isEmpty) return;

    setState(() {
      _isSearching = true;
      _searchText = _searchController.text;
    });

    // Implement actual search logic here
    // This is a placeholder for PDF text search implementation
    // You'll need to integrate with a PDF text extraction library
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text("Sahih Bukhari"),
            Text(
              "Page ${_currentPage + 1}/$_totalPages",
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        backgroundColor: const Color.fromARGB(255, 34, 90, 113),
        actions: [
          IconButton(
            icon: Icon(
              Icons.bookmark,
              color:
                  _bookmarks.contains(_currentPage)
                      ? Colors.amber
                      : Colors.white,
            ),
            onPressed: _toggleBookmark,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed:
                () => showSearch(
                  context: context,
                  delegate: PdfSearchDelegate(_searchController, _handleSearch),
                ),
          ),
          IconButton(
            icon: Icon(
              _isNightMode ? Icons.light_mode : Icons.nightlight_round,
            ),
            onPressed: () => setState(() => _isNightMode = !_isNightMode),
          ),
          PopupMenuButton(
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    child: const Text("Jump to Page"),
                    onTap: _showPageJumpDialog,
                  ),
                  PopupMenuItem(
                    child: const Text("View Bookmarks"),
                    onTap: () => _showBookmarksDialog(),
                  ),
                ],
          ),
        ],
      ),
      body: Stack(
        children: [
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: true,
            pageFling: true,
            nightMode: _isNightMode,
            onRender: (pages) => setState(() => _totalPages = pages ?? 0),
            onViewCreated: (controller) => _pdfViewController = controller,
            onPageChanged:
                (page, _) => setState(() => _currentPage = page ?? 0),
          ),
          if (_isSearching)
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: _buildSearchIndicator(),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFastScroll,
        child: const Icon(Icons.auto_stories),
        backgroundColor: const Color(0xFF0F3443),
      ),
    );
  }

  Widget _buildSearchIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.black54,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(width: 20),
          Text("Searching for '$_searchText'..."),
        ],
      ),
    );
  }

  void _showFastScroll() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            height: 80,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const Text("Fast Navigation"),
                Expanded(
                  child: Slider(
                    min: 0,
                    max: _totalPages.toDouble(),
                    value: _currentPage.toDouble(),
                    divisions: _totalPages,
                    label: "Page ${_currentPage + 1}",
                    onChanged: (value) {
                      _pdfViewController?.setPage(value.toInt());
                    },
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showBookmarksDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Bookmarks"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _bookmarks.length,
                itemBuilder:
                    (context, index) => ListTile(
                      title: Text("Page ${_bookmarks[index] + 1}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeBookmark(_bookmarks[index]),
                      ),
                      onTap: () {
                        _pdfViewController?.setPage(_bookmarks[index]);
                        Navigator.pop(context);
                      },
                    ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Close"),
              ),
            ],
          ),
    );
  }

  void _removeBookmark(int page) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _bookmarks.remove(page));
    await prefs.setStringList(
      'bookmarks',
      _bookmarks.map((e) => e.toString()).toList(),
    );
  }
}

class PdfSearchDelegate extends SearchDelegate {
  final TextEditingController controller;
  final Function onSearch;

  PdfSearchDelegate(this.controller, this.onSearch);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
          controller.clear();
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return Container(); // Implement search results display
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container(); // Implement search suggestions
  }
}
