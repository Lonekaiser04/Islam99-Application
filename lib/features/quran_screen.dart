import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:Islam99/Inner_features/surahScreen.dart'; // Import your existing Quran Arabic text screen

class QuranScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;

    return Scaffold(
      // appBar: AppBar(
      //   title: Text(
      //     'All In One Quran',
      //     style: GoogleFonts.poppins(
      //       color: Colors.white,
      //       fontWeight: FontWeight.w600,
      //       fontSize: isTablet ? 28 : 22,
      //     ),
      //   ),
      //   centerTitle: true,
      //   backgroundColor: Colors.transparent,
      //   elevation: 0,
      //   iconTheme: IconThemeData(color: Colors.white),
      // ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1D2B64), Color(0xFF3B3F5B), Color(0xFF7E8AA2)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 40 : 20,
              vertical: 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(context),
                SizedBox(height: 30),
                Expanded(child: _buildFeatureGrid(context, isTablet)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   "Assalamu Alaikum",
        //   style: GoogleFonts.poppins(
        //     color: Colors.white,
        //     fontSize: 24,
        //     fontWeight: FontWeight.w500,
        //   ),
        // ),
        // SizedBox(height: 8),
        // Text(
        //   "Explore the Divine Revelation",
        //   style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
        // ),
        // SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
          ),
          child: TextField(
            decoration: InputDecoration(
              hintText: "Search Quran...",
              hintStyle: GoogleFonts.poppins(color: Colors.white54),
              prefixIcon: Icon(Icons.search, color: Colors.white54),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
            ),
            style: GoogleFonts.poppins(color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureGrid(BuildContext context, bool isTablet) {
    return GridView.count(
      crossAxisCount: isTablet ? 3 : 2,
      mainAxisSpacing: 19,
      crossAxisSpacing: 18,
      childAspectRatio: 0.9,
      children: [
        _buildFeatureTile(
          context,
          icon: Icons.menu_book,
          title: "Quran",
          subtitle: "Original Arabic Text",
          color: Colors.teal,
          onTap: () => _navigateToScreen(context, SurahScreen()),
        ),
        _buildFeatureTile(
          context,
          icon: Icons.translate,
          title: "Translation",
          subtitle: "Multiple Languages",
          color: Colors.blueAccent,
          onTap: () {}, // Add your translation screen navigation
        ),
        _buildFeatureTile(
          context,
          icon: Icons.auto_stories,
          title: "Tafseer",
          subtitle: "Detailed Explanations",
          color: Colors.purpleAccent,
          onTap: () {}, // Add your tafseer screen navigation
        ),
        _buildFeatureTile(
          context,
          icon: Icons.volume_up,
          title: "Audio",
          subtitle: "Recitations by Qaris",
          color: Colors.orange,
          onTap: () {}, // Add your audio screen navigation
        ),
        _buildFeatureTile(
          context,
          icon: Icons.bookmark,
          title: "Bookmarks",
          subtitle: "Saved Verses",
          color: Colors.pinkAccent,
          onTap: () {}, // Add your bookmarks screen navigation
        ),
        _buildFeatureTile(
          context,
          icon: Icons.history,
          title: "History",
          subtitle: "Recent Readings",
          color: Colors.lightGreen,
          onTap: () {}, // Add your history screen navigation
        ),
      ],
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: color),
              ),
              SizedBox(height: 15),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 5),
              Text(
                subtitle,
                style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToScreen(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }
}
