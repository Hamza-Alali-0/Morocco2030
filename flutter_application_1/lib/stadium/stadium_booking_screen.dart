import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/stadium/stadium_model.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/services.dart';

class StadiumBookingScreen extends StatefulWidget {
  final Stadium stadium;

  const StadiumBookingScreen({Key? key, required this.stadium})
    : super(key: key);

  @override
  State<StadiumBookingScreen> createState() => _StadiumBookingScreenState();
}

class _StadiumBookingScreenState extends State<StadiumBookingScreen> {
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);

  DateTime _selectedDate = DateTime.now();
  String? _selectedTimeSlot;
  Map<String, dynamic>? _selectedMatch;
  String? _selectedSeat;
  bool _isLoading = false;
  List<Map<String, dynamic>> _availableMatches = [];

  final _seats = List.generate(100, (index) => 'Seat ${index + 1}');
  final List<String> _bookedSeats = [];

  @override
  void initState() {
    super.initState();
    _fetchMatchesFromApi();
  }

  Future<void> _fetchMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final matchesSnapshot =
          await FirebaseFirestore.instance
              .collection('football')
              .where('date', isEqualTo: formattedDate)
              .where('stadiumId', isEqualTo: widget.stadium.id)
              .get();

      final matches =
          matchesSnapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'id': doc.id,
              'homeTeam': data['homeTeam'] ?? 'Unknown',
              'awayTeam': data['awayTeam'] ?? 'Unknown',
              'time': data['time'] ?? '00:00',
              'date': data['date'] ?? formattedDate,
            };
          }).toList();

      setState(() {
        _availableMatches = matches;
        _isLoading = false;
        _selectedMatch = null;
        _selectedTimeSlot = null;
        _selectedSeat = null;
      });
    } catch (e) {
      print('Error fetching matches: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load matches: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _onDateChanged(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
    _fetchMatchesFromApi();
  }

  Future<void> _fetchBookedSeats() async {
    if (_selectedMatch == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final bookingsSnapshot = await FirebaseFirestore.instance
          .collection('bookings')
          .where('matchId', isEqualTo: _selectedMatch!['id'])
          .get()
          .timeout(const Duration(seconds: 10));

      final bookedSeats =
          bookingsSnapshot.docs
              .map((doc) => doc.data()['seatNumber'] as String)
              .toList();

      if (mounted) {
        setState(() {
          _bookedSeats.clear();
          _bookedSeats.addAll(bookedSeats);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching booked seats: $e');

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (e.toString().contains('permission-denied')) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Firebase permission error: Please check your database rules',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading bookings: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _bookSeat() async {
    if (_selectedMatch == null || _selectedSeat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a match and seat'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to book seats'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'Anonymous',
        'stadiumId': widget.stadium.id,
        'stadiumName': widget.stadium.name,
        'matchId': _selectedMatch!['id'],
        'homeTeam': _selectedMatch!['homeTeam'],
        'awayTeam': _selectedMatch!['awayTeam'],
        'date': _selectedMatch!['date'],
        'time': _selectedMatch!['time'],
        'seatNumber': _selectedSeat,
        'bookingTime': FieldValue.serverTimestamp(),
        'cityId': widget.stadium.cityId,
      });

      setState(() {
        _bookedSeats.add(_selectedSeat!);
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Successfully booked $_selectedSeat for ${_selectedMatch!["homeTeam"]} vs ${_selectedMatch!["awayTeam"]}',
          ),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _selectedSeat = null;
      });

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      print('Error booking seat: $e');
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to book seat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fetchMatchesFromApi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiKey = dotenv.env['FOOTBALL_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        throw Exception(
          'API key not found. Please add your token to the .env file.',
        );
      }

      final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final nextDay = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate.add(const Duration(days: 7)));

      final apiUrl =
          'https://api.football-data.org/v4/competitions/PL/matches?dateFrom=$formattedDate&dateTo=$nextDay';

      print('Fetching matches from: $apiUrl');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {'X-Auth-Token': apiKey},
      );

      if (response.statusCode == 200) {
        print('API response received successfully');
        final jsonData = json.decode(response.body);
        final matches = jsonData['matches'] as List<dynamic>;

        print('Found ${matches.length} matches');

        if (matches.isEmpty) {
          setState(() {
            _availableMatches = [];
            _isLoading = false;
          });
          return;
        }

        setState(() {
          _availableMatches =
              matches.map((match) {
                final homeTeam = match['homeTeam']['name'] ?? 'Unknown Team';
                final awayTeam = match['awayTeam']['name'] ?? 'Unknown Team';
                final matchTime = DateTime.parse(
                  match['utcDate'] ?? DateTime.now().toIso8601String(),
                );

                return {
                  'id': match['id'].toString(),
                  'homeTeam': homeTeam,
                  'awayTeam': awayTeam,
                  'time': DateFormat('HH:mm').format(matchTime),
                  'date': DateFormat('yyyy-MM-dd').format(matchTime),
                  'venue': match['venue'] ?? widget.stadium.name,
                  'stadiumId': widget.stadium.id,
                };
              }).toList();

          _isLoading = false;
          _selectedMatch = null;
          _selectedTimeSlot = null;
          _selectedSeat = null;
        });
      } else {
        print('Failed to load matches from API: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception(
          'Failed to load matches from API: ${response.statusCode}',
        );
      }
    } catch (e) {
      print('Error fetching matches from API: $e');

      setState(() {
        _isLoading = false;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching matches: $e'),
            backgroundColor: Colors.red,
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Seat'),
        backgroundColor: secondaryColor,
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: primaryColor))
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Stadium: ${widget.stadium.name}'),
                      _buildCalendarCard(),

                      const SizedBox(height: 16),

                      _buildSectionTitle('Select a Match'),
                      _availableMatches.isEmpty
                          ? _buildEmptyState(
                            'No matches available for this date',
                          )
                          : _buildMatchesList(),

                      if (_selectedMatch != null) ...[
                        const SizedBox(height: 20),
                        _buildSectionTitle('Select a Seat'),
                        _buildSeatSelector(),
                        const SizedBox(height: 80),
                      ],
                    ],
                  ),
                ),
              ),
      bottomNavigationBar:
          _selectedSeat != null
              ? Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: ElevatedButton(
                    onPressed: _bookSeat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: secondaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Confirm Booking: $_selectedSeat',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              )
              : null,
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(Icons.sports_soccer, color: secondaryColor),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: secondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 90)),
              focusedDay: _selectedDate,
              selectedDayPredicate: (day) => isSameDay(day, _selectedDate),
              onDaySelected: (selectedDay, focusedDay) {
                _onDateChanged(selectedDay);
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: primaryColor,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: TextStyle(
                  color: secondaryColor,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Selected: ${DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: secondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _availableMatches.length,
      itemBuilder: (context, index) {
        final match = _availableMatches[index];
        final isSelected =
            _selectedMatch != null && _selectedMatch!['id'] == match['id'];

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: isSelected ? 2 : 0,
            ),
          ),
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedMatch = match;
                _selectedTimeSlot = match['time'];
                _selectedSeat = null;
              });
              _fetchBookedSeats();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: secondaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.sports_soccer,
                      color: secondaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${match['homeTeam']} vs ${match['awayTeam']}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Time: ${match['time']}',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
                    size: isSelected ? 24 : 16,
                    color: isSelected ? primaryColor : Colors.grey,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSeatSelector() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (_selectedMatch != null) ...[
              Text(
                '${_selectedMatch!['homeTeam']} vs ${_selectedMatch!['awayTeam']}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '${_selectedMatch!['date']} at ${_selectedMatch!['time']}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const SizedBox(height: 20),
            ],

            Container(
              height: 80,
              margin: const EdgeInsets.symmetric(horizontal: 40),
              decoration: BoxDecoration(
                color: Colors.green[700],
                borderRadius: BorderRadius.circular(40),
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.grey[300]!, 'Available'),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red[400]!, 'Booked'),
                const SizedBox(width: 16),
                _buildLegendItem(primaryColor, 'Selected'),
              ],
            ),

            const SizedBox(height: 20),

            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                childAspectRatio: 1.0,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: _seats.length,
              itemBuilder: (context, index) {
                final seat = _seats[index];
                final isBooked = _bookedSeats.contains(seat);
                final isSelected = _selectedSeat == seat;

                return GestureDetector(
                  onTap:
                      isBooked
                          ? null
                          : () {
                            setState(() {
                              _selectedSeat = seat;
                            });
                            HapticFeedback.selectionClick();
                          },
                  child: Container(
                    decoration: BoxDecoration(
                      color:
                          isBooked
                              ? Colors.red[400]
                              : isSelected
                              ? primaryColor
                              : Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: isSelected ? 1.5 : 0,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        (index + 1).toString(),
                        style: TextStyle(
                          color:
                              isBooked || isSelected
                                  ? Colors.white
                                  : Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[800])),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 0,
        color: Colors.grey[100],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.event_busy, size: 48, color: Colors.grey[500]),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed:
                    () => _onDateChanged(
                      _selectedDate.add(const Duration(days: 1)),
                    ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black87,
                ),
                child: const Text('Try another date'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
