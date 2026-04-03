import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class DuaAzkarScreen extends StatefulWidget {
  @override
  _DuaAzkarScreenState createState() => _DuaAzkarScreenState();
}

class _DuaAzkarScreenState extends State<DuaAzkarScreen> {
  List<Dua> _duas = [];
  List<Dua> _filteredDuas = [];
  TextEditingController _searchController = TextEditingController();
  double _fontSize = 16.0;
  String _languageFilter = 'all';
  bool _showBookmarksOnly = false;
  Set<int> _bookmarks = {};
  final Color _primaryColor = Color(0xFF0F3443);

  @override
  void initState() {
    super.initState();
    _loadDuas();
    _loadBookmarks();
    _searchController.addListener(_filterDuas);
  }

  Future<void> _loadDuas() async {
    try {
      final String response = await rootBundle.loadString('assets/duas.json');
      final List<dynamic> data = json.decode(response);

      setState(() {
        _duas = data.map((item) => Dua.fromJson(item)).toList();
        _filterDuas();
      });
    } catch (e) {
      print("Error loading duas: $e");
    }
  }

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _bookmarks = Set.from(
        prefs.getStringList('bookmarks')?.map(int.parse) ?? [],
      );
    });
  }

  Future<void> _toggleBookmark(int index) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_bookmarks.contains(index)) {
        _bookmarks.remove(index);
      } else {
        _bookmarks.add(index);
      }
    });
    await prefs.setStringList(
      'bookmarks',
      _bookmarks.map((e) => e.toString()).toList(),
    );
    _filterDuas();
  }

  void _filterDuas() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredDuas =
          _duas.where((dua) {
            final matchesText =
                dua.english.toLowerCase().contains(query) ||
                dua.arabic.toLowerCase().contains(query);

            final matchesLanguage =
                _languageFilter == 'all' ||
                (_languageFilter == 'english' && dua.english.isNotEmpty) ||
                (_languageFilter == 'arabic' && dua.arabic.isNotEmpty);

            final matchesBookmark =
                !_showBookmarksOnly || _bookmarks.contains(dua.index);

            return matchesText && matchesLanguage && matchesBookmark;
          }).toList();
    });
  }

  void _changeFontSize(bool increase) {
    setState(() {
      _fontSize = increase ? _fontSize + 1 : _fontSize - 1;
      _fontSize = _fontSize.clamp(12.0, 24.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text('Dua & Azkar'),
            Text(
              '${_filteredDuas.length} Results',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: _primaryColor,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_primaryColor, Color(0xFF34E89E)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.zoom_out),
            onPressed: () => _changeFontSize(false),
          ),
          IconButton(
            icon: Icon(Icons.zoom_in),
            onPressed: () => _changeFontSize(true),
          ),
          PopupMenuButton(
            icon: Icon(Icons.filter_list),
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.language),
                      title: Text('Show All'),
                      onTap: () {
                        setState(() {
                          _languageFilter = 'all';
                          _showBookmarksOnly = false;
                          _filterDuas();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.translate),
                      title: Text('Arabic Only'),
                      onTap: () {
                        setState(() {
                          _languageFilter = 'arabic';
                          _showBookmarksOnly = false;
                          _filterDuas();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.translate),
                      title: Text('English Only'),
                      onTap: () {
                        setState(() {
                          _languageFilter = 'english';
                          _showBookmarksOnly = false;
                          _filterDuas();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  PopupMenuItem(
                    child: ListTile(
                      leading: Icon(Icons.bookmark),
                      title: Text('Bookmarks Only'),
                      onTap: () {
                        setState(() {
                          _showBookmarksOnly = true;
                          _filterDuas();
                        });
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(60),
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search duas...',
                prefixIcon: Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onChanged: (value) => _filterDuas(),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf0f4f7), Color(0xFFd9e3f0)],
          ),
        ),
        child:
            _duas.isEmpty
                ? Center(child: CircularProgressIndicator())
                : _filteredDuas.isEmpty
                ? Center(child: Text('No duas found'))
                : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _filteredDuas.length,
                  itemBuilder:
                      (context, index) => _buildDuaCard(_filteredDuas[index]),
                ),
      ),
    );
  }

  Widget _buildDuaCard(Dua dua) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue[50]!, Colors.white],
          ),
        ),
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    dua.name,
                    style: TextStyle(
                      fontSize: _fontSize + 2,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _bookmarks.contains(dua.index)
                        ? Icons.bookmark
                        : Icons.bookmark_border,
                    color: _primaryColor,
                  ),
                  onPressed: () => _toggleBookmark(dua.index),
                ),
              ],
            ),
            if (_languageFilter != 'arabic') ...[
              SizedBox(height: 12),
              Text(
                dua.english,
                style: TextStyle(
                  fontSize: _fontSize,
                  color: Colors.grey[800],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.justify,
              ),
            ],
            if (_languageFilter != 'english' && dua.arabic.isNotEmpty) ...[
              SizedBox(height: 20),
              Text(
                dua.arabic,
                style: TextStyle(
                  fontSize: _fontSize + 8,
                  fontFamily: 'Lateef',
                  color: Color(0xFF2E3192),
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ],
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Dua ${dua.index}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: _fontSize - 2,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class Dua {
  final int index;
  final String name;
  final String english;
  final String arabic;

  Dua({
    required this.index,
    required this.name,
    required this.english,
    required this.arabic,
  });

  factory Dua.fromJson(Map<String, dynamic> json) {
    return Dua(
      index: json['index'],
      name: json['name'],
      english: json['english'],
      arabic: json['arabic'] ?? '',
    );
  }
}
