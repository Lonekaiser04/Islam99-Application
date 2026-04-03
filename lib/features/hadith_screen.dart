import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:Islam99/Inner_features/sahih_bukhari.dart';

class HadithScreen extends StatelessWidget {
  final List<Map<String, dynamic>> hadithBooks = [
    {
      'title': 'Sahih Bukhari',
      'author': 'Imam Bukhari',
      'hadithCount': 7563,
      'icon': FontAwesomeIcons.bookOpen,
      'color': Colors.blue[800],
    },
    {
      'title': 'Sahih Muslim',
      'author': 'Imam Muslim',
      'hadithCount': 7563,
      'icon': FontAwesomeIcons.mosque,
      'color': Colors.green[800],
    },
    {
      'title': 'Sunan Abu Dawood',
      'author': 'Abu Dawood',
      'hadithCount': 5274,
      'icon': FontAwesomeIcons.starAndCrescent,
      'color': Colors.orange[800],
    },
    {
      'title': 'Jami` At-Tirmidhi',
      'author': 'At-Tirmidhi',
      'hadithCount': 3956,
      'icon': FontAwesomeIcons.quran,
      'color': Colors.purple[800],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hadith Collections'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 37, 102, 128),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFf0f4f7), Color(0xFFd9e3f0)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.9,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: hadithBooks.length,
            itemBuilder: (context, index) {
              final book = hadithBooks[index];
              return _HadithBookCard(
                title: book['title'],
                author: book['author'],
                hadithCount: book['hadithCount'],
                icon: book['icon'],
                color: book['color'],
                onPressed: ()
                // => _navigateToBook(context, book['title']),
                {
                  if (book['title'] == 'Sahih Bukhari') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SahihBukhariScreen(),
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ),
    );
  }

  // void _navigateToBook(BuildContext context, String title) {
  //   Navigator.push(
  //     context,
  //     MaterialPageRoute(
  //       builder:
  //           (context) => Scaffold(
  //             appBar: AppBar(title: Text(title)),
  //             body: Center(child: Text('$title Content')),
  //           ),
  //     ),
  //   );
  // }
}

class _HadithBookCard extends StatelessWidget {
  final String title;
  final String author;
  final int hadithCount;
  final IconData icon;
  final Color? color;
  final VoidCallback onPressed;

  const _HadithBookCard({
    required this.title,
    required this.author,
    required this.hadithCount,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color!.withOpacity(0.9), color!.withOpacity(0.7)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const Icon(
                    Icons.bookmark_border,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Flexible(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                author,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.format_list_numbered,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$hadithCount Hadiths',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed: onPressed,
                  icon: const Icon(Icons.arrow_forward, size: 14),
                  label: const Text('View', style: TextStyle(fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(80, 30),
                    backgroundColor: Colors.white,
                    foregroundColor: color,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
