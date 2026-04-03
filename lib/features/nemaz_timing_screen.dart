import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('prayerCache');
  await Hive.openBox('locations');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prayer Times',
      theme: ThemeData(primarySwatch: Colors.blue, fontFamily: 'Poppins'),
      home: const PrayerTimes(),
    );
  }
}

class PrayerTimes extends StatefulWidget {
  const PrayerTimes({super.key});

  @override
  _PrayerTimesState createState() => _PrayerTimesState();
}

class _PrayerTimesState extends State<PrayerTimes> {
  late Box _prayerTimesBox;
  late Box _locationsBox;
  List<dynamic> _prayerTimes = [];
  bool _isLoading = false;
  String _errorMessage = '';
  DateTime _selectedDate = DateTime.now();
  final List<String> _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  List<Map<String, dynamic>> _locations = [];
  Map<String, dynamic>? _selectedLocation;
  bool _usingCurrentLocation = true;

  @override
  void initState() {
    super.initState();
    _initializeHiveBox();
  }

  Future<void> _initializeHiveBox() async {
    _prayerTimesBox = Hive.box('prayerCache');
    _locationsBox = Hive.box('locations');
    _loadSavedLocations();
    _getCurrentLocation();
  }

  void _loadSavedLocations() {
    _locations =
        _locationsBox.values.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      setState(() {
        _selectedLocation = {
          'name': 'Current Location',
          'lat': position.latitude,
          'lng': position.longitude,
          'isCurrent': true,
        };
        _usingCurrentLocation = true;
      });
      await _fetchPrayerTimes();
    } catch (e) {
      setState(() => _errorMessage = 'Location Error: ${e.toString()}');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _fetchPrayerTimes() async {
    if (_selectedLocation == null) {
      setState(() => _errorMessage = 'No location selected');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    final month = _selectedDate.month;
    final year = _selectedDate.year;
    final cacheKey =
        '${_selectedLocation!['lat']}-${_selectedLocation!['lng']}-$month-$year';

    try {
      if (_prayerTimesBox.containsKey(cacheKey)) {
        setState(() => _prayerTimes = _prayerTimesBox.get(cacheKey));
      } else {
        final response = await http.get(
          Uri.https('api.aladhan.com', '/v1/calendar/$year/$month', {
            'latitude': _selectedLocation!['lat'].toString(),
            'longitude': _selectedLocation!['lng'].toString(),
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body)['data'];
          _prayerTimesBox.put(cacheKey, data);
          setState(() => _prayerTimes = data);
        } else {
          throw 'Failed to load prayer times: ${response.statusCode}';
        }
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
    setState(() => _isLoading = false);
  }

  void _onMonthChanged(int? selectedMonth) {
    if (selectedMonth == null) return;
    setState(() {
      _selectedDate = DateTime(_selectedDate.year, selectedMonth + 1);
      _fetchPrayerTimes();
    });
  }

  void _onLocationChanged(Map<String, dynamic>? location) {
    if (location == null) {
      _getCurrentLocation();
    } else {
      setState(() {
        _selectedLocation = location;
        _usingCurrentLocation = location['isCurrent'] ?? false;
      });
      _fetchPrayerTimes();
    }
  }

  void _addNewLocation(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => LocationDialog(
            onSave: (location) {
              _locationsBox.add(location);
              _loadSavedLocations();
            },
          ),
    );
  }

  void _deleteLocation(int index) {
    final deletedLocation = _locations[index];
    _locationsBox.deleteAt(index);
    _loadSavedLocations();
    if (_selectedLocation != null &&
        _selectedLocation!['name'] == deletedLocation['name'] &&
        _selectedLocation!['lat'] == deletedLocation['lat'] &&
        _selectedLocation!['lng'] == deletedLocation['lng']) {
      _getCurrentLocation();
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildLocationDropdown(),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchPrayerTimes,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addNewLocation(context),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add_location),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildMainContent(),
      ),
    );
  }

  Widget _buildLocationDropdown() {
    final validSelectedLocation =
        _selectedLocation != null &&
                _locations.any(
                  (loc) =>
                      loc['name'] == _selectedLocation!['name'] &&
                      loc['lat'] == _selectedLocation!['lat'] &&
                      loc['lng'] == _selectedLocation!['lng'],
                )
            ? _selectedLocation
            : null;

    return DropdownButton<Map<String, dynamic>>(
      value: validSelectedLocation,
      items: [
        DropdownMenuItem(
          value: null,
          child: Row(
            children: const [
              Icon(Icons.my_location, color: Colors.white),
              SizedBox(width: 8),
              Text('Current Location', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
        ..._locations
            .map(
              (location) => DropdownMenuItem(
                value: location,
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      location['name'],
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        _deleteLocation(_locations.indexOf(location));
                        Navigator.of(context).pop();
                      },
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ],
      onChanged: _onLocationChanged,
      underline: const SizedBox(),
      icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
      dropdownColor: Colors.blue.shade700,
      hint: const Text(
        'Select Location',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Fetching Prayer Times...',
              style: TextStyle(color: Colors.blue.shade800, fontSize: 16),
            ),
          ],
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 16),
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _errorMessage = '';
                    _isLoading = true;
                  });
                  try {
                    if (_usingCurrentLocation) {
                      await _getCurrentLocation();
                    } else {
                      await _fetchPrayerTimes();
                    }
                  } catch (e) {
                    setState(() => _errorMessage = 'Error: ${e.toString()}');
                  }
                  setState(() => _isLoading = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Retry',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildMonthSelector(),
        Expanded(
          child:
              _prayerTimes.isEmpty
                  ? Center(
                    child: Text(
                      'No prayer times available\nSelect a location first',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.blue.shade800,
                        fontSize: 18,
                      ),
                    ),
                  )
                  : _buildPrayerTimesList(),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 236, 168, 11),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 106, 151, 188),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: DropdownButton<int>(
          value: _selectedDate.month - 1,
          items: List.generate(
            12,
            (index) => DropdownMenuItem<int>(
              value: index,
              child: Text(
                _months[index],
                selectionColor: Color.fromARGB(244, 97, 169, 168),
              ),
            ),
          ),
          onChanged: _onMonthChanged,
          isExpanded: true,
          underline: const SizedBox(),
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color.fromARGB(255, 124, 159, 189),
          ),
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _prayerTimes.length,
      itemBuilder: (context, index) {
        final day = _prayerTimes[index];
        final date = _parseDate(day['date']['gregorian']['date']);
        return _PrayerTimeCard(
          date: date,
          times: day['timings'],
          isToday: _isToday(date),
        );
      },
    );
  }

  DateTime _parseDate(String dateString) {
    try {
      return DateFormat('dd-MM-yyyy').parse(dateString);
    } catch (e) {
      // Fallback to ISO 8601 format if the above fails
      return DateTime.parse(dateString);
    }
  }
}

class LocationDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const LocationDialog({required this.onSave});

  @override
  _LocationDialogState createState() => _LocationDialogState();
}

class _LocationDialogState extends State<LocationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cityController = TextEditingController();
  double? _lat;
  double? _lng;
  bool _searching = false;
  String _searchError = '';

  Future<void> _searchLocation() async {
    setState(() {
      _searching = true;
      _searchError = '';
    });

    try {
      final response = await http.get(
        Uri.https('nominatim.openstreetmap.org', '/search', {
          'q': _cityController.text,
          'format': 'json',
          'limit': '1',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data.isNotEmpty) {
          setState(() {
            _lat = double.parse(data[0]['lat']);
            _lng = double.parse(data[0]['lon']);
          });
        } else {
          setState(() => _searchError = 'Location not found');
        }
      } else {
        setState(() => _searchError = 'Search failed: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _searchError = 'Error: ${e.toString()}');
    }
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Location'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'City Name',
                hintText: 'e.g., Kupwara, Kashmir',
              ),
              validator: (value) => value!.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            if (_searching)
              const CircularProgressIndicator()
            else if (_searchError.isNotEmpty)
              Text(_searchError, style: const TextStyle(color: Colors.red)),
            if (_lat != null && _lng != null)
              Text(
                'Found: ${_lat!.toStringAsFixed(4)}, ${_lng!.toStringAsFixed(4)}',
                style: const TextStyle(color: Colors.green),
              ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _searchLocation,
              child: const Text('Search Location'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate() &&
                _lat != null &&
                _lng != null) {
              widget.onSave({
                'name': _cityController.text,
                'lat': _lat!,
                'lng': _lng!,
                'isCurrent': false,
              });
              Navigator.pop(context);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please search for a valid location first.'),
                ),
              );
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _PrayerTimeCard extends StatelessWidget {
  final DateTime date;
  final Map<String, dynamic> times;
  final bool isToday;

  const _PrayerTimeCard({
    required this.date,
    required this.times,
    required this.isToday,
  });

  String _formatTime12Hour(String time) {
    final cleanTime = time.split(' ')[0];
    final dateTime = DateFormat('HH:mm').parse(cleanTime);
    return DateFormat.jm().format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      color: isToday ? Colors.blue.shade100 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        title: Text(
          DateFormat('dd MMM yyyy').format(date),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isToday ? Colors.blue.shade900 : Colors.black,
          ),
        ),
        children: [
          _PrayerTimeItem(name: 'Fajr', time: _formatTime12Hour(times['Fajr'])),
          _PrayerTimeItem(
            name: 'Sunrise',
            time: _formatTime12Hour(times['Sunrise']),
          ),
          _PrayerTimeItem(
            name: 'Dhuhr',
            time: _formatTime12Hour(times['Dhuhr']),
          ),
          _PrayerTimeItem(name: 'Asr', time: _formatTime12Hour(times['Asr'])),
          _PrayerTimeItem(
            name: 'Maghrib',
            time: _formatTime12Hour(times['Maghrib']),
          ),
          _PrayerTimeItem(name: 'Isha', time: _formatTime12Hour(times['Isha'])),
        ],
      ),
    );
  }
}

class _PrayerTimeItem extends StatelessWidget {
  final String name;
  final String time;

  const _PrayerTimeItem({required this.name, required this.time});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(name, style: const TextStyle(fontSize: 16)),
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
