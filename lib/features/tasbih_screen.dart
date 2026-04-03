import 'package:flutter/material.dart';
import 'package:vibration/vibration.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';
// import 'package:sensors_plus/sensors_plus.dart';

class TasbihScreen extends StatefulWidget {
  @override
  _TasbihScreenState createState() => _TasbihScreenState();
}

class _TasbihScreenState extends State<TasbihScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _counter = 0;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  bool _autoReset = true;
  double _buttonScale = 1.0;
  late Dhikr _selectedDhikr = dhikrList[0];
  // final double _maxShakeThreshold = 15.0;

  final List<Dhikr> dhikrList = [
    Dhikr(
      name: "Subhanallah",
      arabic: "سُبْحَانَ اللَّهِ",
      transliteration: "Subḥān Allāh",
      recommendedCount: 33,
    ),
    Dhikr(
      name: "Alhamdulillah",
      arabic: "الْحَمْدُ لِلَّهِ",
      transliteration: "Al-ḥamdu lillāh",
      recommendedCount: 33,
    ),
    Dhikr(
      name: "Allahu Akbar",
      arabic: "اللَّهُ أَكْبَرُ",
      transliteration: "Allāhu Akbar",
      recommendedCount: 34,
    ),
    Dhikr(
      name: "La ilaha illallah",
      arabic: "لَا إِلٰهَ إِلَّا اللَّهُ",
      transliteration: "Lā ilāha illā Allāh",
      recommendedCount: 100,
    ),
    Dhikr(
      name: "Astaghfirullah",
      arabic: "أَسْتَغْفِرُ اللَّهَ",
      transliteration: "Astaghfiru Allāh",
      recommendedCount: 100,
    ),
    Dhikr(
      name: "La hawla wa la quwwata illa billah",
      arabic: "لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ",
      transliteration: "Lā ḥawla wa lā quwwata illā billāh",
      recommendedCount: 100,
    ),
    Dhikr(
      name: "Subhanallahi wa bihamdihi",
      arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ",
      transliteration: "Subḥānallāhi wa biḥamdih",
      recommendedCount: 100,
    ),
    Dhikr(
      name: "Subhanallahi wa bihamdihi, Subhanallahil azeem",
      arabic: "سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ",
      transliteration: "Subḥānallāhi wa biḥamdih, Subḥānallāhil ‘Aẓīm",
      recommendedCount: 100,
    ),
    Dhikr(
      name: "Hasbunallahu wa ni'mal wakeel",
      arabic: "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ",
      transliteration: "Ḥasbunallāhu wa ni‘mal wakīl",
      recommendedCount: 100,
    ),
    Dhikr(
      name: "La ilaha illa anta subhanaka inni kuntu minaz-zalimin",
      arabic:
          "لَا إِلٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ",
      transliteration: "Lā ilāha illā anta subḥānaka innī kuntu minaẓ-ẓālimīn",
      recommendedCount: 100,
    ),
    Dhikr(
      name: "Rabbi zidni ilma",
      arabic: "رَبِّ زِدْنِي عِلْمًا",
      transliteration: "Rabbi zidnī ‘ilmā",
      recommendedCount: 100,
    ),
    Dhikr(
      name: "Allahumma salli ala Muhammad",
      arabic: "اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ",
      transliteration: "Allāhumma ṣalli ‘alā Muḥammad",
      recommendedCount: 100,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  void _initAudio() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.release);
  }

  void _incrementCounter() async {
    try {
      setState(() {
        _counter++;
        _buttonScale = 1.2;
      });

      if (_soundEnabled) {
        await _audioPlayer.play(AssetSource('sounds/tap.mp3'));
      }

      if (_vibrationEnabled) {
        if (await Vibration.hasVibrator()) {
          if (await Vibration.hasAmplitudeControl()) {
            Vibration.vibrate(amplitude: 128, duration: 50);
          } else {
            Vibration.vibrate(duration: 50);
          }
        }
      }

      Future.delayed(Duration(milliseconds: 150), () {
        setState(() => _buttonScale = 1.0);
      });

      if (_autoReset && _counter >= _selectedDhikr.recommendedCount) {
        _showResetConfirmation();
      }
    } catch (e) {
      print('Error in increment: $e');
    }
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.blueGrey[800],
            title: Text(
              'Auto Reset',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              'Counter has reached ${_selectedDhikr.recommendedCount}',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: Colors.teal),
                ),
              ),
            ],
          ),
    );
    _resetCounter();
  }

  void _resetCounter() {
    setState(() {
      _counter = 0;
      if (_vibrationEnabled) Vibration.vibrate(duration: 100);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonSize = screenWidth * 0.3;
    final iconSize = screenWidth * 0.08;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Digital Tasbih',
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: screenWidth * 0.045,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [_buildSettingsPopup()],
      ),
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
            padding: EdgeInsets.all(screenWidth * 0.04),
            child: Column(
              children: [
                // Dhikr Selector
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.05,
                    vertical: screenWidth * 0.02,
                  ),
                  margin: EdgeInsets.only(bottom: screenWidth * 0.04),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Dhikr>(
                      value: _selectedDhikr,
                      icon: Icon(Icons.expand_more, color: Colors.white),
                      dropdownColor: Colors.blueGrey[800],
                      isExpanded: true,
                      items:
                          dhikrList.map((Dhikr dhikr) {
                            return DropdownMenuItem<Dhikr>(
                              value: dhikr,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: screenWidth * 0.02,
                                ),
                                child: Text(
                                  dhikr.name,
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: screenWidth * 0.04,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                      onChanged: (Dhikr? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedDhikr = newValue;
                            _resetCounter();
                          });
                        }
                      },
                    ),
                  ),
                ),
                // Counter Display
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: _counter / _selectedDhikr.recommendedCount,
                          backgroundColor: Colors.white.withOpacity(0.1),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _counter >= _selectedDhikr.recommendedCount
                                ? Colors.amber
                                : Colors.teal,
                          ),
                          strokeWidth: screenWidth * 0.02,
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedSwitcher(
                              duration: Duration(milliseconds: 200),
                              child: Text(
                                '$_counter',
                                key: ValueKey<int>(_counter),
                                style: GoogleFonts.poppins(
                                  fontSize: screenWidth * 0.2,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            Text(
                              _selectedDhikr.arabic,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.amiri(
                                fontSize: screenWidth * 0.08,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: screenWidth * 0.02),
                            Text(
                              _selectedDhikr.transliteration,
                              style: GoogleFonts.poppins(
                                fontSize: screenWidth * 0.04,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Control Buttons
                Padding(
                  padding: EdgeInsets.symmetric(vertical: screenWidth * 0.04),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ControlButton(
                            icon: Icons.refresh,
                            onPressed: _resetCounter,
                            color: Colors.redAccent,
                            tooltip: 'Reset Counter',
                            size: screenWidth * 0.15,
                          ),
                          SizedBox(width: screenWidth * 0.1),
                          AnimatedScale(
                            scale: _buttonScale,
                            duration: Duration(milliseconds: 100),
                            child: GestureDetector(
                              onTap: _incrementCounter,
                              child: Container(
                                width: buttonSize,
                                height: buttonSize,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Color(0xFF4CAF50),
                                      Color(0xFF45C7B8),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.teal.withOpacity(0.4),
                                      blurRadius: 15,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  Icons.touch_app,
                                  size: iconSize,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: screenWidth * 0.04),
                      // Settings Toggles
                      _SettingsRow(
                        soundEnabled: _soundEnabled,
                        vibrationEnabled: _vibrationEnabled,
                        autoReset: _autoReset,
                        onSoundPressed:
                            () =>
                                setState(() => _soundEnabled = !_soundEnabled),
                        onVibrationPressed:
                            () => setState(
                              () => _vibrationEnabled = !_vibrationEnabled,
                            ),
                        onAutoResetPressed:
                            () => setState(() => _autoReset = !_autoReset),
                        iconSize: iconSize,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPopup() {
    return PopupMenuButton(
      icon: Icon(Icons.more_vert, color: Colors.white),
      itemBuilder:
          (context) => [
            PopupMenuItem(
              child: ListTile(
                leading: Icon(Icons.info, color: Colors.blueGrey),
                title: Text('About', style: GoogleFonts.poppins()),
                onTap: () => _showAboutDialog(),
              ),
            ),
          ],
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Colors.blueGrey[800],
            title: Text(
              'Digital Tasbih',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
            content: Text(
              'Made with ❤️ for Muslim Community\nVersion 1.0.0',
              style: GoogleFonts.poppins(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.poppins(color: Colors.teal),
                ),
              ),
            ],
          ),
    );
  }
}

class Dhikr {
  final String name;
  final String arabic;
  final String transliteration;
  final int recommendedCount;

  Dhikr({
    required this.name,
    required this.arabic,
    required this.transliteration,
    required this.recommendedCount,
  });
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final String tooltip;
  final double size;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    required this.tooltip,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: IconButton(
          icon: Icon(icon, color: color),
          iconSize: size * 0.5,
          onPressed: onPressed,
        ),
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool autoReset;
  final VoidCallback onSoundPressed;
  final VoidCallback onVibrationPressed;
  final VoidCallback onAutoResetPressed;
  final double iconSize;

  const _SettingsRow({
    required this.soundEnabled,
    required this.vibrationEnabled,
    required this.autoReset,
    required this.onSoundPressed,
    required this.onVibrationPressed,
    required this.onAutoResetPressed,
    required this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _ToggleButton(
          icon: soundEnabled ? Icons.volume_up : Icons.volume_off,
          active: soundEnabled,
          onPressed: onSoundPressed,
          iconSize: iconSize,
          label: 'Sound',
        ),
        _ToggleButton(
          icon: vibrationEnabled ? Icons.vibration : Icons.vibration_rounded,
          active: vibrationEnabled,
          onPressed: onVibrationPressed,
          iconSize: iconSize,
          label: 'Vibrate',
        ),
        _ToggleButton(
          icon: autoReset ? Icons.autorenew : Icons.autorenew_outlined,
          active: autoReset,
          onPressed: onAutoResetPressed,
          iconSize: iconSize,
          label: 'Auto Reset',
        ),
      ],
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;
  final double iconSize;
  final String label;

  const _ToggleButton({
    required this.icon,
    required this.active,
    required this.onPressed,
    required this.iconSize,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          IconButton(
            icon: Icon(
              icon,
              color: active ? Colors.teal : Colors.white70,
              size: iconSize,
            ),
            onPressed: onPressed,
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              color: active ? Colors.teal : Colors.white70,
              fontSize: iconSize * 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
