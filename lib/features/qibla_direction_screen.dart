import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:math';

class QiblaDirectionScreen extends StatefulWidget {
  const QiblaDirectionScreen({super.key});

  @override
  State<QiblaDirectionScreen> createState() => _QiblaDirectionScreenState();
}

class _QiblaDirectionScreenState extends State<QiblaDirectionScreen> {
  double? _qiblaDirection; // Qibla direction in degrees
  double? _currentHeading; // Current device heading in degrees
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  /// Initialize compass and location services
  Future<void> _initialize() async {
    try {
      // Check location permissions
      bool hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        setState(() {
          _errorMessage =
              'Location permission denied. Please enable it in settings.';
          _isLoading = false;
        });
        return;
      }

      // Get user's current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate Qibla direction
      _qiblaDirection = _calculateQiblaDirection(
        position.latitude,
        position.longitude,
      );

      // Listen to compass updates
      FlutterCompass.events?.listen((event) {
        setState(() {
          _currentHeading = event.heading;
        });
      });

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  /// Check and request location permissions
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _errorMessage = 'Location services are disabled. Please enable GPS.';
      });
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }
    return true;
  }

  /// Calculate Qibla direction based on latitude and longitude
  double _calculateQiblaDirection(double latitude, double longitude) {
    // Kaaba coordinates
    const double kaabaLat = 21.422487;
    const double kaabaLng = 39.826206;

    // Convert degrees to radians
    double latRad = latitude * pi / 180;
    double lngRad = longitude * pi / 180;
    double kaabaLatRad = kaabaLat * pi / 180;
    double kaabaLngRad = kaabaLng * pi / 180;

    // Calculate Qibla direction
    double y = sin(kaabaLngRad - lngRad);
    double x =
        cos(latRad) * tan(kaabaLatRad) -
        sin(latRad) * cos(kaabaLngRad - lngRad);
    double qiblaDirection = atan2(y, x) * 180 / pi;

    // Normalize to 0-360 degrees
    return (qiblaDirection + 360) % 360;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade900, Colors.blue.shade400],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child:
              _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : _errorMessage.isNotEmpty
                  ? Text(
                    _errorMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                    textAlign: TextAlign.center,
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Compass UI
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Compass background
                          Container(
                            width: 250,
                            height: 250,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.8),
                                width: 4,
                              ),
                            ),
                            child: CustomPaint(painter: CompassPainter()),
                          ),
                          // Qibla direction arrow
                          Transform.rotate(
                            angle:
                                ((_currentHeading ?? 0) -
                                    (_qiblaDirection ?? 0)) *
                                pi /
                                180,
                            child: Icon(
                              Icons.navigation,
                              size: 100,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                      // Qibla direction text
                      Text(
                        'Qibla Direction: ${_qiblaDirection?.toStringAsFixed(2)}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Device Heading: ${_currentHeading?.toStringAsFixed(2)}°',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}

/// Custom painter for drawing the compass
class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Draw compass circle
    final paint =
        Paint()
          ..color = Colors.white.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawCircle(center, radius, paint);

    // Draw compass lines
    for (int i = 0; i < 360; i += 30) {
      final angle = i * pi / 180;
      final start = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final end = Offset(
        center.dx + (radius - 20) * cos(angle),
        center.dy + (radius - 20) * sin(angle),
      );
      canvas.drawLine(start, end, paint);

      // Draw degree labels
      final textPainter = TextPainter(
        text: TextSpan(
          text: '$i°',
          style: TextStyle(color: Colors.white, fontSize: 12),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx + (radius - 30) * cos(angle) - textPainter.width / 2,
          center.dy + (radius - 30) * sin(angle) - textPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
