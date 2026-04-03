import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:Islam99/Inner_features/support.dart';
import 'package:Islam99/features/nemaz_timing_screen.dart';
import 'package:Islam99/features/tasbih_screen.dart';
import 'package:provider/provider.dart';
import 'features/prayer_time_screen.dart';
import 'features/duas_azkar_screen.dart';
import 'features/qibla_direction_screen.dart';
import 'features/quran_screen.dart';
import 'features/hadith_screen.dart';
import 'features/settings_screen.dart';
import 'features/both_calendars_screen.dart';
import 'features/prayer_countdown.dart';
import 'features/theme_provider.dart';
import 'features/calendars_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'features/splash_screen.dart';
import 'features/aurad_e_fatiha.dart';
import 'package:Islam99/Inner_features/names_screen.dart';
import 'Inner_features/zakat_screen.dart';
import 'package:timezone/data/latest.dart' as tzData;
import 'package:timezone/timezone.dart' as tz;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tzData.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
  await Hive.initFlutter();
  await Hive.openBox('prayerCache');
  await Hive.openBox('hijriCache');
  await Hive.openBox('verseCache');
  await Hive.openBox('hadithCache');

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: Colors.black, fontSize: 16),
          bodyMedium: TextStyle(color: Colors.black),
          bodySmall: TextStyle(color: Colors.black),
          titleLarge: TextStyle(
            color: Colors.black,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          titleMedium: TextStyle(color: Colors.black),
          titleSmall: TextStyle(color: Colors.black),
        ),
        // Customize light theme
        primaryColor: const Color.fromARGB(255, 128, 208, 132),
        scaffoldBackgroundColor: Colors.grey[200],
        appBarTheme: const AppBarTheme(
          color: Color.fromARGB(255, 104, 179, 108),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        // Customize dark theme
        primaryColor: const Color(0xFF1B5E20),
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: const AppBarTheme(
          color: Color(0xFF1B5E20),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      themeMode: themeProvider.themeMode,
      home: SplashScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeTab(),
    const QuranTab(),
    const HadithTab(),
    const PrayerTab(),
    const MoreTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_online),
            label: 'Quran',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.library_books),
            label: 'Hadith',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Prayers',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}

class _AppResumeObserver with WidgetsBindingObserver {
  final VoidCallback onResume;

  _AppResumeObserver({required this.onResume}) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
      WidgetsBinding.instance.removeObserver(this);
    }
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic> _dates = {};
  bool _isLoading = true;
  // String _errorMessage = '';
  String _verseOfTheDay = '';
  String _hadithOfTheDay = '';

  @override
  void initState() {
    super.initState();
    _loadCachedData();
    _fetchDates();
    _fetchVerseOfTheDay();
    _fetchHadithOfTheDay();
  }

  Future<void> _loadCachedData() async {
    final hijriCache = Hive.box('hijriCache');
    final verseCache = Hive.box('verseCache');
    final hadithCache = Hive.box('hadithCache');

    setState(() {
      _dates = {
        'hijri': hijriCache.get('hijri', defaultValue: {}),
        'gregorian': hijriCache.get('gregorian', defaultValue: {}),
      };
      _verseOfTheDay = verseCache.get('verse', defaultValue: 'Loading...');
      _hadithOfTheDay = hadithCache.get('hadith', defaultValue: 'Loading...');
    });
  }

  Future<void> _fetchDates() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://api.aladhan.com/v1/gToH/${DateFormat('dd-MM-yyyy').format(DateTime.now())}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hijriCache = Hive.box('hijriCache');
        hijriCache.put('hijri', data['data']['hijri']);
        hijriCache.put('gregorian', data['data']['gregorian']);

        setState(() {
          _dates = {
            'hijri': data['data']['hijri'],
            'gregorian': data['data']['gregorian'],
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchVerseOfTheDay() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.alquran.cloud/v1/ayah/random'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Hive.box('verseCache').put('verse', data['data']['text']);
        setState(() => _verseOfTheDay = data['data']['text']);
      }
    } catch (e) {
      setState(() => _verseOfTheDay = 'Failed to fetch verse');
    }
  }

  Future<void> _fetchHadithOfTheDay() async {
    try {
      final response = await http.get(
        Uri.parse('https://random-hadith-generator.vercel.app/bukhari/'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        Hive.box('hadithCache').put('hadith', data['data']['hadith_english']);
        setState(() => _hadithOfTheDay = data['data']['hadith_english']);
      }
    } catch (e) {
      setState(() => _hadithOfTheDay = 'Failed to fetch Hadith');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Islam99'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyApp()),
                ),
          ),

          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MSettingsScreen(),
                  ),
                ),
          ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _DateCard(dates: _dates),
          const SizedBox(height: 20),
          _PrayerCountdownCard(),
          const SizedBox(height: 20),
          _VerseCard(verse: _verseOfTheDay),
          const SizedBox(height: 20),
          _HadithCard(hadith: _hadithOfTheDay),
        ],
      ),
    );
  }
}

class _DateCard extends StatelessWidget {
  final Map<String, dynamic> dates;
  const _DateCard({required this.dates});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      color: Color.fromRGBO(13, 118, 217, 0.833),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Hijri Date', style: Theme.of(context).textTheme.titleLarge),
            Text(
              '${dates['hijri']['day']}-${dates['hijri']['month']['en']}-${dates['hijri']['year']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Text(
              'Gregorian Date',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              DateFormat('dd MMMM yyyy').format(DateTime.now()),
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrayerCountdownCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text("Next Prayer In", style: TextStyle(fontSize: 20)),
            SizedBox(height: 10),
            PrayerCountdown(),
          ],
        ),
      ),
    );
  }
}

class _VerseCard extends StatelessWidget {
  final String verse;
  const _VerseCard({required this.verse});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Verse of the Day',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(verse, style: const TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  final String hadith;
  const _HadithCard({required this.hadith});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hadith of the Day',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(hadith, style: const TextStyle(fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }
}

// Placeholder tabs
class QuranTab extends StatelessWidget {
  const QuranTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: PreferredSize(
      //   preferredSize: Size.fromHeight(60),
      //   child: CustomAppBar(title: 'Holy Quran'),
      // ),
      appBar: AppBar(
        title: const Text('Holy Quran'),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 37, 102, 128),
      ),
      body: Center(child: QuranScreen()),
    );
  }
}

class HadithTab extends StatelessWidget {
  const HadithTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: HadithScreen());
  }
}

class PrayerTab extends StatelessWidget {
  const PrayerTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // appBar: PreferredSize(
      //   preferredSize: Size.fromHeight(60),
      //   child: CustomAppBar(title: 'Prayer Times'),
      // ),
      body: PrayerTimesScreen(),
    );
  }
}

class MoreTab extends StatelessWidget {
  const MoreTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: CustomAppBar(title: 'More'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey.shade50],
          ),
        ),
        child: Column(
          children: [
            _buildProfileHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFeatureGrid(context),
                  const SizedBox(height: 24),
                  _buildUtilitiesSection(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 90, 145, 171),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 3,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildAvatar(),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome Back!',
                style: TextStyle(
                  color: const Color.fromARGB(255, 68, 11, 225),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Text(
                'Muslim User',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blueGrey,
        border: Border.all(color: Colors.white24, width: 2),
        image: DecorationImage(
          image: AssetImage("assets/icon/quran2.png"),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      childAspectRatio: 0.8,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildFeatureCard(
          context: context,
          icon: Icons.calendar_today,
          title: 'Hijri Calendar',
          color: Colors.purple.shade100,
          onTap: () => _navigateTo(context, const HijriCalendarScreen()),
        ),
        _buildFeatureCard(
          context: context,
          icon: Icons.explore,
          title: 'Qibla Direction',
          color: Colors.blue.shade100,
          onTap: () => _navigateTo(context, const QiblaDirectionScreen()),
        ),
        _buildFeatureCard(
          context: context,
          icon: Icons.handshake,
          title: 'Dua & Azkar',
          color: Colors.orange.shade100,
          onTap: () => _navigateTo(context, DuaAzkarScreen()),
        ),
        _buildFeatureCard(
          context: context,
          icon: Icons.calendar_month_rounded,
          title: 'Both Calendars',
          color: Colors.teal.shade100,
          onTap: () => _navigateTo(context, const EnhancedCalendarScreen()),
        ),
        _buildFeatureCard(
          context: context,
          icon: Icons.date_range,
          title: 'Monthly Prayer Times',
          color: const Color.fromARGB(255, 51, 232, 217),
          onTap: () => _navigateTo(context, const PrayerTimes()),
        ),
        _buildFeatureCard(
          context: context,
          icon: Icons.book,
          title: 'Aurad e Fatiha',
          color: const Color.fromARGB(145, 104, 142, 195),
          onTap: () => _navigateTo(context, PDFScreen()),
        ),
        _buildFeatureCard(
          context: context,
          icon: Icons.auto_awesome,
          title: 'Tasbih',
          color: const Color.fromARGB(145, 149, 117, 212),
          onTap: () => _navigateTo(context, TasbihScreen()),
        ),
        _buildFeatureCard(
          context: context,
          icon: Icons.auto_awesome_motion,
          title: '99 Names of Allah',
          color: const Color.fromARGB(145, 183, 209, 143),
          onTap: () => _navigateTo(context, NamesScreen()),
        ),
        _buildFeatureCard(
          context: context,
          icon: Icons.calculate,
          title: 'Zakat Calculator',
          color: const Color.fromARGB(145, 228, 234, 171),
          onTap: () => _navigateTo(context, ZakatCalculatorScreen()),
        ),
      ],
    );
  }

  Widget _buildUtilitiesSection(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100, width: 1),
      ),
      child: Column(
        children: [
          _buildUtilityTile(
            icon: Icons.settings,
            title: 'App Settings',
            color: Colors.grey.shade800,
            onTap: () => _navigateTo(context, const MSettingsScreen()),
          ),
          _buildDivider(),
          const Divider(),
          _buildUtilityTile(
            icon: Icons.feedback,
            title: 'Send Feedback',
            color: Colors.grey.shade800,
            onTap: () => _handleFeedback(context),
          ),
          _buildDivider(),
          const Divider(),
          _buildUtilityTile(
            icon: Icons.share,
            title: 'Share App',
            color: Colors.grey.shade800,
            onTap: () => _shareApp(context),
          ),
          _buildDivider(),
          const Divider(),
          _buildUtilityTile(
            icon: Icons.star_rate,
            title: 'Rate App',
            color: Colors.grey.shade800,
            onTap: () => _rateApp(context),
          ),
          _buildDivider(),
          const Divider(),
          _buildUtilityTile(
            icon: Icons.info_outline,
            title: 'About Us',
            color: Colors.grey.shade800,
            onTap: () => _AboutUs(context),
          ),
          _buildDivider(),
          const Divider(),
          _buildUtilityTile(
            icon: Icons.support,
            title: 'Support Us',
            color: Colors.grey.shade800,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SupportScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      borderRadius: BorderRadius.circular(16),
      color: color,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 34, color: Colors.black87),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityTile({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color)),
      trailing: Icon(Icons.chevron_right, color: color.withOpacity(0.6)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      visualDensity: const VisualDensity(vertical: -2),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 20,
      endIndent: 20,
      color: Colors.grey.shade200,
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  void _handleFeedback(BuildContext context) async {
    final feedbackController = TextEditingController();
    final packageInfo = await PackageInfo.fromPlatform();
    final deviceInfoPlugin = DeviceInfoPlugin();

    // Get clean device information
    String deviceInfoString = await _getCleanDeviceInfo(deviceInfoPlugin);
    deviceInfoString += 'App Version: ${packageInfo.version}\n';
    deviceInfoString += 'Build Number: ${packageInfo.buildNumber}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 24,
              right: 24,
              top: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Send Feedback',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: feedbackController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: 'Write your feedback here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.send, color: Colors.white),
                  label: const Text('Send Feedback'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final feedbackText = feedbackController.text.trim();
                    if (feedbackText.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please enter your feedback'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    final Uri emailUri = Uri(
                      scheme: 'mailto',
                      path: 'lonekaiser04@gmail.com',
                      queryParameters: {
                        'subject': Uri.encodeComponent('App Feedback'),
                        'body': Uri.encodeComponent(
                          '$feedbackText\n\n--- Technical Information ---\n$deviceInfoString',
                        ),
                      },
                    );

                    try {
                      final parentContext = context;
                      if (await launchUrl(emailUri)) {
                        Navigator.pop(parentContext);
                        _AppResumeObserver(
                          onResume:
                              () => ScaffoldMessenger.of(
                                parentContext,
                              ).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Feedback submitted successfully!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Failed to send feedback: ${e.toString()}',
                          ),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                ),
                const SizedBox(height: 8),
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
    );
  }

  // Clean device info formatter
  Future<String> _getCleanDeviceInfo(DeviceInfoPlugin deviceInfo) async {
    try {
      final deviceData = await deviceInfo.deviceInfo;

      if (deviceData is AndroidDeviceInfo) {
        return 'Device: ${deviceData.model}\nOS Version: Android ${deviceData.version.release}\n';
      }
      if (deviceData is IosDeviceInfo) {
        return 'Device: ${deviceData.name}\nOS Version: iOS ${deviceData.systemVersion}\n';
      }
      return ''; // Return empty for other platforms
    } catch (_) {
      return '';
    }
  }

  void _shareApp(BuildContext context) {
    try {
      Share.share(
        'Check out Islam99 - the all-in-one Islamic app!\n'
        '📱 Features Include:\n'
        '- Prayer Times & Qibla Direction\n'
        '- Quran with Translations\n'
        '- Hadith Collection\n'
        '- Islamic Calendar\n'
        '- Dua & Azkar\n\n'
        'Download now: https://play.google.com/store/apps/details?id=com.Islam99.app',
        subject: 'Islam99 - Islamic Companion App',
        sharePositionOrigin: Rect.largest,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _rateApp(BuildContext context) async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    String appStoreUrl = '';

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        appStoreUrl =
            androidInfo.version.sdkInt >= 21
                ? 'market://details?id=com.Islam99.app'
                : 'https://play.google.com/store/apps/details?id=com.Islam99.app';
      } else if (Platform.isIOS) {
        appStoreUrl = 'itms-apps://itunes.apple.com/app/idYOUR_APPLE_ID';
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rating not supported on this platform'),
          ),
        );
        return;
      }

      if (await canLaunch(appStoreUrl)) {
        await launch(appStoreUrl);
      } else {
        throw Exception('Could not launch app store');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open app store: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Open Web',
            onPressed:
                () => launch(
                  Platform.isAndroid
                      ? 'https://play.google.com/store/apps/details?id=com.Islam99.app'
                      : 'https://apps.apple.com/app/idYOUR_APPLE_ID',
                ),
          ),
        ),
      );
    }
  }
}

void _AboutUs(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        backgroundColor: Colors.white,
        title: Column(
          children: [
            Icon(Icons.info_outline, size: 50, color: Colors.blue),
            SizedBox(height: 10),
            Text(
              "About Islam99",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Islam99 is an all-in-one Islamic app providing accurate prayer times, Quran, Hadith, Qibla direction, Islamic events, and more.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 15),
            Divider(),
            Text(
              "📌 Developed by: Kaiser Mohiuddin.\n  📌  Version: 1.0.0",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 15),
            Divider(),
            Text(
              "📞 Contact Us",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.email, color: Colors.blue),
                SizedBox(width: 5),
                SelectableText("Lonekaiser04@gmail.com"),
              ],
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.language, color: Colors.green),
                SizedBox(width: 5),
                SelectableText("www.Islam99.com"),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Close", style: TextStyle(color: Colors.red)),
          ),
        ],
      );
    },
  );
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const CustomAppBar({required this.title, super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).primaryColor,
              Theme.of(context).primaryColor.withOpacity(0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
    );
  }
}
