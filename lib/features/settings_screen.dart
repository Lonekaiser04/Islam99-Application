import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart'; // Import your ThemeProvider

class MSettingsScreen extends StatefulWidget {
  const MSettingsScreen({super.key});

  @override
  State<MSettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<MSettingsScreen> {
  bool _notificationsEnabled = true;
  bool _hijriDateEnabled = true;
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors:
                  isDarkMode
                      ? [Colors.teal.shade800, Colors.teal.shade600]
                      : [Colors.teal, Colors.teal.shade400],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // About Section
            _buildSectionHeader('About Islam99'),
            const SizedBox(height: 10),
            _buildSectionContent(
              'Islam99 is a comprehensive Islamic app designed to provide Muslims with essential tools and resources for their daily lives. '
              'It includes features like Prayer Times, Hijri Calendar, Duas & Azkar, Qibla Direction, Quran, and Hadith collections. '
              'The app is developed with the aim of helping users stay connected to their faith and practice Islam with ease.',
            ),
            const SizedBox(height: 20),

            // Developer Information
            _buildSectionHeader('Developer Information'),
            const SizedBox(height: 10),
            _buildSectionContent(
              'Developed by: KAISER MOHI-U-DIN\n'
              'Email: Lonekaiser04@gmail.com\n'
              'Version: 1.0.0',
              textColor: Colors.teal,
            ),
            const SizedBox(height: 20),

            // App Settings
            _buildSectionHeader('App Settings'),
            const SizedBox(height: 10),

            // Dark Mode Toggle
            _buildSettingTile(
              icon: Icons.dark_mode,
              title: 'Dark Mode',
              trailing: Switch(
                value: themeProvider.themeMode == ThemeMode.dark,
                onChanged: (value) {
                  themeProvider.setThemeMode(
                    value ? ThemeMode.dark : ThemeMode.light,
                  );
                },
              ),
            ),

            // Notifications Toggle
            _buildSettingTile(
              icon: Icons.notifications,
              title: 'Enable Notifications',
              trailing: Switch(
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() {
                    _notificationsEnabled = value;
                  });
                },
              ),
            ),

            // Hijri Date Toggle
            _buildSettingTile(
              icon: Icons.calendar_today,
              title: 'Show Hijri Date',
              trailing: Switch(
                value: _hijriDateEnabled,
                onChanged: (value) {
                  setState(() {
                    _hijriDateEnabled = value;
                  });
                },
              ),
            ),

            // Language Selection
            _buildSettingTile(
              icon: Icons.language,
              title: 'Language',
              trailing: DropdownButton<String>(
                value: _language,
                dropdownColor:
                    isDarkMode
                        ? Colors.grey.shade800
                        : const Color.fromARGB(255, 22, 197, 156),
                items:
                    [
                          'English',
                          'Arabic',
                          'Urdu',
                          "French",
                          "Spanish",
                          "Kashmiri",
                        ]
                        .map(
                          (language) => DropdownMenuItem(
                            value: language,
                            child: Text(language),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    _language = value!;
                  });
                },
              ),
            ),

            // Feedback Section
            _buildSectionHeader('Feedback'),
            const SizedBox(height: 10),
            _buildSectionContent(
              'We value your feedback! If you have any suggestions or issues, please let us know.',
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                // Navigate to feedback screen or open email
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              child: const Text(
                'Send Feedback',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build section headers
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.teal,
      ),
    );
  }

  // Helper method to build section content
  Widget _buildSectionContent(
    String content, {
    Color textColor = Colors.black87,
  }) {
    return Text(content, style: TextStyle(fontSize: 16, color: textColor));
  }

  // Helper method to build setting tiles
  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Widget trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal),
      title: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: trailing,
    );
  }
}
