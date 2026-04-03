import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';

class NameModel {
  final int number;
  final String name;
  final String transliteration;
  final String meaning;

  NameModel({
    required this.number,
    required this.name,
    required this.transliteration,
    required this.meaning,
  });

  factory NameModel.fromJson(Map<String, dynamic> json) {
    return NameModel(
      number: json['number'],
      name: json['name'],
      transliteration: json['transliteration'],
      meaning: json['meaning'],
    );
  }
}

class NamesScreen extends StatefulWidget {
  @override
  _NamesScreenState createState() => _NamesScreenState();
}

class _NamesScreenState extends State<NamesScreen> {
  late List<NameModel> names = [];
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;
  double _progressValue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadNames();
    _pageController.addListener(_updateProgress);
  }

  void _updateProgress() {
    setState(() {
      _progressValue = (_currentPage + 1) / 99;
    });
  }

  Future<void> _loadNames() async {
    final jsonString = await rootBundle.loadString('assets/names.json');
    final jsonData = json.decode(jsonString);
    setState(() {
      names =
          (jsonData['asmaul_husna'] as List)
              .map((item) => NameModel.fromJson(item))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('99 Names of Allah'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal[800]!, Colors.indigo[900]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.indigo[900]!, Colors.teal[800]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child:
            names.isEmpty
                ? Center(child: CircularProgressIndicator(color: Colors.white))
                : Column(
                  children: [
                    SizedBox(height: 20),
                    _ProgressHeader(current: _currentPage + 1, total: 99),
                    SizedBox(height: 20),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: names.length,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemBuilder: (context, index) {
                          return AnimatedSwitcher(
                            duration: Duration(milliseconds: 500),
                            child: _NameCard(
                              key: ValueKey<int>(names[index].number),
                              name: names[index],
                              progress: _progressValue,
                            ),
                          );
                        },
                      ),
                    ),
                    _NavigationControls(
                      currentPage: _currentPage,
                      totalPages: names.length,
                      pageController: _pageController,
                    ),
                    SizedBox(height: 30),
                  ],
                ),
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int current;
  final int total;

  const _ProgressHeader({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$current/$total',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Container(
            width: 150,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.black.withOpacity(0.3),
            ),
            child: LinearProgressIndicator(
              value: current / total,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.tealAccent),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }
}

class _NameCard extends StatelessWidget {
  final NameModel name;
  final double progress;

  const _NameCard({Key? key, required this.name, required this.progress})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Card(
        elevation: 15,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        shadowColor: Colors.tealAccent.withOpacity(0.3),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.teal[800]!, Colors.indigo[900]!],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  name.name,
                  style: TextStyle(
                    fontSize: 58,
                    color: Colors.white,
                    fontFamily: 'Amiri',
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                ),
                SizedBox(height: 25),
                Text(
                  name.transliteration,
                  style: TextStyle(
                    fontSize: 28,
                    color: Colors.tealAccent[100],
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 15),
                Divider(color: Colors.white54, thickness: 1),
                SizedBox(height: 20),
                Text(
                  name.meaning,
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),
                _NumberBadge(number: name.number),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NumberBadge extends StatelessWidget {
  final int number;

  const _NumberBadge({required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.tealAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.tealAccent, width: 1),
      ),
      child: Text(
        '${number.toString().padLeft(2, '0')}',
        style: TextStyle(
          fontSize: 18,
          color: Colors.tealAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _NavigationControls extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final PageController pageController;

  const _NavigationControls({
    required this.currentPage,
    required this.totalPages,
    required this.pageController,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FloatingActionButton(
            heroTag: 'prev',
            onPressed:
                currentPage > 0
                    ? () => pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                    : null,
            backgroundColor: Colors.teal[800],
            child: Icon(Icons.chevron_left, size: 32),
          ),
          FloatingActionButton(
            heroTag: 'next',
            onPressed:
                currentPage < totalPages - 1
                    ? () => pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    )
                    : null,
            backgroundColor: Colors.teal[800],
            child: Icon(Icons.chevron_right, size: 32),
          ),
        ],
      ),
    );
  }
}
