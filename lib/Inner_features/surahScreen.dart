import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
// import 'package:google_fonts/google_fonts.dart';

// Enhanced Data Models
class Surah {
  final int number;
  final String name;
  final String englishName;
  final List<Verse> verses;

  Surah({
    required this.number,
    required this.name,
    required this.englishName,
    required this.verses,
  });
}

class Verse {
  final int number;
  final String text;

  Verse({required this.number, required this.text});
}

// Enhanced Quran Repository
class QuranRepository {
  static const Map<int, Map<String, String>> surahNames = {
    1: {'arabic': 'الفاتحة', 'english': 'Al-Fatiha'},
    2: {'arabic': 'البقرة', 'english': 'Al-Baqarah'},
    3: {'arabic': 'آل عمران', 'english': 'Aal Imran'},
    4: {'arabic': 'النساء', 'english': 'An-Nisa'},
    5: {'arabic': 'المائدة', 'english': 'Al-Ma’idah'},
    6: {'arabic': 'الأنعام', 'english': 'Al-An’am'},
    7: {'arabic': 'الأعراف', 'english': 'Al-A’raf'},
    8: {'arabic': 'الأنفال', 'english': 'Al-Anfal'},
    9: {'arabic': 'التوبة', 'english': 'At-Tawbah'},
    10: {'arabic': 'يونس', 'english': 'Yunus'},
    11: {'arabic': 'هود', 'english': 'Hud'},
    12: {'arabic': 'يوسف', 'english': 'Yusuf'},
    13: {'arabic': 'الرعد', 'english': 'Ar-Ra’d'},
    14: {'arabic': 'إبراهيم', 'english': 'Ibrahim'},
    15: {'arabic': 'الحجر', 'english': 'Al-Hijr'},
    16: {'arabic': 'النحل', 'english': 'An-Nahl'},
    17: {'arabic': 'الإسراء', 'english': 'Al-Isra'},
    18: {'arabic': 'الكهف', 'english': 'Al-Kahf'},
    19: {'arabic': 'مريم', 'english': 'Maryam'},
    20: {'arabic': 'طه', 'english': 'Taha'},
    21: {'arabic': 'الأنبياء', 'english': 'Al-Anbiya'},
    22: {'arabic': 'الحج', 'english': 'Al-Hajj'},
    23: {'arabic': 'المؤمنون', 'english': 'Al-Mu’minun'},
    24: {'arabic': 'النور', 'english': 'An-Nur'},
    25: {'arabic': 'الفرقان', 'english': 'Al-Furqan'},
    26: {'arabic': 'الشعراء', 'english': 'Ash-Shu’ara'},
    27: {'arabic': 'النمل', 'english': 'An-Naml'},
    28: {'arabic': 'القصص', 'english': 'Al-Qasas'},
    29: {'arabic': 'العنكبوت', 'english': 'Al-Ankabut'},
    30: {'arabic': 'الروم', 'english': 'Ar-Rum'},
    31: {'arabic': 'لقمان', 'english': 'Luqman'},
    32: {'arabic': 'السجدة', 'english': 'As-Sajdah'},
    33: {'arabic': 'الأحزاب', 'english': 'Al-Ahzab'},
    34: {'arabic': 'سبإ', 'english': 'Saba'},
    35: {'arabic': 'فاطر', 'english': 'Fatir'},
    36: {'arabic': 'يس', 'english': 'Ya-Sin'},
    37: {'arabic': 'الصافات', 'english': 'As-Saffat'},
    38: {'arabic': 'ص', 'english': 'Sad'},
    39: {'arabic': 'الزمر', 'english': 'Az-Zumar'},
    40: {'arabic': 'غافر', 'english': 'Ghafir'},
    41: {'arabic': 'فصلت', 'english': 'Fussilat'},
    42: {'arabic': 'الشورى', 'english': 'Ash-Shura'},
    43: {'arabic': 'الزخرف', 'english': 'Az-Zukhruf'},
    44: {'arabic': 'الدخان', 'english': 'Ad-Dukhan'},
    45: {'arabic': 'الجاثية', 'english': 'Al-Jathiyah'},
    46: {'arabic': 'الأحقاف', 'english': 'Al-Ahqaf'},
    47: {'arabic': 'محمد', 'english': 'Muhammad'},
    48: {'arabic': 'الفتح', 'english': 'Al-Fath'},
    49: {'arabic': 'الحجرات', 'english': 'Al-Hujurat'},
    50: {'arabic': 'ق', 'english': 'Qaf'},
    51: {'arabic': 'الذاريات', 'english': 'Adh-Dhariyat'},
    52: {'arabic': 'الطور', 'english': 'At-Tur'},
    53: {'arabic': 'النجم', 'english': 'An-Najm'},
    54: {'arabic': 'القمر', 'english': 'Al-Qamar'},
    55: {'arabic': 'الرحمن', 'english': 'Ar-Rahman'},
    56: {'arabic': 'الواقعة', 'english': 'Al-Waqi’ah'},
    57: {'arabic': 'الحديد', 'english': 'Al-Hadid'},
    58: {'arabic': 'المجادلة', 'english': 'Al-Mujadila'},
    59: {'arabic': 'الحشر', 'english': 'Al-Hashr'},
    60: {'arabic': 'الممتحنة', 'english': 'Al-Mumtahinah'},
    61: {'arabic': 'الصف', 'english': 'As-Saff'},
    62: {'arabic': 'الجمعة', 'english': 'Al-Jumu’ah'},
    63: {'arabic': 'المنافقون', 'english': 'Al-Munafiqun'},
    64: {'arabic': 'التغابن', 'english': 'At-Taghabun'},
    65: {'arabic': 'الطلاق', 'english': 'At-Talaq'},
    66: {'arabic': 'التحريم', 'english': 'At-Tahrim'},
    67: {'arabic': 'الملك', 'english': 'Al-Mulk'},
    68: {'arabic': 'القلم', 'english': 'Al-Qalam'},
    69: {'arabic': 'الحاقة', 'english': 'Al-Haqqah'},
    70: {'arabic': 'المعارج', 'english': 'Al-Ma’arij'},
    71: {'arabic': 'نوح', 'english': 'Nuh'},
    72: {'arabic': 'الجن', 'english': 'Al-Jinn'},
    73: {'arabic': 'المزمل', 'english': 'Al-Muzzammil'},
    74: {'arabic': 'المدثر', 'english': 'Al-Muddaththir'},
    75: {'arabic': 'القيامة', 'english': 'Al-Qiyamah'},
    76: {'arabic': 'الإنسان', 'english': 'Al-Insan'},
    77: {'arabic': 'المرسلات', 'english': 'Al-Mursalat'},
    78: {'arabic': 'النبأ', 'english': 'An-Naba'},
    79: {'arabic': 'النازعات', 'english': 'An-Nazi’at'},
    80: {'arabic': 'عبس', 'english': 'Abasa'},
    81: {'arabic': 'التكوير', 'english': 'At-Takwir'},
    82: {'arabic': 'الإنفطار', 'english': 'Al-Infitar'},
    83: {'arabic': 'المطففين', 'english': 'Al-Mutaffifin'},
    84: {'arabic': 'الإنشقاق', 'english': 'Al-Inshiqaq'},
    85: {'arabic': 'البروج', 'english': 'Al-Buruj'},
    86: {'arabic': 'الطارق', 'english': 'At-Tariq'},
    87: {'arabic': 'الأعلى', 'english': 'Al-A’la'},
    88: {'arabic': 'الغاشية', 'english': 'Al-Ghashiyah'},
    89: {'arabic': 'الفجر', 'english': 'Al-Fajr'},
    90: {'arabic': 'البلد', 'english': 'Al-Balad'},
    91: {'arabic': 'الشمس', 'english': 'Ash-Shams'},
    92: {'arabic': 'الليل', 'english': 'Al-Layl'},
    93: {'arabic': 'الضحى', 'english': 'Ad-Duhaa'},
    94: {'arabic': 'الشرح', 'english': 'Ash-Sharh'},
    95: {'arabic': 'التين', 'english': 'At-Tin'},
    96: {'arabic': 'العلق', 'english': 'Al-‘Alaq'},
    97: {'arabic': 'القدر', 'english': 'Al-Qadr'},
    98: {'arabic': 'البينة', 'english': 'Al-Bayyina'},
    99: {'arabic': 'الزلزلة', 'english': 'Az-Zalzalah'},
    100: {'arabic': 'العاديات', 'english': 'Al-Adiyat'},
    101: {'arabic': 'القارعة', 'english': 'Al-Qari’ah'},
    102: {'arabic': 'التكاثر', 'english': 'At-Takathur'},
    103: {'arabic': 'العصر', 'english': 'Al-‘Asr'},
    104: {'arabic': 'الهمزة', 'english': 'Al-Humazah'},
    105: {'arabic': 'الفيل', 'english': 'Al-Fil'},
    106: {'arabic': 'قريش', 'english': 'Quraish'},
    107: {'arabic': 'الماعون', 'english': 'Al-Ma’un'},
    108: {'arabic': 'الكوثر', 'english': 'Al-Kawthar'},
    109: {'arabic': 'الكافرون', 'english': 'Al-Kafirun'},
    110: {'arabic': 'النصر', 'english': 'An-Nasr'},
    111: {'arabic': 'المسد', 'english': 'Al-Masad'},
    112: {'arabic': 'الإخلاص', 'english': 'Al-Ikhlas'},
    113: {'arabic': 'الفلق', 'english': 'Al-Falaq'},
    114: {'arabic': 'الناس', 'english': 'An-Nas'},
  };

  Future<List<Surah>> loadSurahs() async {
    try {
      final response = await rootBundle.loadString('assets/quran.json');
      final data = json.decode(response) as Map<String, dynamic>;

      return data.entries.map((entry) {
          final surahNumber = int.tryParse(entry.key) ?? 0;
          final versesData = entry.value as List<dynamic>;

          final verses =
              versesData.map((v) {
                final verseNumber = (v['Verse'] as num?)?.toInt() ?? 0;
                final verseText = (v['text'] as String?) ?? '';

                return Verse(number: verseNumber, text: verseText);
              }).toList();

          // Add Bismillah for all surahs except 1 and 9
          if (surahNumber != 1 && surahNumber != 9) {
            verses.insert(
              0,
              Verse(number: 0, text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ'),
            );
          }

          return Surah(
            number: surahNumber,
            name: surahNames[surahNumber]?['arabic'] ?? 'Surah $surahNumber',
            englishName:
                surahNames[surahNumber]?['english'] ?? 'Surah $surahNumber',
            verses: verses,
          );
        }).toList()
        ..sort((a, b) => a.number.compareTo(b.number));
    } catch (e, stack) {
      print('Error details: $e');
      print('Stack trace: $stack');
      throw Exception('Failed to load Quran data: ${e.toString()}');
    }
  }
}

class SurahScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade900,
              Colors.teal.shade600,
              Colors.teal.shade400,
            ],
          ),
        ),
        child: FutureBuilder<List<Surah>>(
          future: QuranRepository().loadSurahs(),
          builder: (context, snapshot) {
            // ... error handling
            return ListView.separated(
              padding: EdgeInsets.all(16),
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, __) => SizedBox(height: 12),
              itemBuilder: (context, index) {
                final surah = snapshot.data![index];
                return _SurahCard(surah: surah);
              },
            );
          },
        ),
      ),
    );
  }
}

class _SurahCard extends StatelessWidget {
  final Surah surah;

  const _SurahCard({required this.surah});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailScreen(surah: surah),
            ),
          );
        },
        child: Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.teal.shade800, Colors.teal.shade600],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '${surah.number}',
                  style: TextStyle(
                    color: const Color.fromARGB(255, 156, 212, 209),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.englishName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade900,
                      ),
                    ),
                    Text(
                      surah.name,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.teal.shade700,
                        fontFamily: 'NotoNaskhArabic',
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Icon(Icons.menu_book, color: Colors.teal.shade600),
                  SizedBox(height: 4),
                  Text(
                    '${surah.verses.length} verses',
                    style: TextStyle(color: Colors.teal.shade600, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void navigateToSurah(BuildContext context, Surah surah) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => SurahDetailScreen(surah: surah)),
  );
}

class ErrorWidget extends StatelessWidget {
  final String error;

  const ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 50),
            SizedBox(height: 20),
            Text('Error Loading Quran:', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                error,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SurahDetailScreen extends StatelessWidget {
  final Surah surah;

  const SurahDetailScreen({required this.surah, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              surah.englishName,
              style: TextStyle(fontSize: 16, color: Colors.white),
            ),
            Text(
              surah.name,
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'UthmanicHafs',
                color: Colors.white,
              ),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.teal.shade800, Colors.teal.shade600],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.teal.shade50, Colors.white],
          ),
        ),
        child: ListView.separated(
          padding: EdgeInsets.all(20),
          itemCount: surah.verses.length,
          separatorBuilder: (_, __) => SizedBox(height: 20),
          itemBuilder: (context, index) {
            final verse = surah.verses[index];
            return _VerseCard(verse: verse);
          },
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  final Verse verse;

  const _VerseCard({required this.verse});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Directionality(
          textDirection: TextDirection.rtl,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: Text(
                  verse.text,
                  textAlign: TextAlign.justify,
                  style: TextStyle(
                    fontSize: 24,
                    fontFamily: 'UthmanicHafs',
                    color: Colors.teal.shade900,
                    height: 1.8,
                  ),
                ),
              ),
              if (verse.number > 0)
                Container(
                  margin: EdgeInsets.only(left: 16),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.teal.shade300, width: 1.5),
                  ),
                  child: Text(
                    '${verse.number}',
                    style: TextStyle(
                      fontFamily: 'NotoSans',
                      color: Colors.teal.shade800,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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
