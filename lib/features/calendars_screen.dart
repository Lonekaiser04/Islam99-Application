import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class HijriCalendarScreen extends StatefulWidget {
  const HijriCalendarScreen({super.key});

  @override
  State<HijriCalendarScreen> createState() => _HijriCalendarScreenState();
}

class _HijriCalendarScreenState extends State<HijriCalendarScreen> {
  DateTime _todayGregorian = DateTime.now();
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  Map<String, List<String>> _events = {};
  bool _isLoading = true;
  String _hijriDate = 'Loading...';

  @override
  void initState() {
    super.initState();
    _fetchHijriDate();
    _fetchEvents();
  }

  /// Fetch Hijri Date from API
  Future<void> _fetchHijriDate() async {
    final response = await http.get(
      Uri.parse(
        'http://api.aladhan.com/v1/gToH/${DateFormat('dd-MM-yyyy').format(_todayGregorian)}',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _hijriDate = data['data']['hijri']['date'];
      });
    } else {
      setState(() => _hijriDate = 'Failed to load Hijri date');
    }
  }

  /// Fetch Islamic Events
  Future<void> _fetchEvents() async {
    final response = await http.get(
      Uri.parse(
        'http://api.aladhan.com/v1/hijriCalendarByCity?city=Makkah&country=Saudi%20Arabia&method=2',
      ),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        _events = _parseEvents(data['data']);
        _isLoading = false;
      });
    } else {
      setState(() => _isLoading = false);
    }
  }

  /// Parse Events from API
  Map<String, List<String>> _parseEvents(List<dynamic> data) {
    Map<String, List<String>> events = {};
    for (var day in data) {
      String date = day['date']['gregorian']['date'];
      String hijriEvent = day['date']['hijri']['holidays'].join(", ");
      if (hijriEvent.isNotEmpty) {
        events[date] = [hijriEvent];
      }
    }
    return events;
  }

  /// Get Events for a Specific Day
  List<String> _getEventsForDay(DateTime day) {
    String formattedDate = DateFormat('dd-MM-yyyy').format(day);
    return _events[formattedDate] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hijri Calendar'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildCurrentDate(),
                    const SizedBox(height: 20),
                    _buildCalendar(),
                    const SizedBox(height: 20),
                    _buildImportantEvents(),
                    const SizedBox(height: 20),
                    _buildDateConverter(),
                  ],
                ),
              ),
    );
  }

  /// Display Current Date
  Widget _buildCurrentDate() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple, Colors.purple.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'Today\'s Date',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Hijri: $_hijriDate',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
          const SizedBox(height: 10),
          Text(
            'Gregorian: ${DateFormat('dd MMMM yyyy').format(_todayGregorian)}',
            style: const TextStyle(fontSize: 18, color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// Build Calendar Widget
  Widget _buildCalendar() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: TableCalendar(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: _calendarFormat,
          onFormatChanged: (format) {
            setState(() => _calendarFormat = format);
          },
          onPageChanged: (focusedDay) {
            setState(() => _focusedDay = focusedDay);
          },
          eventLoader: _getEventsForDay,
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Colors.deepPurple.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Colors.deepPurple,
              shape: BoxShape.circle,
            ),
            defaultTextStyle: TextStyle(
              color: Colors.black, // Ensure dates are visible
              fontSize: 16,
            ),
            weekendTextStyle: TextStyle(
              color: Colors.black, // Ensure weekend dates are visible
              fontSize: 16,
            ),
            outsideTextStyle: TextStyle(
              color: Colors.grey, // Style for dates outside the current month
              fontSize: 16,
            ),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleTextStyle: TextStyle(
              color: Colors.deepPurple,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            formatButtonTextStyle: TextStyle(
              color: Colors.deepPurple,
              fontSize: 14,
            ),
            formatButtonDecoration: BoxDecoration(
              border: Border.all(color: Colors.deepPurple),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) {
              final events = _getEventsForDay(day);
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.day.toString(),
                    style: TextStyle(
                      color: Colors.black, // Ensure dates are visible
                      fontSize: 16,
                    ),
                  ),
                  if (events.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.circle,
                        size: 8,
                        color: Colors.red,
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Display Islamic Events
  Widget _buildImportantEvents() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Important Events',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            ..._events.entries.map(
              (entry) => ListTile(
                title: Text(
                  entry.value.join(', '),
                  style: const TextStyle(fontSize: 16),
                ),
                subtitle: Text(
                  entry.key,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Date Converter
  Widget _buildDateConverter() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Date Converter',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Colors.deepPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Enter Gregorian Date (yyyy-MM-dd)',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) async {
                final date = DateTime.tryParse(value);
                if (date != null) {
                  final response = await http.get(
                    Uri.parse(
                      'http://api.aladhan.com/v1/gToH/${DateFormat('dd-MM-yyyy').format(date)}',
                    ),
                  );

                  if (response.statusCode == 200) {
                    final data = json.decode(response.body);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Hijri Date: ${data['data']['hijri']['date']}',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
