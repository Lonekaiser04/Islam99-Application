// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:geocoding/geocoding.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:intl/intl.dart';
// import 'package:hive/hive.dart';
// import 'package:shimmer/shimmer.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/timezone.dart' as tz;
// import 'package:timezone/data/latest_all.dart' as tzData;

// // Color Scheme Constants
// const Color primaryColor = Color(0xFF2D3250);
// const Color secondaryColor = Color(0xFF5B5F7F);
// const Color surfaceColor = Color(0xFFF8F9FA);
// const Color onPrimaryColor = Colors.white;
// const Color highlightColor = Color(0xFF7077A1);

// class PrayerTimesScreen extends StatefulWidget {
//   const PrayerTimesScreen({super.key});

//   @override
//   State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
// }

// class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
//   late Box _settingsBox;
//   final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();
//   Map<String, dynamic> _appSettings = {
//     'calculationMethod': 2,
//     'convention': 'Standard',
//     'manualAdjustments': {},
//     'location': 'Current Location',
//     'notifications': true,
//     'notificationOffset': 10,
//     'textScale': 1.0,
//   };
//   late Box _prayerBox;
//   final Map<String, Map<String, String>> _prayerTimesByDate = {};
//   final Map<String, String> _hijriDates = {};
//   bool _isLoading = false;
//   String _errorMessage = '';
//   String _locationName = 'Loading location...';
//   Position? _currentPosition;
//   bool _usingCachedData = false;
//   final List<DateTime> _dateRange = [];
//   DateTime _selectedDate = DateTime.now();
//   late PageController _pageController;
//   final _dateFormatter = DateFormat('yyyy-MM-dd');
//   final _apiDateFormatter = DateFormat('dd-MM-yyyy');
//   String? _nextPrayer;
//   Timer? _nextPrayerTimer;

//   @override
//   void initState() {
//     super.initState();
//     tzData.initializeTimeZones();
//     _initializeDates();
//     _initializeHive();
//     _initializeSettings();
//     _initializeNotifications();
//     _setupNextPrayerTimer();
//   }

//   void _setupNextPrayerTimer() {
//     _nextPrayerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
//       _determineNextPrayer();
//     });
//   }

//   Future<void> _initializeSettings() async {
//     if (!Hive.isBoxOpen('settings')) {
//       await Hive.openBox('settings');
//     }
//     _settingsBox = Hive.box('settings');
//     _loadSettings();
//   }

//   void _loadSettings() {
//     setState(() {
//       _appSettings = Map<String, dynamic>.from(
//         _settingsBox.get('settings', defaultValue: _appSettings),
//       );
//     });
//   }

//   Future<void> _initializeNotifications() async {
//     const AndroidInitializationSettings initializationSettingsAndroid =
//         AndroidInitializationSettings('app_icon');
//     final InitializationSettings initializationSettings =
//         InitializationSettings(android: initializationSettingsAndroid);
//     await _notificationsPlugin.initialize(initializationSettings);
//   }

//   void _initializeDates() {
//     final today = DateTime.now();
//     final todayMidnight = DateTime(today.year, today.month, today.day);
//     _dateRange.addAll([
//       todayMidnight.subtract(const Duration(days: 2)),
//       todayMidnight.subtract(const Duration(days: 1)),
//       todayMidnight,
//       todayMidnight.add(const Duration(days: 1)),
//       todayMidnight.add(const Duration(days: 2)),
//     ]);
//     _pageController = PageController(initialPage: 2);
//     _selectedDate = _dateRange[2];
//   }

//   Future<void> _initializeHive() async {
//     if (!Hive.isBoxOpen('prayerCache')) {
//       await Hive.openBox('prayerCache');
//     }
//     _prayerBox = Hive.box('prayerCache');
//     _loadCachedData();
//     _getPrayerTimes();
//   }

//   void _loadCachedData() {
//     for (final date in _dateRange) {
//       final dateKey = _dateFormatter.format(date);
//       final cachedData = _prayerBox.get(dateKey);
//       if (cachedData != null) {
//         setState(() {
//           _prayerTimesByDate[dateKey] = Map<String, String>.from(
//             cachedData['times'],
//           );
//           _hijriDates[dateKey] = cachedData['hijri'] ?? '';
//           _locationName = cachedData['location'] ?? _locationName;
//           _usingCachedData = true;
//         });
//       }
//     }
//   }

//   Future<void> _getPrayerTimes() async {
//     if (_isLoading) return;
//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//       _usingCachedData = false;
//     });

//     try {
//       final position = await _getPosition();
//       await _updateLocationName(position);

//       final response = await http.get(
//         Uri.parse(
//           'https://api.aladhan.com/v1/calendar?latitude=${position.latitude}'
//           '&longitude=${position.longitude}&method=${_appSettings['calculationMethod']}&'
//           'start=${_formatAPIDate(_dateRange.first)}&end=${_formatAPIDate(_dateRange.last)}',
//         ),
//       );

//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         _processPrayerTimes(data);
//         _cacheData(data);
//         _determineNextPrayer();
//         _scheduleNotifications();
//       } else {
//         throw Exception('Failed to load prayer times: ${response.statusCode}');
//       }
//     } catch (e) {
//       setState(() => _errorMessage = _getErrorMessage(e));
//       if (_prayerTimesByDate.isEmpty) _loadCachedData();
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   String _formatAPIDate(DateTime date) => _apiDateFormatter.format(date);

//   void _processPrayerTimes(Map<String, dynamic> data) {
//     final days = data['data'] as List;
//     for (final day in days) {
//       try {
//         final dateStr = day['date']['gregorian']['date'];
//         final parsedDate = _apiDateFormatter.parse(dateStr);
//         final dateKey = _dateFormatter.format(parsedDate);

//         final timings = Map<String, String>.from(day['timings']);
//         final cleanedTimings = {
//           'Fajr': timings['Fajr']?.split(' ').first ?? '',
//           'Sunrise': timings['Sunrise']?.split(' ').first ?? '',
//           'Dhuhr': timings['Dhuhr']?.split(' ').first ?? '',
//           'Asr': timings['Asr']?.split(' ').first ?? '',
//           'Maghrib': timings['Maghrib']?.split(' ').first ?? '',
//           'Isha': timings['Isha']?.split(' ').first ?? '',
//         };

//         final hijriDate = day['date']['hijri']['date'];
//         final hijriDesignation =
//             day['date']['hijri']['designation']['abbreviated'];
//         final hijriDateStr = '$hijriDate $hijriDesignation';

//         setState(() {
//           _prayerTimesByDate[dateKey] = cleanedTimings;
//           _hijriDates[dateKey] = hijriDateStr;
//         });
//       } catch (e) {
//         print('Error processing date: $e');
//       }
//     }
//   }

//   void _cacheData(Map<String, dynamic> data) {
//     final days = data['data'] as List;
//     for (final day in days) {
//       try {
//         final dateStr = day['date']['gregorian']['date'];
//         final parsedDate = _apiDateFormatter.parse(dateStr);
//         final dateKey = _dateFormatter.format(parsedDate);

//         _prayerBox.put(dateKey, {
//           'times': _prayerTimesByDate[dateKey],
//           'hijri': _hijriDates[dateKey],
//           'location': _locationName,
//         });
//       } catch (e) {
//         print('Error caching data: $e');
//       }
//     }
//   }

//   void _determineNextPrayer() {
//     final now = DateTime.now();
//     final todayKey = _dateFormatter.format(now);
//     final times = _prayerTimesByDate[todayKey];
//     if (times == null) return;

//     final prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
//     for (final prayer in prayerOrder) {
//       final timeStr = times[prayer];
//       if (timeStr == null) continue;
//       try {
//         final time = DateFormat('HH:mm').parse(timeStr);
//         final prayerTime = DateTime(
//           now.year,
//           now.month,
//           now.day,
//           time.hour,
//           time.minute,
//         );
//         if (now.isBefore(prayerTime)) {
//           setState(() => _nextPrayer = prayer);
//           return;
//         }
//       } catch (e) {
//         print('Error parsing prayer time: $e');
//       }
//     }
//     setState(() => _nextPrayer = null);
//   }

//   Future<Position> _getPosition() async {
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) throw Exception('Location services are disabled');

//     LocationPermission permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission != LocationPermission.whileInUse &&
//           permission != LocationPermission.always) {
//         throw Exception('Location permissions denied');
//       }
//     }

//     try {
//       _currentPosition = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.medium,
//       );
//       return _currentPosition!;
//     } catch (e) {
//       throw Exception('Error getting position: ${e.toString()}');
//     }
//   }

//   Future<void> _updateLocationName(Position position) async {
//     try {
//       final places = await placemarkFromCoordinates(
//         position.latitude,
//         position.longitude,
//       );

//       final place = places.first;
//       setState(() {
//         _locationName = [
//           if (place.subLocality != null) place.subLocality,
//           if (place.locality != null) place.locality,
//           if (place.administrativeArea != null) place.administrativeArea,
//         ].where((part) => part?.isNotEmpty ?? false).join(', ');
//       });
//     } catch (e) {
//       setState(() => _locationName = 'Current Location');
//     }
//   }

//   void _navigateToSettings(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder:
//             (context) => SettingsScreen(
//               settings: _appSettings,
//               onSettingsChanged: (newSettings) {
//                 setState(() => _appSettings = newSettings);
//                 _settingsBox.put('settings', newSettings);
//                 _getPrayerTimes();
//               },
//             ),
//       ),
//     );
//   }

//   Future<void> _scheduleNotifications() async {
//     // guard + clear previous schedules
//     if (!(_appSettings['notifications'] == true)) return;
//     await _notificationsPlugin.cancelAll();

//     final int offsetMinutes = _appSettings['notificationOffset'] ?? 0;

//     try {
//       for (final entry in _prayerTimesByDate.entries) {
//         final DateTime date = _dateFormatter.parse(entry.key);
//         final times = entry.value; // Map<String, String>

//         for (final prayerEntry in times.entries) {
//           // Expecting values like "05:30 AM" or "17:10"
//           final parts = prayerEntry.value.split(':');
//           if (parts.length < 2) continue;

//           final int? hour = int.tryParse(parts[0]);
//           final String minutePart = parts[1].split(' ').first;
//           final int? minute = int.tryParse(minutePart);
//           if (hour == null || minute == null) continue;

//           final tz.TZDateTime scheduledTime = tz.TZDateTime(
//             tz.local,
//             date.year,
//             date.month,
//             date.day,
//             hour,
//             minute,
//           ).subtract(Duration(minutes: offsetMinutes));

//           // skip past times
//           if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) continue;

//           final int id =
//               prayerEntry.key.hashCode ^ date.hashCode; // stable unique id

//           await _notificationsPlugin.zonedSchedule(
//             id,
//             'Prayer Time Reminder',
//             '${prayerEntry.key} prayer in $offsetMinutes minutes',
//             scheduledTime,
//             const NotificationDetails(
//               android: AndroidNotificationDetails(
//                 'prayer_channel',
//                 'Prayer Times',
//                 channelDescription: 'Reminders for upcoming prayers',
//                 importance: Importance.high,
//                 priority: Priority.high,
//               ),
//             ),
//             // NEW API (v16+/v17): use schedule mode instead of deprecated androidAllowWhileIdle
//             androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//             // uiLocalNotificationDateInterpretation:
//             //     UILocalNotificationDateInterpretation.absoluteTime,
//             // one-time schedule; omit matchDateTimeComponents unless you want repeating
//             payload: 'prayer:${prayerEntry.key}',
//           );
//         }
//       }
//     } catch (e) {
//       // never crash the UI due to scheduling
//       // ignore: avoid_print
//       print('Notification scheduling error: $e');
//     }
//   }

//   String _getErrorMessage(dynamic error) =>
//       error.toString().replaceAll('Exception: ', '');

//   String _formatTime(String time) {
//     try {
//       return DateFormat('h:mm a').format(DateFormat('HH:mm').parse(time));
//     } catch (e) {
//       return time;
//     }
//   }

//   @override
//   void dispose() {
//     _nextPrayerTimer?.cancel();
//     _pageController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back, color: onPrimaryColor),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         backgroundColor: primaryColor,
//         title: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Prayer Times',
//               style: TextStyle(color: onPrimaryColor, fontSize: 20),
//             ),
//             Text(
//               _locationName,
//               style: TextStyle(
//                 color: onPrimaryColor.withOpacity(0.9),
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.settings, color: onPrimaryColor),
//             onPressed: () => _navigateToSettings(context),
//           ),
//           IconButton(
//             icon:
//                 _isLoading
//                     ? const SizedBox(
//                       width: 20,
//                       height: 20,
//                       child: CircularProgressIndicator(
//                         strokeWidth: 2,
//                         color: onPrimaryColor,
//                       ),
//                     )
//                     : const Icon(Icons.refresh, color: onPrimaryColor),
//             onPressed: _getPrayerTimes,
//           ),
//         ],
//       ),
//       body: _buildBody(),
//       backgroundColor: surfaceColor,
//     );
//   }

//   Widget _buildBody() {
//     if (_errorMessage.isNotEmpty && _prayerTimesByDate.isEmpty) {
//       return _buildErrorWidget();
//     }

//     return Column(
//       children: [
//         if (_usingCachedData) _buildCacheNotice(),
//         _buildDateSelector(),
//         Expanded(child: _buildMainContent()),
//       ],
//     );
//   }

//   Widget _buildCacheNotice() => Container(
//     padding: const EdgeInsets.symmetric(vertical: 8),
//     color: highlightColor.withOpacity(0.1),
//     child: Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(Icons.info, size: 18, color: highlightColor),
//         const SizedBox(width: 8),
//         Text('Showing cached data', style: TextStyle(color: highlightColor)),
//       ],
//     ),
//   );

//   Widget _buildDateSelector() => SizedBox(
//     height: 80,
//     child: ListView.builder(
//       scrollDirection: Axis.horizontal,
//       itemCount: _dateRange.length,
//       itemBuilder: (context, index) => _buildDateItem(_dateRange[index], index),
//     ),
//   );

//   Widget _buildDateItem(DateTime date, int index) {
//     final isSelected = _dateRange[index] == _selectedDate;
//     return GestureDetector(
//       onTap:
//           () => _pageController.animateToPage(
//             index,
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//           ),
//       child: Container(
//         margin: const EdgeInsets.all(7),
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
//         decoration: BoxDecoration(
//           color: isSelected ? secondaryColor : Colors.transparent,
//           borderRadius: BorderRadius.circular(10),
//           border: Border.all(
//             color:
//                 isSelected
//                     ? primaryColor
//                     : const Color.fromARGB(255, 224, 224, 224),
//           ),
//         ),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text(
//               DateFormat('EEE').format(date),
//               style: TextStyle(
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? onPrimaryColor : primaryColor,
//               ),
//             ),
//             Text(
//               DateFormat('d').format(date),
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.bold,
//                 color: isSelected ? onPrimaryColor : primaryColor,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildMainContent() => PageView.builder(
//     controller: _pageController,
//     itemCount: _dateRange.length,
//     onPageChanged: (index) => setState(() => _selectedDate = _dateRange[index]),
//     itemBuilder: (context, index) => _buildDailyPrayerTimes(_dateRange[index]),
//   );

//   Widget _buildDailyPrayerTimes(DateTime date) {
//     final dateKey = _dateFormatter.format(date);
//     final times = _prayerTimesByDate[dateKey];
//     final isToday = dateKey == _dateFormatter.format(DateTime.now());

//     return RefreshIndicator(
//       onRefresh: _getPrayerTimes,
//       child:
//           times == null
//               ? _buildDateShimmer()
//               : ListView(
//                 padding: const EdgeInsets.all(16),
//                 children: [
//                   _buildDateHeader(date, isToday),
//                   ...times.entries.map(
//                     (entry) => _PrayerTimeItem(
//                       prayer: entry.key,
//                       time: _formatTime(entry.value),
//                       isNext: isToday && entry.key == _nextPrayer,
//                     ),
//                   ),
//                 ],
//               ),
//     );
//   }

//   Widget _buildDateHeader(DateTime date, bool isToday) {
//     final dateKey = _dateFormatter.format(date);
//     final hijriDate = _hijriDates[dateKey] ?? '';

//     return Card(
//       margin: const EdgeInsets.all(16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Container(
//         decoration: BoxDecoration(
//           color: isToday ? highlightColor.withOpacity(0.1) : onPrimaryColor,
//           borderRadius: BorderRadius.circular(16),
//         ),
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           children: [
//             Text(
//               DateFormat('EEEE, MMMM d').format(date),
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//                 color: primaryColor,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               hijriDate,
//               style: TextStyle(fontSize: 14, color: secondaryColor),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _locationName,
//               style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildErrorWidget() => Center(
//     child: Padding(
//       padding: const EdgeInsets.all(20),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.error_outline, size: 48, color: highlightColor),
//           const SizedBox(height: 16),
//           Text(
//             'Error: $_errorMessage',
//             style: TextStyle(color: highlightColor, fontSize: 16),
//             textAlign: TextAlign.center,
//           ),
//           const SizedBox(height: 16),
//           ElevatedButton(
//             onPressed: _getPrayerTimes,
//             style: ElevatedButton.styleFrom(
//               backgroundColor: primaryColor,
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(12),
//               ),
//             ),
//             child: const Text(
//               'Try Again',
//               style: TextStyle(color: Colors.white),
//             ),
//           ),
//         ],
//       ),
//     ),
//   );

//   Widget _buildDateShimmer() => Shimmer.fromColors(
//     baseColor: Colors.grey[300]!,
//     highlightColor: Colors.grey[100]!,
//     child: Padding(
//       padding: const EdgeInsets.all(16),
//       child: Column(
//         children: List.generate(
//           6,
//           (index) => Container(
//             height: 60,
//             margin: const EdgeInsets.only(bottom: 8),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//       ),
//     ),
//   );
// }

// class _PrayerTimeItem extends StatelessWidget {
//   final String prayer;
//   final String time;
//   final bool isNext;

//   const _PrayerTimeItem({
//     required this.prayer,
//     required this.time,
//     this.isNext = false,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
//       elevation: 0,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//         side: BorderSide(
//           color: isNext ? highlightColor : Colors.grey.shade200,
//           width: 1,
//         ),
//       ),
//       child: ListTile(
//         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         leading: Container(
//           padding: const EdgeInsets.all(8),
//           decoration: BoxDecoration(
//             color: highlightColor.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: _getPrayerIcon(),
//         ),
//         title: Text(
//           prayer,
//           style: const TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w600,
//             color: primaryColor,
//           ),
//         ),
//         trailing: Text(
//           time,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: isNext ? secondaryColor : highlightColor,
//           ),
//         ),
//         tileColor:
//             isNext ? highlightColor.withOpacity(0.05) : Colors.transparent,
//       ),
//     );
//   }

//   Icon _getPrayerIcon() {
//     switch (prayer) {
//       case 'Fajr':
//         return const Icon(Icons.nightlight_round, color: primaryColor);
//       case 'Sunrise':
//         return const Icon(Icons.wb_sunny, color: Color(0xFFF6B17A));
//       case 'Dhuhr':
//         return const Icon(Icons.brightness_5, color: Color(0xFFF6B17A));
//       case 'Asr':
//         return const Icon(Icons.brightness_medium, color: primaryColor);
//       case 'Maghrib':
//         return const Icon(Icons.brightness_4, color: primaryColor);
//       case 'Isha':
//         return const Icon(Icons.nightlight_round, color: primaryColor);
//       default:
//         return const Icon(Icons.access_time, color: primaryColor);
//     }
//   }
// }

// class SettingsScreen extends StatefulWidget {
//   final Map<String, dynamic> settings;
//   final Function(Map<String, dynamic>) onSettingsChanged;

//   const SettingsScreen({
//     Key? key,
//     required this.settings,
//     required this.onSettingsChanged,
//   }) : super(key: key);

//   @override
//   State<SettingsScreen> createState() => _SettingsScreenState();
// }

// class _SettingsScreenState extends State<SettingsScreen> {
//   late Map<String, dynamic> _currentSettings;

//   final List<Map<String, dynamic>> _calculationMethods = [
//     {'value': 1, 'name': 'MWL', 'description': 'Muslim World League'},
//     {
//       'value': 2,
//       'name': 'ISNA',
//       'description': 'Islamic Society of North America',
//     },
//     {
//       'value': 3,
//       'name': 'Egyptian',
//       'description': 'Egyptian General Authority',
//     },
//     {
//       'value': 4,
//       'name': 'Umm Al-Qura',
//       'description': 'Umm Al-Qura University, Makkah',
//     },
//     {
//       'value': 5,
//       'name': 'Islamic Sciences',
//       'description': 'University of Islamic Sciences, Karachi',
//     },
//   ];

//   final List<Map<String, dynamic>> _madhhabMethods = [
//     {'value': 0, 'name': 'Shafi/Hanbali/Maliki'},
//     {'value': 1, 'name': 'Hanafi'},
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _currentSettings = Map.from(widget.settings);
//     _currentSettings['madhhab'] ??= 0; // Initialize madhhab if not set
//   }

//   String _getMethodName(int method) {
//     return _calculationMethods.firstWhere(
//       (m) => m['value'] == method,
//       orElse: () => {'name': 'Unknown'},
//     )['name'];
//   }

//   String _getMadhhabName(int method) {
//     return _madhhabMethods.firstWhere(
//       (m) => m['value'] == method,
//       orElse: () => {'name': 'Unknown'},
//     )['name'];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Settings'),
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//               colors: [primaryColor, Color(0xFF4A548C)],
//             ),
//           ),
//         ),
//         foregroundColor: onPrimaryColor,
//       ),
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Color(0xFFF0F5FF), Color(0xFFE6EDFA), Color(0xFFDDE5F5)],
//           ),
//         ),
//         child: ListView(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
//           children: [
//             _buildSectionHeader('LOCATION SETTINGS', Icons.location_on),
//             _buildLocationCard(),

//             const SizedBox(height: 24),
//             _buildSectionHeader('PRAYER CALCULATION', Icons.calculate),
//             _buildCalculationCard(),
//             const SizedBox(height: 16),
//             _buildMadhhabCard(),

//             const SizedBox(height: 24),
//             _buildSectionHeader('NOTIFICATIONS', Icons.notifications),
//             _buildNotificationsCard(),

//             const SizedBox(height: 24),
//             _buildSectionHeader('APPEARANCE', Icons.palette),
//             _buildAppearanceCard(),

//             const SizedBox(height: 24),
//             _buildSectionHeader('ADVANCED', Icons.tune),
//             _buildAdvancedCard(),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: primaryColor,
//         foregroundColor: onPrimaryColor,
//         child: const Icon(Icons.save),
//         onPressed: () => widget.onSettingsChanged(_currentSettings),
//       ),
//     );
//   }

//   Widget _buildSectionHeader(String title, IconData icon) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Row(
//         children: [
//           Icon(icon, color: primaryColor, size: 22),
//           const SizedBox(width: 12),
//           Text(
//             title,
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w600,
//               color: primaryColor,
//               letterSpacing: 0.8,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildLocationCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: primaryColor.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(Icons.location_on, color: primaryColor),
//         ),
//         title: Text(
//           'Location',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: secondaryColor,
//           ),
//         ),
//         subtitle: Text(
//           _currentSettings['location'],
//           style: TextStyle(color: primaryColor),
//         ),
//         trailing: Icon(Icons.chevron_right, color: primaryColor),
//         onTap: _showLocationDialog,
//       ),
//     );
//   }

//   void _showLocationDialog() {
//     String manualLocation = _currentSettings['location'];
//     final controller = TextEditingController(text: manualLocation);

//     showDialog(
//       context: context,
//       builder:
//           (context) => Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: primaryColor,
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.location_on, color: onPrimaryColor),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Change Location',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: onPrimaryColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       ListTile(
//                         contentPadding: EdgeInsets.zero,
//                         leading: Icon(Icons.gps_fixed, color: primaryColor),
//                         title: Text('Use Current Location'),
//                         onTap: () {
//                           setState(
//                             () =>
//                                 _currentSettings['location'] =
//                                     'Current Location',
//                           );
//                           Navigator.pop(context);
//                         },
//                       ),
//                       const Divider(height: 30),
//                       TextField(
//                         controller: controller,
//                         decoration: InputDecoration(
//                           labelText: 'Manual Location',
//                           labelStyle: TextStyle(color: secondaryColor),
//                           prefixIcon: Icon(
//                             Icons.edit_location,
//                             color: primaryColor,
//                           ),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(
//                               color: primaryColor.withOpacity(0.3),
//                             ),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide(color: primaryColor),
//                           ),
//                         ),
//                         onChanged: (value) => manualLocation = value,
//                       ),
//                       const SizedBox(height: 20),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           TextButton(
//                             onPressed: () => Navigator.pop(context),
//                             child: Text(
//                               'CANCEL',
//                               style: TextStyle(color: secondaryColor),
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           ElevatedButton(
//                             style: ElevatedButton.styleFrom(
//                               backgroundColor: primaryColor,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(12),
//                               ),
//                               padding: const EdgeInsets.symmetric(
//                                 horizontal: 24,
//                                 vertical: 12,
//                               ),
//                             ),
//                             onPressed: () {
//                               setState(
//                                 () =>
//                                     _currentSettings['location'] =
//                                         manualLocation,
//                               );
//                               Navigator.pop(context);
//                             },
//                             child: Text(
//                               'SAVE',
//                               style: TextStyle(color: onPrimaryColor),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//     );
//   }

//   Widget _buildCalculationCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: primaryColor.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(Icons.calculate, color: primaryColor),
//         ),
//         title: Text(
//           'Calculation Method',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: secondaryColor,
//           ),
//         ),
//         subtitle: Text(
//           _getMethodName(_currentSettings['calculationMethod']),
//           style: TextStyle(color: primaryColor),
//         ),
//         trailing: Icon(Icons.chevron_right, color: primaryColor),
//         onTap: _showMethodDialog,
//       ),
//     );
//   }

//   Widget _buildMadhhabCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: primaryColor.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(Icons.account_balance, color: primaryColor),
//         ),
//         title: Text(
//           'Fiqh Method (Madhhab)',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: secondaryColor,
//           ),
//         ),
//         subtitle: Text(
//           _getMadhhabName(_currentSettings['madhhab']),
//           style: TextStyle(color: primaryColor),
//         ),
//         trailing: Icon(Icons.chevron_right, color: primaryColor),
//         onTap: _showMadhhabDialog,
//       ),
//     );
//   }

//   void _showMethodDialog() {
//     showDialog(
//       context: context,
//       builder:
//           (context) => Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: primaryColor,
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.calculate, color: onPrimaryColor),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Calculation Method',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: onPrimaryColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   child: SizedBox(
//                     width: double.maxFinite,
//                     child: ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: _calculationMethods.length,
//                       itemBuilder: (context, index) {
//                         final method = _calculationMethods[index];
//                         return RadioListTile<int>(
//                           title: Text('${method['name']}'),
//                           subtitle: Text('${method['description']}'),
//                           value: method['value'],
//                           groupValue: _currentSettings['calculationMethod'],
//                           activeColor: primaryColor,
//                           onChanged: (value) {
//                             setState(
//                               () =>
//                                   _currentSettings['calculationMethod'] =
//                                       value!,
//                             );
//                             Navigator.pop(context);
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//     );
//   }

//   void _showMadhhabDialog() {
//     showDialog(
//       context: context,
//       builder:
//           (context) => Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: primaryColor,
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.account_balance, color: onPrimaryColor),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Select Madhhab',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: onPrimaryColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   child: SizedBox(
//                     width: double.maxFinite,
//                     child: ListView.builder(
//                       shrinkWrap: true,
//                       itemCount: _madhhabMethods.length,
//                       itemBuilder: (context, index) {
//                         final method = _madhhabMethods[index];
//                         return RadioListTile<int>(
//                           title: Text(method['name']),
//                           value: method['value'],
//                           groupValue: _currentSettings['madhhab'],
//                           activeColor: primaryColor,
//                           onChanged: (value) {
//                             setState(
//                               () => _currentSettings['madhhab'] = value!,
//                             );
//                             Navigator.pop(context);
//                           },
//                         );
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//     );
//   }

//   Widget _buildNotificationsCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: Column(
//         children: [
//           SwitchListTile(
//             contentPadding: const EdgeInsets.symmetric(horizontal: 16),
//             title: Text(
//               'Enable Notifications',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: secondaryColor,
//               ),
//             ),
//             value: _currentSettings['notifications'],
//             secondary: Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: primaryColor.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(Icons.notifications, color: primaryColor),
//             ),
//             activeColor: primaryColor,
//             onChanged:
//                 (value) =>
//                     setState(() => _currentSettings['notifications'] = value),
//           ),
//           ListTile(
//             contentPadding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
//             leading: Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: primaryColor.withOpacity(0.1),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(Icons.timer, color: primaryColor),
//             ),
//             title: Text(
//               'Notification Offset',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//                 color: secondaryColor,
//               ),
//             ),
//             subtitle: Text(
//               '${_currentSettings['notificationOffset']} minutes before prayer',
//               style: TextStyle(color: primaryColor),
//             ),
//             onTap: _showOffsetDialog,
//           ),
//         ],
//       ),
//     );
//   }

//   void _showOffsetDialog() {
//     showDialog(
//       context: context,
//       builder:
//           (context) => Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: primaryColor,
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.timer, color: onPrimaryColor),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Notification Timing',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: onPrimaryColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         'Minutes before prayer time:',
//                         style: TextStyle(fontSize: 16, color: secondaryColor),
//                       ),
//                       const SizedBox(height: 16),
//                       Slider(
//                         value:
//                             _currentSettings['notificationOffset'].toDouble(),
//                         min: 5,
//                         max: 60,
//                         divisions: 11,
//                         label: '${_currentSettings['notificationOffset']}',
//                         activeColor: primaryColor,
//                         inactiveColor: primaryColor.withOpacity(0.2),
//                         onChanged: (value) {
//                           setState(() {
//                             _currentSettings['notificationOffset'] =
//                                 value.round();
//                           });
//                         },
//                       ),
//                       const SizedBox(height: 24),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: primaryColor,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                           ),
//                           onPressed: () => Navigator.pop(context),
//                           child: Text(
//                             'SAVE SETTING',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: onPrimaryColor,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//     );
//   }

//   Widget _buildAppearanceCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: primaryColor.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(Icons.text_fields, color: primaryColor),
//         ),
//         title: Text(
//           'Text Scaling',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: secondaryColor,
//           ),
//         ),
//         subtitle: Text(
//           '${(_currentSettings['textScale'] * 100).round()}%',
//           style: TextStyle(color: primaryColor),
//         ),
//         trailing: Icon(Icons.chevron_right, color: primaryColor),
//         onTap: _showTextScaleDialog,
//       ),
//     );
//   }

//   void _showTextScaleDialog() {
//     showDialog(
//       context: context,
//       builder:
//           (context) => Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: primaryColor,
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.text_fields, color: onPrimaryColor),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Text Scaling',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: onPrimaryColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Slider(
//                         value: _currentSettings['textScale'],
//                         min: 0.8,
//                         max: 1.5,
//                         divisions: 7,
//                         label:
//                             '${(_currentSettings['textScale'] * 100).round()}%',
//                         activeColor: primaryColor,
//                         inactiveColor: primaryColor.withOpacity(0.2),
//                         onChanged: (value) {
//                           setState(() => _currentSettings['textScale'] = value);
//                         },
//                       ),
//                       const SizedBox(height: 24),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: primaryColor,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                           ),
//                           onPressed: () => Navigator.pop(context),
//                           child: Text(
//                             'SAVE SETTING',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: onPrimaryColor,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//     );
//   }

//   Widget _buildAdvancedCard() {
//     return Card(
//       elevation: 2,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//       child: ListTile(
//         leading: Container(
//           padding: const EdgeInsets.all(10),
//           decoration: BoxDecoration(
//             color: primaryColor.withOpacity(0.1),
//             shape: BoxShape.circle,
//           ),
//           child: Icon(Icons.edit, color: primaryColor),
//         ),
//         title: Text(
//           'Manual Time Adjustments',
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.w500,
//             color: secondaryColor,
//           ),
//         ),
//         subtitle: Text(
//           'Coming soon',
//           style: TextStyle(color: primaryColor.withOpacity(0.7)),
//         ),
//         trailing: Icon(Icons.chevron_right, color: primaryColor),
//         onTap: _showManualCorrectionsDialog,
//       ),
//     );
//   }

//   void _showManualCorrectionsDialog() {
//     showDialog(
//       context: context,
//       builder:
//           (context) => Dialog(
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(20),
//             ),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 Container(
//                   padding: const EdgeInsets.all(20),
//                   decoration: BoxDecoration(
//                     color: primaryColor,
//                     borderRadius: const BorderRadius.only(
//                       topLeft: Radius.circular(20),
//                       topRight: Radius.circular(20),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.edit, color: onPrimaryColor),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Manual Adjustments',
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.w600,
//                           color: onPrimaryColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.all(20),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       Text(
//                         'This feature is under development and will be available in the next update',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           fontSize: 16,
//                           color: secondaryColor,
//                           height: 1.5,
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       SizedBox(
//                         width: double.infinity,
//                         child: ElevatedButton(
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: primaryColor,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             padding: const EdgeInsets.symmetric(vertical: 14),
//                           ),
//                           onPressed: () => Navigator.pop(context),
//                           child: Text(
//                             'UNDERSTOOD',
//                             style: TextStyle(
//                               fontSize: 16,
//                               fontWeight: FontWeight.w600,
//                               color: onPrimaryColor,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzData;

// Color Scheme Constants
const Color primaryColor = Color(0xFF2D3250);
const Color secondaryColor = Color(0xFF5B5F7F);
const Color surfaceColor = Color(0xFFF8F9FA);
const Color onPrimaryColor = Colors.white;
const Color highlightColor = Color(0xFF7077A1);

class PrayerTimesScreen extends StatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  State<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends State<PrayerTimesScreen> {
  late Box _settingsBox;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  Map<String, dynamic> _appSettings = {
    'calculationMethod': 2,
    'madhhab': 0, // Added madhhab setting
    'location': 'Current Location',
    'notifications': true,
    'notificationOffset': 10,
    'textScale': 1.0,
  };
  late Box _prayerBox;
  final Map<String, Map<String, String>> _prayerTimesByDate = {};
  final Map<String, String> _hijriDates = {};
  bool _isLoading = false;
  String _errorMessage = '';
  String _locationName = 'Loading location...';
  Position? _currentPosition;
  bool _usingCachedData = false;
  final List<DateTime> _dateRange = [];
  DateTime _selectedDate = DateTime.now();
  late PageController _pageController;
  final _dateFormatter = DateFormat('yyyy-MM-dd');
  final _apiDateFormatter = DateFormat('dd-MM-yyyy');
  String? _nextPrayer;
  Timer? _nextPrayerTimer;

  @override
  void initState() {
    super.initState();
    tzData.initializeTimeZones();
    _initializeDates();
    _initializeHive();
    _initializeSettings();
    _initializeNotifications();
    _setupNextPrayerTimer();
  }

  void _setupNextPrayerTimer() {
    _nextPrayerTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _determineNextPrayer();
    });
  }

  Future<void> _initializeSettings() async {
    if (!Hive.isBoxOpen('settings')) {
      await Hive.openBox('settings');
    }
    _settingsBox = Hive.box('settings');
    _loadSettings();
  }

  void _loadSettings() {
    final savedSettings = _settingsBox.get(
      'settings',
      defaultValue: _appSettings,
    );
    setState(() {
      _appSettings = Map<String, dynamic>.from(savedSettings);
      // Ensure all settings exist
      _appSettings['madhhab'] ??= 0;
      _appSettings['notificationOffset'] ??= 10;
      _appSettings['textScale'] ??= 1.0;
    });
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('app_icon');
    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await _notificationsPlugin.initialize(initializationSettings);
  }

  void _initializeDates() {
    final today = DateTime.now();
    final todayMidnight = DateTime(today.year, today.month, today.day);
    _dateRange.addAll([
      todayMidnight.subtract(const Duration(days: 2)),
      todayMidnight.subtract(const Duration(days: 1)),
      todayMidnight,
      todayMidnight.add(const Duration(days: 1)),
      todayMidnight.add(const Duration(days: 2)),
    ]);
    _pageController = PageController(initialPage: 2);
    _selectedDate = _dateRange[2];
  }

  Future<void> _initializeHive() async {
    if (!Hive.isBoxOpen('prayerCache')) {
      await Hive.openBox('prayerCache');
    }
    _prayerBox = Hive.box('prayerCache');
    _loadCachedData();
    _getPrayerTimes();
  }

  void _loadCachedData() {
    for (final date in _dateRange) {
      final dateKey = _dateFormatter.format(date);
      final cachedData = _prayerBox.get(dateKey);
      if (cachedData != null) {
        setState(() {
          _prayerTimesByDate[dateKey] = Map<String, String>.from(
            cachedData['times'],
          );
          _hijriDates[dateKey] = cachedData['hijri'] ?? '';
          _locationName = cachedData['location'] ?? _locationName;
          _usingCachedData = true;
        });
      }
    }
  }

  Future<void> _getPrayerTimes() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _usingCachedData = false;
    });

    try {
      final position = await _getPosition();
      await _updateLocationName(position);

      // Build API URL with settings
      final apiUrl = Uri.parse(
        'https://api.aladhan.com/v1/calendar?latitude=${position.latitude}'
        '&longitude=${position.longitude}'
        '&method=${_appSettings['calculationMethod']}'
        '&school=${_appSettings['madhhab']}' // Add madhhab to API call
        '&start=${_formatAPIDate(_dateRange.first)}'
        '&end=${_formatAPIDate(_dateRange.last)}',
      );

      final response = await http.get(apiUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _processPrayerTimes(data);
        _cacheData(data);
        _determineNextPrayer();
        _scheduleNotifications();
      } else {
        throw Exception('Failed to load prayer times: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _errorMessage = _getErrorMessage(e));
      if (_prayerTimesByDate.isEmpty) _loadCachedData();
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _formatAPIDate(DateTime date) => _apiDateFormatter.format(date);

  void _processPrayerTimes(Map<String, dynamic> data) {
    final days = data['data'] as List;
    for (final day in days) {
      try {
        final dateStr = day['date']['gregorian']['date'];
        final parsedDate = _apiDateFormatter.parse(dateStr);
        final dateKey = _dateFormatter.format(parsedDate);

        final timings = Map<String, String>.from(day['timings']);
        final cleanedTimings = {
          'Fajr': timings['Fajr']?.split(' ').first ?? '',
          'Sunrise': timings['Sunrise']?.split(' ').first ?? '',
          'Dhuhr': timings['Dhuhr']?.split(' ').first ?? '',
          'Asr': timings['Asr']?.split(' ').first ?? '',
          'Maghrib': timings['Maghrib']?.split(' ').first ?? '',
          'Isha': timings['Isha']?.split(' ').first ?? '',
        };

        final hijriDate = day['date']['hijri']['date'];
        final hijriDesignation =
            day['date']['hijri']['designation']['abbreviated'];
        final hijriDateStr = '$hijriDate $hijriDesignation';

        setState(() {
          _prayerTimesByDate[dateKey] = cleanedTimings;
          _hijriDates[dateKey] = hijriDateStr;
        });
      } catch (e) {
        print('Error processing date: $e');
      }
    }
  }

  void _cacheData(Map<String, dynamic> data) {
    final days = data['data'] as List;
    for (final day in days) {
      try {
        final dateStr = day['date']['gregorian']['date'];
        final parsedDate = _apiDateFormatter.parse(dateStr);
        final dateKey = _dateFormatter.format(parsedDate);

        _prayerBox.put(dateKey, {
          'times': _prayerTimesByDate[dateKey],
          'hijri': _hijriDates[dateKey],
          'location': _locationName,
        });
      } catch (e) {
        print('Error caching data: $e');
      }
    }
  }

  void _determineNextPrayer() {
    final now = DateTime.now();
    final todayKey = _dateFormatter.format(now);
    final times = _prayerTimesByDate[todayKey];
    if (times == null) return;

    final prayerOrder = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    for (final prayer in prayerOrder) {
      final timeStr = times[prayer];
      if (timeStr == null) continue;
      try {
        final time = DateFormat('HH:mm').parse(timeStr);
        final prayerTime = DateTime(
          now.year,
          now.month,
          now.day,
          time.hour,
          time.minute,
        );
        if (now.isBefore(prayerTime)) {
          setState(() => _nextPrayer = prayer);
          return;
        }
      } catch (e) {
        print('Error parsing prayer time: $e');
      }
    }
    setState(() => _nextPrayer = null);
  }

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) throw Exception('Location services are disabled');

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.whileInUse &&
          permission != LocationPermission.always) {
        throw Exception('Location permissions denied');
      }
    }

    try {
      _currentPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      return _currentPosition!;
    } catch (e) {
      throw Exception('Error getting position: ${e.toString()}');
    }
  }

  Future<void> _updateLocationName(Position position) async {
    try {
      final places = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = places.first;
      setState(() {
        _locationName = [
          if (place.subLocality != null) place.subLocality,
          if (place.locality != null) place.locality,
          if (place.administrativeArea != null) place.administrativeArea,
        ].where((part) => part?.isNotEmpty ?? false).join(', ');
      });
    } catch (e) {
      setState(() => _locationName = 'Current Location');
    }
  }

  void _navigateToSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => SettingsScreen(
              settings: _appSettings,
              onSettingsChanged: (newSettings) {
                setState(() {
                  _appSettings = newSettings;
                  _settingsBox.put('settings', newSettings);
                  _getPrayerTimes(); // Refresh with new settings
                });
              },
            ),
      ),
    );
  }

  // Future<void> _scheduleNotifications() async {
  //   if (!(_appSettings['notifications'] == true)) return;
  //   await _notificationsPlugin.cancelAll();

  //   final int offsetMinutes = _appSettings['notificationOffset'] ?? 10;

  //   try {
  //     final now = tz.TZDateTime.now(tz.local);

  //     for (final entry in _prayerTimesByDate.entries) {
  //       final date = _dateFormatter.parse(entry.key);
  //       final times = entry.value;

  //       for (final prayerEntry in times.entries) {
  //         final timeParts = prayerEntry.value.split(':');
  //         if (timeParts.length < 2) continue;

  //         final hour = int.tryParse(timeParts[0]);
  //         final minutePart = timeParts[1].contains(' ')
  //             ? timeParts[1].split(' ')[0]
  //             : timeParts[1];
  //         final minute = int.tryParse(minutePart);

  //         if (hour == null || minute == null) continue;

  //         final prayerTime = tz.TZDateTime(
  //           tz.local,
  //           date.year,
  //           date.month,
  //           date.day,
  //           hour,
  //           minute,
  //         );

  //         final scheduledTime = prayerTime.subtract(Duration(minutes: offsetMinutes));

  //         // Skip past notifications
  //         if (scheduledTime.isBefore(now)) continue;

  //         await _notificationsPlugin.zonedSchedule(
  //           prayerEntry.key.hashCode + date.hashCode,
  //           'Prayer Time Reminder',
  //           '${prayerEntry.key} prayer in $offsetMinutes minutes',
  //           scheduledTime,
  //           const NotificationDetails(
  //             android: AndroidNotificationDetails(
  //               'prayer_channel',
  //               'Prayer Times',
  //               importance: Importance.high,
  //               priority: Priority.high,
  //             ),
  //           ),
  //           androidAllowWhileIdle: true,
  //           uiLocalNotificationDateInterpretation:
  //               UILocalNotificationDateInterpretation.absoluteTime,
  //           matchDateTimeComponents: DateTimeComponents.time,
  //         );
  //       }
  //     }
  //   } catch (e) {
  //     print('Notification scheduling error: $e');
  //   }
  // }

  Future<void> _scheduleNotifications() async {
    // guard + clear previous schedules
    if (!(_appSettings['notifications'] == true)) return;
    await _notificationsPlugin.cancelAll();

    final int offsetMinutes = _appSettings['notificationOffset'] ?? 0;

    try {
      for (final entry in _prayerTimesByDate.entries) {
        final DateTime date = _dateFormatter.parse(entry.key);
        final times = entry.value; // Map<String, String>

        for (final prayerEntry in times.entries) {
          // Expecting values like "05:30 AM" or "17:10"
          final parts = prayerEntry.value.split(':');
          if (parts.length < 2) continue;

          final int? hour = int.tryParse(parts[0]);
          final String minutePart = parts[1].split(' ').first;
          final int? minute = int.tryParse(minutePart);
          if (hour == null || minute == null) continue;

          final tz.TZDateTime scheduledTime = tz.TZDateTime(
            tz.local,
            date.year,
            date.month,
            date.day,
            hour,
            minute,
          ).subtract(Duration(minutes: offsetMinutes));

          // skip past times
          if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) continue;

          final int id =
              prayerEntry.key.hashCode ^ date.hashCode; // stable unique id

          await _notificationsPlugin.zonedSchedule(
            id,
            'Prayer Time Reminder',
            '${prayerEntry.key} prayer in $offsetMinutes minutes',
            scheduledTime,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'prayer_channel',
                'Prayer Times',
                channelDescription: 'Reminders for upcoming prayers',
                importance: Importance.high,
                priority: Priority.high,
              ),
            ),
            // NEW API (v16+/v17): use schedule mode instead of deprecated androidAllowWhileIdle
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            // uiLocalNotificationDateInterpretation:
            //     UILocalNotificationDateInterpretation.absoluteTime,
            // one-time schedule; omit matchDateTimeComponents unless you want repeating
            payload: 'prayer:${prayerEntry.key}',
          );
        }
      }
    } catch (e) {
      // never crash the UI due to scheduling
      // ignore: avoid_print
      print('Notification scheduling error: $e');
    }
  }

  String _getErrorMessage(dynamic error) =>
      error.toString().replaceAll('Exception: ', '');

  String _formatTime(String time) {
    try {
      return DateFormat('h:mm a').format(DateFormat('HH:mm').parse(time));
    } catch (e) {
      return time;
    }
  }

  @override
  void dispose() {
    _nextPrayerTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: onPrimaryColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        backgroundColor: primaryColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Prayer Times',
              style: TextStyle(color: onPrimaryColor, fontSize: 20),
            ),
            Text(
              _locationName,
              style: TextStyle(
                color: onPrimaryColor.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: onPrimaryColor),
            onPressed: () => _navigateToSettings(context),
          ),
          IconButton(
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: onPrimaryColor,
                      ),
                    )
                    : const Icon(Icons.refresh, color: onPrimaryColor),
            onPressed: _getPrayerTimes,
          ),
        ],
      ),
      body: _buildBody(),
      backgroundColor: surfaceColor,
    );
  }

  Widget _buildBody() {
    if (_errorMessage.isNotEmpty && _prayerTimesByDate.isEmpty) {
      return _buildErrorWidget();
    }

    return Column(
      children: [
        if (_usingCachedData) _buildCacheNotice(),
        _buildDateSelector(),
        Expanded(child: _buildMainContent()),
      ],
    );
  }

  Widget _buildCacheNotice() => Container(
    padding: const EdgeInsets.symmetric(vertical: 8),
    color: highlightColor.withOpacity(0.1),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.info, size: 18, color: highlightColor),
        const SizedBox(width: 8),
        Text('Showing cached data', style: TextStyle(color: highlightColor)),
      ],
    ),
  );

  Widget _buildDateSelector() => SizedBox(
    height: 80,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: _dateRange.length,
      itemBuilder: (context, index) => _buildDateItem(_dateRange[index], index),
    ),
  );

  Widget _buildDateItem(DateTime date, int index) {
    final isSelected = _dateRange[index] == _selectedDate;
    return GestureDetector(
      onTap:
          () => _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          ),
      child: Container(
        margin: const EdgeInsets.all(7),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? secondaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected
                    ? primaryColor
                    : const Color.fromARGB(255, 224, 224, 224),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('EEE').format(date),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? onPrimaryColor : primaryColor,
              ),
            ),
            Text(
              DateFormat('d').format(date),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? onPrimaryColor : primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent() => PageView.builder(
    controller: _pageController,
    itemCount: _dateRange.length,
    onPageChanged: (index) => setState(() => _selectedDate = _dateRange[index]),
    itemBuilder: (context, index) => _buildDailyPrayerTimes(_dateRange[index]),
  );

  Widget _buildDailyPrayerTimes(DateTime date) {
    final dateKey = _dateFormatter.format(date);
    final times = _prayerTimesByDate[dateKey];
    final isToday = dateKey == _dateFormatter.format(DateTime.now());

    return RefreshIndicator(
      onRefresh: _getPrayerTimes,
      child:
          times == null
              ? _buildDateShimmer()
              : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildDateHeader(date, isToday),
                  ...times.entries.map(
                    (entry) => _PrayerTimeItem(
                      prayer: entry.key,
                      time: _formatTime(entry.value),
                      isNext: isToday && entry.key == _nextPrayer,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildDateHeader(DateTime date, bool isToday) {
    final dateKey = _dateFormatter.format(date);
    final hijriDate = _hijriDates[dateKey] ?? '';

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? highlightColor.withOpacity(0.1) : onPrimaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              DateFormat('EEEE, MMMM d').format(date),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hijriDate,
              style: TextStyle(fontSize: 14, color: secondaryColor),
            ),
            const SizedBox(height: 8),
            Text(
              _locationName,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget() => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: highlightColor),
          const SizedBox(height: 16),
          Text(
            'Error: $_errorMessage',
            style: TextStyle(color: highlightColor, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _getPrayerTimes,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildDateShimmer() => Shimmer.fromColors(
    baseColor: Colors.grey[300]!,
    highlightColor: Colors.grey[100]!,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: List.generate(
          6,
          (index) => Container(
            height: 60,
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    ),
  );
}

class _PrayerTimeItem extends StatelessWidget {
  final String prayer;
  final String time;
  final bool isNext;

  const _PrayerTimeItem({
    required this.prayer,
    required this.time,
    this.isNext = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isNext ? highlightColor : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: highlightColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: _getPrayerIcon(),
        ),
        title: Text(
          prayer,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: primaryColor,
          ),
        ),
        trailing: Text(
          time,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isNext ? secondaryColor : highlightColor,
          ),
        ),
        tileColor:
            isNext ? highlightColor.withOpacity(0.05) : Colors.transparent,
      ),
    );
  }

  Icon _getPrayerIcon() {
    switch (prayer) {
      case 'Fajr':
        return const Icon(Icons.nightlight_round, color: primaryColor);
      case 'Sunrise':
        return const Icon(Icons.wb_sunny, color: Color(0xFFF6B17A));
      case 'Dhuhr':
        return const Icon(Icons.brightness_5, color: Color(0xFFF6B17A));
      case 'Asr':
        return const Icon(Icons.brightness_medium, color: primaryColor);
      case 'Maghrib':
        return const Icon(Icons.brightness_4, color: primaryColor);
      case 'Isha':
        return const Icon(Icons.nightlight_round, color: primaryColor);
      default:
        return const Icon(Icons.access_time, color: primaryColor);
    }
  }
}

class SettingsScreen extends StatefulWidget {
  final Map<String, dynamic> settings;
  final Function(Map<String, dynamic>) onSettingsChanged;

  const SettingsScreen({
    required this.settings,
    required this.onSettingsChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late Map<String, dynamic> _currentSettings;
  final List<Map<String, dynamic>> _calculationMethods = [
    {'value': 1, 'name': 'MWL', 'description': 'Muslim World League'},
    {
      'value': 2,
      'name': 'ISNA',
      'description': 'Islamic Society of North America',
    },
    {
      'value': 3,
      'name': 'Egyptian',
      'description': 'Egyptian General Authority',
    },
    {
      'value': 4,
      'name': 'Umm Al-Qura',
      'description': 'Umm Al-Qura University, Makkah',
    },
    {
      'value': 5,
      'name': 'Islamic Sciences',
      'description': 'University of Islamic Sciences, Karachi',
    },
  ];

  final List<Map<String, dynamic>> _madhhabMethods = [
    {'value': 0, 'name': 'Shafi/Hanbali/Maliki'},
    {'value': 1, 'name': 'Hanafi'},
  ];

  @override
  void initState() {
    super.initState();
    _currentSettings = Map.from(widget.settings);
    // Initialize settings if not present
    _currentSettings['madhhab'] ??= 0;
    _currentSettings['notificationOffset'] ??= 10;
    _currentSettings['textScale'] ??= 1.0;
  }

  String _getMethodName(int method) {
    return _calculationMethods.firstWhere(
      (m) => m['value'] == method,
      orElse: () => {'name': 'Unknown'},
    )['name'];
  }

  String _getMadhhabName(int method) {
    return _madhhabMethods.firstWhere(
      (m) => m['value'] == method,
      orElse: () => {'name': 'Unknown'},
    )['name'];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, Color(0xFF4A548C)],
            ),
          ),
        ),
        foregroundColor: onPrimaryColor,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0F5FF), Color(0xFFE6EDFA), Color(0xFFDDE5F5)],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            _buildSectionHeader('LOCATION SETTINGS', Icons.location_on),
            _buildLocationCard(),

            const SizedBox(height: 24),
            _buildSectionHeader('PRAYER CALCULATION', Icons.calculate),
            _buildCalculationCard(),
            const SizedBox(height: 16),
            _buildMadhhabCard(),

            const SizedBox(height: 24),
            _buildSectionHeader('NOTIFICATIONS', Icons.notifications),
            _buildNotificationsCard(),

            const SizedBox(height: 24),
            _buildSectionHeader('APPEARANCE', Icons.palette),
            _buildAppearanceCard(),

            const SizedBox(height: 24),
            _buildSectionHeader('ADVANCED', Icons.tune),
            _buildAdvancedCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: onPrimaryColor,
        child: const Icon(Icons.save),
        onPressed: () => widget.onSettingsChanged(_currentSettings),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 22),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.location_on, color: primaryColor),
        ),
        title: Text(
          'Location',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
          ),
        ),
        subtitle: Text(
          _currentSettings['location'],
          style: TextStyle(color: primaryColor),
        ),
        trailing: Icon(Icons.chevron_right, color: primaryColor),
        onTap: _showLocationDialog,
      ),
    );
  }

  void _showLocationDialog() {
    String manualLocation = _currentSettings['location'];
    final controller = TextEditingController(text: manualLocation);

    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: onPrimaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'Change Location',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: onPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.gps_fixed, color: primaryColor),
                        title: Text('Use Current Location'),
                        onTap: () {
                          setState(
                            () =>
                                _currentSettings['location'] =
                                    'Current Location',
                          );
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(height: 30),
                      TextField(
                        controller: controller,
                        decoration: InputDecoration(
                          labelText: 'Manual Location',
                          labelStyle: TextStyle(color: secondaryColor),
                          prefixIcon: Icon(
                            Icons.edit_location,
                            color: primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: primaryColor.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor),
                          ),
                        ),
                        onChanged: (value) => manualLocation = value,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'CANCEL',
                              style: TextStyle(color: secondaryColor),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            onPressed: () {
                              setState(
                                () =>
                                    _currentSettings['location'] =
                                        manualLocation,
                              );
                              Navigator.pop(context);
                            },
                            child: Text(
                              'SAVE',
                              style: TextStyle(color: onPrimaryColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildCalculationCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.calculate, color: primaryColor),
        ),
        title: Text(
          'Calculation Method',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
          ),
        ),
        subtitle: Text(
          _getMethodName(_currentSettings['calculationMethod']),
          style: TextStyle(color: primaryColor),
        ),
        trailing: Icon(Icons.chevron_right, color: primaryColor),
        onTap: _showMethodDialog,
      ),
    );
  }

  Widget _buildMadhhabCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.account_balance, color: primaryColor),
        ),
        title: Text(
          'Fiqh Method (Madhhab)',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
          ),
        ),
        subtitle: Text(
          _getMadhhabName(_currentSettings['madhhab']),
          style: TextStyle(color: primaryColor),
        ),
        trailing: Icon(Icons.chevron_right, color: primaryColor),
        onTap: _showMadhhabDialog,
      ),
    );
  }

  void _showMethodDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calculate, color: onPrimaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'Calculation Method',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: onPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _calculationMethods.length,
                      itemBuilder: (context, index) {
                        final method = _calculationMethods[index];
                        return RadioListTile<int>(
                          title: Text('${method['name']}'),
                          subtitle: Text('${method['description']}'),
                          value: method['value'],
                          groupValue: _currentSettings['calculationMethod'],
                          activeColor: primaryColor,
                          onChanged: (value) {
                            setState(
                              () =>
                                  _currentSettings['calculationMethod'] =
                                      value!,
                            );
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showMadhhabDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance, color: onPrimaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'Select Madhhab',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: onPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: SizedBox(
                    width: double.maxFinite,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _madhhabMethods.length,
                      itemBuilder: (context, index) {
                        final method = _madhhabMethods[index];
                        return RadioListTile<int>(
                          title: Text(method['name']),
                          value: method['value'],
                          groupValue: _currentSettings['madhhab'],
                          activeColor: primaryColor,
                          onChanged: (value) {
                            setState(
                              () => _currentSettings['madhhab'] = value!,
                            );
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildNotificationsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              'Enable Notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
              ),
            ),
            value: _currentSettings['notifications'],
            secondary: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.notifications, color: primaryColor),
            ),
            activeColor: primaryColor,
            onChanged:
                (value) =>
                    setState(() => _currentSettings['notifications'] = value),
          ),
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.timer, color: primaryColor),
            ),
            title: Text(
              'Notification Offset',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: secondaryColor,
              ),
            ),
            subtitle: Text(
              '${_currentSettings['notificationOffset']} minutes before prayer',
              style: TextStyle(color: primaryColor),
            ),
            onTap: _showOffsetDialog,
          ),
        ],
      ),
    );
  }

  void _showOffsetDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer, color: onPrimaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'Notification Timing',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: onPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Minutes before prayer time:',
                        style: TextStyle(fontSize: 16, color: secondaryColor),
                      ),
                      const SizedBox(height: 16),
                      Slider(
                        value:
                            _currentSettings['notificationOffset'].toDouble(),
                        min: 5,
                        max: 60,
                        divisions: 11,
                        label: '${_currentSettings['notificationOffset']}',
                        activeColor: primaryColor,
                        inactiveColor: primaryColor.withOpacity(0.2),
                        onChanged: (value) {
                          setState(() {
                            _currentSettings['notificationOffset'] =
                                value.round();
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'SAVE SETTING',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: onPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildAppearanceCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.text_fields, color: primaryColor),
        ),
        title: Text(
          'Text Scaling',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
          ),
        ),
        subtitle: Text(
          '${(_currentSettings['textScale'] * 100).round()}%',
          style: TextStyle(color: primaryColor),
        ),
        trailing: Icon(Icons.chevron_right, color: primaryColor),
        onTap: _showTextScaleDialog,
      ),
    );
  }

  void _showTextScaleDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.text_fields, color: onPrimaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'Text Scaling',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: onPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Slider(
                        value: _currentSettings['textScale'],
                        min: 0.8,
                        max: 1.5,
                        divisions: 7,
                        label:
                            '${(_currentSettings['textScale'] * 100).round()}%',
                        activeColor: primaryColor,
                        inactiveColor: primaryColor.withOpacity(0.2),
                        onChanged: (value) {
                          setState(() => _currentSettings['textScale'] = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'SAVE SETTING',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: onPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildAdvancedCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.edit, color: primaryColor),
        ),
        title: Text(
          'Manual Time Adjustments',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: secondaryColor,
          ),
        ),
        subtitle: Text(
          'Coming soon',
          style: TextStyle(color: primaryColor.withOpacity(0.7)),
        ),
        trailing: Icon(Icons.chevron_right, color: primaryColor),
        onTap: _showManualCorrectionsDialog,
      ),
    );
  }

  void _showManualCorrectionsDialog() {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: onPrimaryColor),
                      const SizedBox(width: 12),
                      Text(
                        'Manual Adjustments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: onPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'This feature is under development and will be available in the next update',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: secondaryColor,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'UNDERSTOOD',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: onPrimaryColor,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}
