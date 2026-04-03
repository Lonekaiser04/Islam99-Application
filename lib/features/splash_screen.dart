import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:Islam99/main.dart'; // your actual main screen

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  // Simulate loading
  void _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3)); // Delay for 3 seconds
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => MainNavigationScreen(),
      ), // Replace with your home screen
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Change color if needed
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Icon
            Image.asset(
              'assets/icon/quran.png', // Change to your app icon path
              width: 120,
              height: 120,
            ),
            const SizedBox(height: 20),

            // App Name
            Text(
              "ISLAM99",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // Loading Indicator
            SpinKitFadingCircle(
              color: Colors.green,
              size: 50,
            ), // Loading animation
          ],
        ),
      ),
    );
  }
}
