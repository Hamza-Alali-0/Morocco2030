import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert'; 

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({Key? key}) : super(key: key);

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Color primaryColor = const Color(0xFFFDCB00);
  final Color secondaryColor = const Color(0xFF065d67);
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); 
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

Widget _buildGuideBookings() {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    return const Center(child: Text('Please sign in to view your bookings'));
  }
  
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('guideId', isGreaterThan: '') // Filter for guide bookings
        .orderBy('guideId')
        .orderBy('date', descending: false)
        .limit(50)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No guide bookings yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          final doc = snapshot.data!.docs[index];
          final data = doc.data() as Map<String, dynamic>;
          
          final guideName = data['guideName'] ?? 'Unknown Guide';
          final timestamp = data['date'] as Timestamp?;
          final date = timestamp != null ? timestamp.toDate() : DateTime.now();
          final people = data['people'] ?? 1;
          final status = data['status'] ?? 'pending';
          final duration = data['duration'] ?? 1;
          final totalPrice = data['totalPrice'] ?? 0.0;
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildGuideAvatar(data),  // <-- Replace CircleAvatar with this
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          guideName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _buildStatusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    Icons.calendar_today,
                    DateFormat('MMM dd, yyyy').format(date),
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.access_time,
                    '${DateFormat('h:mm a').format(date)} (${duration}h)',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.people,
                    '$people ${people == 1 ? 'person' : 'people'}',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.payments,
                    '${totalPrice.toStringAsFixed(2)} MAD',
                  ),
                  
                  if (status == 'pending')
                    Padding(
                      padding: const EdgeInsets.only(top: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _cancelBooking(doc.id),
                            child: const Text(
                              'Cancel Booking',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bookings'),
        backgroundColor: secondaryColor,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryColor,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true, // Make tabs scrollable
          tabs: const [
            Tab(text: 'Restaurants'),
            Tab(text: 'Guides'),
            Tab(text: 'Activities'), 
            Tab(text: 'Tickets'),
            Tab(text: 'Accommodations'), 
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildRestaurantBookings(),
          _buildGuideBookings(),
          _buildActivityBookings(), // New tab view
          _buildTicketBookings(),
          _buildLocationBookings(), 
        ],
      ),
    );
  }

  Widget _buildRestaurantBookings() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Center(child: Text('Please sign in to view your bookings'));
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('restaurantId', isGreaterThan: '') // Filter for restaurant bookings
          .orderBy('restaurantId')
          .orderBy('date', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No restaurant bookings yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final restaurantName = data['restaurantName'] ?? 'Unknown Restaurant';
            final timestamp = data['date'] as Timestamp?;
            final date = timestamp != null ? timestamp.toDate() : DateTime.now();
            final guests = data['guests'] ?? 1;
            final status = data['status'] ?? 'pending';
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            restaurantName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      Icons.calendar_today,
                      DateFormat('MMM dd, yyyy').format(date),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.access_time,
                      DateFormat('h:mm a').format(date),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      Icons.people,
                      '$guests ${guests == 1 ? 'guest' : 'guests'}',
                    ),
                    
                    if (status == 'pending')
                      Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => _cancelBooking(doc.id),
                              child: const Text(
                                'Cancel Booking',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildHotelBookings() {
    // Similar implementation for hotel bookings
    return const Center(
      child: Text('Hotel bookings coming soon'),
    );
  }
  
  Widget _buildTicketBookings() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Center(child: Text('Please sign in to view your bookings'));
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('stadiumId', isGreaterThan: '') // Filter for stadium bookings
          .orderBy('stadiumId')
          .orderBy('date', descending: false)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.sports_soccer, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No stadium ticket bookings yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to stadium listing page
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  icon: const Icon(Icons.stadium),
                  label: const Text('Explore Stadiums'),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final stadiumName = data['stadiumName'] ?? 'Unknown Stadium';
            final homeTeam = data['homeTeam'] ?? 'Home Team';
            final awayTeam = data['awayTeam'] ?? 'Away Team';
            final matchDate = data['date'] ?? '';
            final matchTime = data['time'] ?? '';
            final seatNumber = data['seatNumber'] ?? '';
            final status = data['status'] ?? 'pending';
            
            // Parse the date correctly - depending on format stored
            DateTime? date;
            if (data['date'] is Timestamp) {
              date = (data['date'] as Timestamp).toDate();
            } else if (data['date'] is String) {
              try {
                date = DateFormat('yyyy-MM-dd').parse(data['date']);
              } catch (e) {
                print('Error parsing date: $e');
              }
            }
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: secondaryColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sports_soccer, color: Colors.white),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$homeTeam vs $awayTeam',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        _buildStatusBadge(status),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoRow(
                          Icons.stadium,
                          stadiumName,
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.calendar_today,
                          date != null ? DateFormat('EEE, MMM d, yyyy').format(date) : matchDate,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.access_time,
                          matchTime,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.event_seat,
                          'Seat: $seatNumber',
                        ),
                        
                        if (status == 'pending')
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _cancelBooking(doc.id),
                                  child: const Text(
                                    'Cancel Booking',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  _buildTicketStub(seatNumber, '$homeTeam vs $awayTeam', matchTime),
                ],
              ),
            );
          },
        );
      },
    );
  }
  
  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
  
  Widget _buildStatusBadge(String status) {
    Color color;
    String text;
    
    switch (status) {
      case 'confirmed':
        color = Colors.green;
        text = 'Confirmed';
        break;
      case 'completed':
        color = Colors.blue;
        text = 'Completed';
        break;
      case 'cancelled':
        color = Colors.red;
        text = 'Cancelled';
        break;
      case 'pending':
      default:
        color = Colors.orange;
        text = 'Pending';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 12),
      ),
    );
  }
  // Add this new method to _MyBookingsScreenState class

Widget _buildLocationBookings() {
  final user = FirebaseAuth.instance.currentUser;
  
  if (user == null) {
    return const Center(child: Text('Please sign in to view your bookings'));
  }
  
  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('bookings')
        .where('userId', isEqualTo: user.uid)
        .where('locationId', isGreaterThan: '') // Filter for location bookings
        .where('type', isEqualTo: 'location') // Added type filter
        .orderBy('type')
        .orderBy('locationId')
        .orderBy('date', descending: false) // Changed from checkIn to date
        .limit(50)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }
      
      if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      }
      
      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.hotel, size: 80, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'No accommodation bookings yet',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  // Navigate back to explore accommodations
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                icon: const Icon(Icons.hotel),
                label: const Text('Explore Accommodations'),
              ),
            ],
          ),
        );
      }
      
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: snapshot.data!.docs.length,
        itemBuilder: (context, index) {
          final doc = snapshot.data!.docs[index];
          final data = doc.data() as Map<String, dynamic>;
          
          final locationName = data['locationName'] ?? 'Unknown Location';
          final locationImage = data['locationImage'];
          final locationType = data['locationType'] ?? 'Hotel';
          
          // Handle various date formats - update to match the fields from your bookings
          DateTime? checkIn;
          if (data['date'] is Timestamp) {
            checkIn = (data['date'] as Timestamp).toDate();
          } else if (data['date'] is String) {
            try {
              checkIn = DateFormat('yyyy-MM-dd').parse(data['date']);
            } catch (e) {
              print('Error parsing check-in date: $e');
            }
          }
          
          DateTime? checkOut;
          if (data['checkoutDate'] is Timestamp) {
            checkOut = (data['checkoutDate'] as Timestamp).toDate();
          } else if (data['checkoutDate'] is String) {
            try {
              checkOut = DateFormat('yyyy-MM-dd').parse(data['checkoutDate']);
            } catch (e) {
              print('Error parsing check-out date: $e');
            }
          }
          
          final guests = data['guests'] ?? 1;
          final rooms = data['rooms'] ?? 1;
          final totalPrice = data['totalPrice'] ?? 0.0;
          final status = data['status'] ?? 'pending';
          
          // Calculate number of nights
          int nights = 1;
          if (checkIn != null && checkOut != null) {
            nights = checkOut.difference(checkIn).inDays;
          }
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Column(
              children: [
                // Location image at the top
                if (locationImage != null && locationImage.toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: _buildBookingImage(locationImage.toString(), Icons.hotel),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  locationName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  locationType,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Dates section with check-in and check-out
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CHECK-IN',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    checkIn != null 
                                      ? DateFormat('EEE, MMM d, yyyy').format(checkIn)
                                      : 'Not specified',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey[300],
                              margin: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'CHECK-OUT',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    checkOut != null 
                                      ? DateFormat('EEE, MMM d, yyyy').format(checkOut)
                                      : 'Not specified',
                                    style: const TextStyle(fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              Icons.nights_stay,
                              '$nights ${nights == 1 ? 'night' : 'nights'}',
                            ),
                          ),
                          Expanded(
                            child: _buildInfoRow(
                              Icons.meeting_room,
                              '$rooms ${rooms == 1 ? 'room' : 'rooms'}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildInfoRow(
                              Icons.people,
                              '$guests ${guests == 1 ? 'guest' : 'guests'}',
                            ),
                          ),
                          Expanded(
                            child: _buildInfoRow(
                              Icons.payment,
                              '${totalPrice.toStringAsFixed(2)} MAD',
                            ),
                          ),
                        ],
                      ),
                      
                      if (status == 'pending' && checkIn != null && 
                          checkIn.isAfter(DateTime.now().subtract(const Duration(days: 1))))
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => _cancelBooking(doc.id),
                                child: const Text(
                                  'Cancel Booking',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Bottom confirmation number section
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.confirmation_number, size: 16, color: secondaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Confirmation: ${doc.id.substring(0, 8).toUpperCase()}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: secondaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

// Helper method to display booking images with base64 support
Widget _buildBookingImage(String imageSource, IconData fallbackIcon) {
  if (imageSource.isEmpty) {
    return Container(
      height: 140,
      width: double.infinity,
      color: Colors.grey[300],
      child: Icon(fallbackIcon, color: Colors.grey[600], size: 40),
    );
  }
  
  if (imageSource.startsWith('data:image') || RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
    try {
      String base64String = imageSource.startsWith('data:image') ? 
                          imageSource.split(',')[1] : 
                          imageSource;
      return Image.memory(
        base64Decode(base64String),
        height: 140,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          height: 140,
          color: Colors.grey[300],
          child: Icon(fallbackIcon, color: Colors.grey[600], size: 40),
        ),
      );
    } catch (e) {
      print('Error decoding image: $e');
      return Container(
        height: 140,
        color: Colors.grey[300],
        child: Icon(fallbackIcon, color: Colors.grey[600], size: 40),
      );
    }
  }
  
  return Image.network(
    imageSource,
    height: 140,
    width: double.infinity,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) => Container(
      height: 140,
      color: Colors.grey[300],
      child: Icon(fallbackIcon, color: Colors.grey[600], size: 40),
    ),
  );
}
  Future<void> _cancelBooking(String bookingId) async {
    try {
      // Show confirmation dialog
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Booking'),
          content: const Text('Are you sure you want to cancel this booking?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      
      if (shouldCancel == true) {
        await FirebaseFirestore.instance
            .collection('bookings')
            .doc(bookingId)
            .update({'status': 'cancelled'});
            
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking cancelled')),
        );
      }
    } catch (e) {
      print('Error cancelling booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to cancel booking')),
      );
    }
  }

  Widget _buildGuideAvatar(Map<String, dynamic> data) {
    // Check if guide image exists in booking data
    final guideProfileImage = data['guideProfileImage'];
    
    if (guideProfileImage != null && guideProfileImage.toString().isNotEmpty) {
      // Try to decode as base64
      try {
        String base64String = guideProfileImage.toString();
        // Check if it has the data:image prefix
        if (base64String.startsWith('data:image')) {
          base64String = base64String.split(',')[1];
        }
        
        return CircleAvatar(
          radius: 20,
          backgroundImage: MemoryImage(base64Decode(base64String)),
          onBackgroundImageError: (exception, stackTrace) {
            print('Error loading guide avatar: $exception');
          },
          backgroundColor: secondaryColor.withOpacity(0.2),
          child: Container(), // Empty container so the icon doesn't show on top of the image
        );
      } catch (e) {
        print('Error decoding guide profile image: $e');
        // Fall back to default icon on error
        return CircleAvatar(
          backgroundColor: secondaryColor.withOpacity(0.2),
          radius: 20,
          child: Icon(Icons.person, color: secondaryColor),
        );
      }
    }
    
    // Default icon if no image available
    return CircleAvatar(
      backgroundColor: secondaryColor.withOpacity(0.2),
      radius: 20,
      child: Icon(Icons.person, color: secondaryColor),
    );
  }

  Widget _buildActivityBookings() {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return const Center(child: Text('Please sign in to view your bookings'));
    }
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'activity')
          .orderBy('date', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_available, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No activity bookings yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final activityName = data['activityName'] ?? 'Unknown Activity';
            final timestamp = data['date'] as Timestamp?;
            final date = timestamp != null ? timestamp.toDate() : DateTime.now();
            final participants = data['participants'] ?? 1;
            final pointsUsed = data['pointsUsed'] ?? 0;
            final status = data['status'] ?? 'pending';
            final activityImage = data['activityImage'];
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              child: Column(
                children: [
                  if (activityImage != null && activityImage.toString().isNotEmpty)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: _buildActivityImage(activityImage.toString()),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                activityName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildStatusBadge(status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildInfoRow(
                          Icons.calendar_today,
                          DateFormat('MMM dd, yyyy').format(date),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.access_time,
                          DateFormat('h:mm a').format(date),
                        ),
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.people,
                          '$participants ${participants == 1 ? 'person' : 'people'}',
                        ),
                        if (pointsUsed > 0) ...[
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            Icons.stars,
                            '$pointsUsed points redeemed',
                          ),
                        ],
                        
                        if (status == 'pending')
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _cancelActivityBooking(doc.id, pointsUsed),
                                  child: const Text(
                                    'Cancel Booking',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper method to display activity images with base64 support
  Widget _buildActivityImage(String imageSource) {
    if (imageSource.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        color: Colors.grey[300],
        child: Icon(Icons.image_not_supported, color: Colors.grey[600], size: 40),
      );
    }
    
    if (imageSource.startsWith('data:image') || RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(imageSource)) {
      try {
        String base64String = imageSource.startsWith('data:image') ? 
                            imageSource.split(',')[1] : 
                            imageSource;
        return Image.memory(
          base64Decode(base64String),
          height: 120,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            height: 120,
            color: Colors.grey[300],
            child: Icon(Icons.broken_image, color: Colors.grey[600], size: 40),
          ),
        );
      } catch (e) {
        print('Error decoding activity image: $e');
        return Container(
          height: 120,
          color: Colors.grey[300],
          child: Icon(Icons.broken_image, color: Colors.grey[600], size: 40),
        );
      }
    }
    
    return Image.network(
      imageSource,
      height: 120,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        height: 120,
        color: Colors.grey[300],
        child: Icon(Icons.broken_image, color: Colors.grey[600], size: 40),
      ),
    );
  }

  // Add this method to handle cancellation of activity bookings with point refunds
  Future<void> _cancelActivityBooking(String bookingId, int pointsUsed) async {
    try {
      final shouldCancel = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cancel Activity Booking'),
          content: Text(
            pointsUsed > 0 
            ? 'Are you sure you want to cancel this booking? Your ${pointsUsed} points will be refunded.'
            : 'Are you sure you want to cancel this booking?'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('No'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Yes'),
            ),
          ],
        ),
      );
      
      if (shouldCancel == true) {
        if (pointsUsed > 0) {
          // For point redemptions, handle refund logic
          final user = FirebaseAuth.instance.currentUser;
          if (user == null) return;
          
          // Get current user points
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();
              
          final currentPoints = (userDoc.data() ?? {})['fidelityPoints'] ?? 0;
          
          // Batch write to ensure consistency
          WriteBatch batch = FirebaseFirestore.instance.batch();
          
          // Update booking status
          batch.update(
            FirebaseFirestore.instance.collection('bookings').doc(bookingId),
            {'status': 'cancelled'}
          );
          
          // Refund points
          batch.update(
            FirebaseFirestore.instance.collection('users').doc(user.uid),
            {'fidelityPoints': currentPoints + pointsUsed}
          );
          
          // Commit the batch
          await batch.commit();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Booking cancelled and $pointsUsed points refunded'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // For regular bookings, just update status
          await FirebaseFirestore.instance
              .collection('bookings')
              .doc(bookingId)
              .update({'status': 'cancelled'});
              
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking cancelled')),
          );
        }
      }
    } catch (e) {
      print('Error cancelling activity booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to cancel booking'), 
          backgroundColor: Colors.red
        ),
      );
    }
  }

  Widget _buildTicketStub(String seat, String match, String time) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(12),
          bottomRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                const Text(
                  'SEAT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                ),
                Text(
                  seat.replaceAll('Seat ', ''),
                  style: const TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  match,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  time,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Image.asset(
            'assets/images/qr-placeholder.png',
            width: 40,
            height: 40,
            errorBuilder: (context, error, stackTrace) => Container(
              width: 40,
              height: 40,
              color: Colors.grey[300],
              child: Icon(Icons.qr_code_2, color: Colors.grey[600]),
            ),
          ),
        ],
      ),
    );
  }
}