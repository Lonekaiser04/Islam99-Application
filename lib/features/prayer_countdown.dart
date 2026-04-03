import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

class PrayerCountdown extends StatefulWidget {
  const PrayerCountdown({super.key});

  @override
  State<PrayerCountdown> createState() => _PrayerCountdownState();
}

class _PrayerCountdownState extends State<PrayerCountdown> {
  Map<String, String> prayerTimes = {};
  String nextPrayer = "Fetching...";
  Duration timeRemaining = Duration.zero;
  Timer? _timer;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getUserLocation();
  }

  Future<void> _getUserLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception("Location services are disabled.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied)
          throw Exception("Location permission denied.");
      }

      Position position = await Geolocator.getCurrentPosition();
      setState(() => _currentPosition = position);
      _fetchPrayerTimes(position.latitude, position.longitude);
    } catch (e) {
      setState(() {
        nextPrayer = "Location error!";
      });
    }
  }

  Future<void> _fetchPrayerTimes(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://api.aladhan.com/v1/timings?latitude=$latitude&longitude=$longitude&method=2",
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final timings = data['data']['timings'];

        setState(() {
          prayerTimes = {
            "Fajr": timings["Fajr"],
            "Dhuhr": timings["Dhuhr"],
            "Asr": timings["Asr"],
            "Maghrib": timings["Maghrib"],
            "Isha": timings["Isha"],
          };
        });

        _findNextPrayer();
      } else {
        throw Exception("Failed to load prayer times.");
      }
    } catch (e) {
      setState(() => nextPrayer = "Error fetching times");
    }
  }

  void _findNextPrayer() {
    final now = DateTime.now();
    final dateFormat = DateFormat("HH:mm");

    for (var entry in prayerTimes.entries) {
      final prayerTime = dateFormat.parse(entry.value);
      final todayPrayerTime = DateTime(
        now.year,
        now.month,
        now.day,
        prayerTime.hour,
        prayerTime.minute,
      );

      if (now.isBefore(todayPrayerTime)) {
        setState(() {
          nextPrayer = entry.key;
          timeRemaining = todayPrayerTime.difference(now);
        });
        _startTimer();
        return;
      }
    }

    // If all prayers are over, set Fajr for next day
    final fajrTime = dateFormat.parse(prayerTimes["Fajr"]!);
    final tomorrowFajr = DateTime(
      now.year,
      now.month,
      now.day + 1,
      fajrTime.hour,
      fajrTime.minute,
    );

    setState(() {
      nextPrayer = "Fajr";
      timeRemaining = tomorrowFajr.difference(now);
    });
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (timeRemaining.inSeconds > 0) {
          timeRemaining -= const Duration(seconds: 1);
        } else {
          _fetchPrayerTimes(
            _currentPosition!.latitude,
            _currentPosition!.longitude,
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "${timeRemaining.inHours.toString().padLeft(2, '0')}:${(timeRemaining.inMinutes % 60).toString().padLeft(2, '0')}:${(timeRemaining.inSeconds % 60).toString().padLeft(2, '0')}",
          style: const TextStyle(
            // fontSize: 24,
            // color: Color.fromARGB(255, 6, 206, 241),
            // fontWeight: FontWeight.bold,
            fontSize: 32, // Increased size
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 9, 151, 82),
            // shadows: [
            //   // Shadow(
            //   //   blurRadius: 6,
            //   //   color: Color.fromRGBO(24, 239, 178, 0.502), // Glow effect
            //   // ),
            // ],
          ),
        ),
        Text(
          "NEXT PRAYER: $nextPrayer",
          style: const TextStyle(
            fontSize: 18,
            color: Color.fromARGB(255, 222, 19, 198),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6, width: double.infinity),
      ],
    );
  }
}
