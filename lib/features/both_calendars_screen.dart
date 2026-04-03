import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

class EnhancedCalendarScreen extends StatefulWidget {
  const EnhancedCalendarScreen({super.key});

  @override
  State<EnhancedCalendarScreen> createState() => _EnhancedCalendarScreenState();
}

class _EnhancedCalendarScreenState extends State<EnhancedCalendarScreen> {
  bool _showHijri = false;
  DateTime _focusedDay = DateTime.now();
  final Map<DateTime, List<String>> _events = {};

  // Urdu translations
  final Map<String, String> _urduMonths = {
    'Muharram': 'محرم',
    'Safar': 'صفر',
    'Rabi al-awwal': 'ربیع الاول',
    'Rabi al-thani': 'ربیع الثانی',
    'Jumada al-awwal': 'جمادی الاول',
    'Jumada al-thani': 'جمادی الثانی',
    'Rajab': 'رجب',
    'Sha\'ban': 'شعبان',
    'Ramadan': 'رمضان',
    'Shawwal': 'شوال',
    'Dhu al-Qi\'dah': 'ذوالقعدہ',
    'Dhu al-Hijjah': 'ذوالحجہ',
  };

  final List<String> _urduDays = [
    'اتوار',
    'پیر',
    'منگل',
    'بدھ',
    'جمعرات',
    'جمعہ',
    'ہفتہ',
  ];

  String _getFormattedDate(DateTime date) {
    try {
      if (_showHijri) {
        final hijri = HijriCalendar.fromDate(date);
        return '${hijri.hDay} ${_urduMonths[hijri.longMonthName]} ${hijri.hYear}ھ';
      }
      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return 'تاریخ لوڈ ہو رہی ہے...';
    }
  }

  Widget _buildDay(DateTime date, bool isToday, bool isSelected) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color:
            isToday
                ? Colors.green[300]
                : isSelected
                ? Colors.green[100]
                : null,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          _showHijri
              ? HijriCalendar.fromDate(date).hDay.toString()
              : date.day.toString(),
          style: TextStyle(
            color: isToday ? Colors.white : Colors.grey[800],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children:
          _urduDays
              .map(
                (day) => Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      day,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: const Color.fromARGB(255, 24, 10, 221),
                        fontFamily: 'NotoNastaliqUrdu',
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _showHijri ? 'ہجری کیلنڈر' : 'اسلامی کیلنڈر',
          style: const TextStyle(
            fontFamily: 'NotoNastaliqUrdu',
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.green[700],
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.green[50]!, Colors.white],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.green[700],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.calendar_month, color: Colors.white),
                    const SizedBox(width: 10),
                    Text(
                      _getFormattedDate(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontFamily: 'NotoNastaliqUrdu',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: SwitchListTile(
                  title: Text(
                    _showHijri ? 'ہجری دیکھیں' : 'Gregorian View',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontFamily: 'NotoNastaliqUrdu',
                    ),
                  ),
                  secondary: Icon(
                    _showHijri ? Icons.mosque : Icons.public,
                    color: Colors.green[700],
                  ),
                  value: _showHijri,
                  onChanged: (value) => setState(() => _showHijri = value),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildHeader(),
                      Expanded(
                        child: TableCalendar(
                          firstDay: DateTime(1900),
                          lastDay: DateTime(2100),
                          focusedDay: _focusedDay,
                          currentDay: DateTime.now(),
                          calendarFormat: CalendarFormat.month,
                          eventLoader: (date) => _events[date] ?? [],
                          onPageChanged:
                              (focusedDay) =>
                                  setState(() => _focusedDay = focusedDay),
                          calendarStyle: CalendarStyle(
                            todayDecoration: BoxDecoration(
                              color: Colors.green[300],
                              shape: BoxShape.circle,
                            ),
                            selectedDecoration: BoxDecoration(
                              color: Colors.green[700],
                              shape: BoxShape.circle,
                            ),
                            outsideDaysVisible: false,
                          ),
                          headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            titleTextStyle: TextStyle(
                              color: Colors.green[700],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            leftChevronIcon: Icon(
                              Icons.chevron_left,
                              color: Colors.green[700],
                            ),
                            rightChevronIcon: Icon(
                              Icons.chevron_right,
                              color: Colors.green[700],
                            ),
                          ),
                          calendarBuilders: CalendarBuilders(
                            defaultBuilder:
                                (context, date, events) => _buildDay(
                                  date,
                                  _isSameDay(date, DateTime.now()),
                                  false,
                                ),
                            selectedBuilder:
                                (context, date, events) => _buildDay(
                                  date,
                                  _isSameDay(date, DateTime.now()),
                                  true,
                                ),
                            todayBuilder:
                                (context, date, events) =>
                                    _buildDay(date, true, false),
                          ),
                        ),
                      ),
                      if (_showHijri)
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              Text(
                                'Hijri dates are based on crescent moon observation',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontStyle: FontStyle.italic,
                                  fontFamily: 'NotoNastaliqUrdu',
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
