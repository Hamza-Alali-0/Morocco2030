import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/transportation/transportation_model.dart';
import 'package:flutter_application_1/transportation/transportation_service.dart';
import 'package:flutter_application_1/transportation/fare_calculator_screen.dart';

class TransportationScreen extends StatefulWidget {
  final City city;

  const TransportationScreen({Key? key, required this.city}) : super(key: key);

  @override
  State<TransportationScreen> createState() => _TransportationScreenState();
}

class _TransportationScreenState extends State<TransportationScreen>
    with SingleTickerProviderStateMixin {
  final TransportationService _transportService = TransportationService();
  List<TransportRoute> _allRoutes = [];
  List<TransportRoute> _filteredRoutes = [];
  bool _isLoading = true;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadTransportRoutes();

    // Set up listener for tab changes
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        _filterRoutesByTabIndex(_tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTransportRoutes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final routes = await _transportService.getRoutesForCity(widget.city);
      setState(() {
        _allRoutes = routes;
        _filteredRoutes = routes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transportation routes: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterRoutesByTabIndex(int index) {
    setState(() {
      if (index == 0) {
        _filteredRoutes =
            _allRoutes
                .where((route) => route.type == TransportType.taxi)
                .toList();
      } else if (index == 1) {
        _filteredRoutes =
            _allRoutes
                .where((route) => route.type == TransportType.bus)
                .toList();
      } else if (index == 2) {
        _filteredRoutes =
            _allRoutes
                .where((route) => route.type == TransportType.tramway)
                .toList();
      } else if (index == 3) {
        _filteredRoutes =
            _allRoutes
                .where((route) => route.type == TransportType.train)
                .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with filter
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Transportation in ${widget.city.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // Transport type tabs
        TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: const Color(0xFF065d67),
          labelColor: const Color(0xFF065d67),
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(icon: Icon(Icons.local_taxi), text: 'Taxi'),
            Tab(icon: Icon(Icons.directions_bus), text: 'Bus'),
            Tab(icon: Icon(Icons.tram), text: 'Tramway'),
            Tab(icon: Icon(Icons.train), text: 'Train'),
          ],
        ),

        // Fare calculator button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => FareCalculatorScreen(
                        city: widget.city,
                        transportType:
                            _tabController.index == 0
                                ? TransportType.taxi
                                : _tabController.index == 1
                                ? TransportType.bus
                                : _tabController.index == 2
                                ? TransportType.tramway
                                : TransportType.train,
                      ),
                ),
              );
            },
            icon: const Icon(Icons.calculate),
            label: const Text('Calculate Fare'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF065d67),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),

        // Content
        Expanded(
          child:
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredRoutes.isEmpty
                  ? const Center(
                    child: Text('No routes available for this type'),
                  )
                  : ListView.builder(
                    itemCount: _filteredRoutes.length,
                    itemBuilder: (context, index) {
                      final route = _filteredRoutes[index];
                      return _buildRouteCard(route);
                    },
                  ),
        ),
      ],
    );
  }

  Widget _buildRouteCard(TransportRoute route) {
    final Color cardColor;
    final IconData transportIcon;

    switch (route.type) {
      case TransportType.taxi:
        cardColor = Colors.amber.shade100;
        transportIcon = Icons.local_taxi;
        break;
      case TransportType.bus:
        cardColor = Colors.blue.shade100;
        transportIcon = Icons.directions_bus;
        break;
      case TransportType.tramway:
        cardColor = Colors.green.shade100;
        transportIcon = Icons.tram;
        break;
      case TransportType.train:
        cardColor = Colors.red.shade100;
        transportIcon = Icons.train;
        break;
    }

    // Calculate distance from route points
    final distance = _transportService.calculateDistance(
      route.startLocation,
      route.endLocation,
    );

    // Calculate the example fare
    final fare = _transportService.calculateFare(route, distance);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: cardColor.withOpacity(0.3),
          border: Border.all(color: cardColor, width: 1),
        ),
        child: Column(
          children: [
            ListTile(
              leading: CircleAvatar(
                backgroundColor: cardColor,
                child: Icon(transportIcon, color: Colors.black87),
              ),
              title: Text(
                route.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${route.startName} → ${route.endName}'),
              trailing: Text(
                '~${fare.toStringAsFixed(1)} DH',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (route.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Text(route.description),
              ),
            if (route.schedule.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        route.schedule,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              height: 150,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                child: _buildSimpleRouteMap(route),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Add this method to your class
  String _formatSchedule(String schedule) {
    // Convert "6:00 AM - 10:00 PM, every 20 minutes" to "6AM-10PM (20min)"
    return schedule
        .replaceAll(':00', '')
        .replaceAll(', every ', ' (')
        .replaceAll(' minutes', 'min)')
        .replaceAll(' minute', 'min)')
        .replaceAll('hourly service', '1hr intervals');
  }

  Widget _buildSimpleRouteMap(TransportRoute route) {
    // Using a simple static representation instead of an interactive map
    return Container(
      color: Colors.grey[200],
      child: Stack(
        children: [
          // Fake map background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://maps.googleapis.com/maps/api/staticmap?center=${route.startLocation.latitude},${route.startLocation.longitude}&zoom=12&size=600x300&maptype=roadmap&markers=color:green%7C${route.startLocation.latitude},${route.startLocation.longitude}&markers=color:red%7C${route.endLocation.latitude},${route.endLocation.longitude}&key=YOUR_API_KEY',
                ),
                fit: BoxFit.cover,
                // Since we don't have an API key, this won't load - using onError to replace with a placeholder
                onError: (_, __) {},
              ),
            ),
          ),

          // Simple map visualization with start and end points
          CustomPaint(
            size: const Size(double.infinity, 150),
            painter: RouteMapPainter(
              startPoint: route.startLocation,
              endPoint: route.endLocation,
              routeColor: _getRouteColor(route.type),
            ),
          ),

          // Labels
          Positioned(
            left: 10,
            top: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                route.startName,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),

          Positioned(
            right: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(route.endName, style: const TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRouteColor(TransportType type) {
    switch (type) {
      case TransportType.taxi:
        return Colors.amber;
      case TransportType.bus:
        return Colors.blue;
      case TransportType.tramway:
        return Colors.green;
      case TransportType.train:
        return Colors.red;
    }
  }
}

// Custom painter to draw a simplified route
class RouteMapPainter extends CustomPainter {
  final GeoPoint startPoint;
  final GeoPoint endPoint;
  final Color routeColor;

  RouteMapPainter({
    required this.startPoint,
    required this.endPoint,
    required this.routeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Simple painter that draws a line between start and end points
    final paint =
        Paint()
          ..color = routeColor
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke;

    // Start point
    final startPaint =
        Paint()
          ..color = Colors.green
          ..style = PaintingStyle.fill;

    // End point
    final endPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.fill;

    // Convert geo coordinates to relative positions on the canvas
    // This is a very simplified representation
    final startX = 50.0;
    final startY = size.height / 3;
    final endX = size.width - 50.0;
    final endY = size.height * 2 / 3;

    // Draw route line
    final path = Path();
    path.moveTo(startX, startY);

    // Add a slight curve to the path
    path.quadraticBezierTo(
      size.width / 2,
      (startY > endY) ? startY + 30 : startY - 30,
      endX,
      endY,
    );

    canvas.drawPath(path, paint);

    // Draw start and end points
    canvas.drawCircle(Offset(startX, startY), 8, startPaint);
    canvas.drawCircle(Offset(endX, endY), 8, endPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
