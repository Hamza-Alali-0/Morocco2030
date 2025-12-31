import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/transportation/transportation_model.dart';
import 'package:flutter_application_1/transportation/transportation_service.dart';

class FareCalculatorScreen extends StatefulWidget {
  final City city;
  final TransportType transportType;

  const FareCalculatorScreen({
    Key? key, 
    required this.city, 
    required this.transportType,
  }) : super(key: key);

  @override
  State<FareCalculatorScreen> createState() => _FareCalculatorScreenState();
}

class _FareCalculatorScreenState extends State<FareCalculatorScreen> {
  final TransportationService _transportService = TransportationService();
  
  // List of predefined locations
  final List<Map<String, dynamic>> _predefinedLocations = [];
  Map<String, dynamic>? _selectedStartLocation;
  Map<String, dynamic>? _selectedEndLocation;
  
  // For fare calculation
  double _distance = 0;
  double _fare = 0;
  
  // Base fares by transport type (in case we don't have specific routes)
  final Map<TransportType, double> _baseFares = {
    TransportType.taxi: 15.0,
    TransportType.bus: 5.0,
    TransportType.tramway: 7.0,
    TransportType.train: 30.0,
  };
  
  final Map<TransportType, double> _farePerKm = {
    TransportType.taxi: 2.0,
    TransportType.bus: 0.5,
    TransportType.tramway: 0.5,
    TransportType.train: 1.0,
  };

  @override
  void initState() {
    super.initState();
    _loadPredefinedLocations();
  }

  void _loadPredefinedLocations() {
    // In a real app, you would load these from Firestore
    // For this example, we'll create some hardcoded locations
    setState(() {
      _predefinedLocations.addAll([
        {
          'name': 'City Center',
          'geopoint': GeoPoint(widget.city.location.latitude, widget.city.location.longitude),
        },
        {
          'name': 'Airport',
          'geopoint': GeoPoint(
            widget.city.location.latitude - 0.05, 
            widget.city.location.longitude + 0.05
          ),
        },
        {
          'name': 'Train Station',
          'geopoint': GeoPoint(
            widget.city.location.latitude + 0.02, 
            widget.city.location.longitude - 0.01
          ),
        },
        {
          'name': 'Beach',
          'geopoint': GeoPoint(
            widget.city.location.latitude + 0.04, 
            widget.city.location.longitude + 0.06
          ),
        },
        {
          'name': 'University',
          'geopoint': GeoPoint(
            widget.city.location.latitude - 0.03, 
            widget.city.location.longitude - 0.02
          ),
        },
      ]);
      
      // Set default selections
      _selectedStartLocation = _predefinedLocations[0];
      _selectedEndLocation = _predefinedLocations[1];
      
      // Calculate initial fare
      _calculateFare();
    });
  }

  void _calculateFare() {
    if (_selectedStartLocation == null || _selectedEndLocation == null) {
      return;
    }
    
    // Calculate distance
    _distance = _transportService.calculateDistance(
      _selectedStartLocation!['geopoint'] as GeoPoint,
      _selectedEndLocation!['geopoint'] as GeoPoint,
    );
    
    // Calculate fare based on transport type
    switch (widget.transportType) {
      case TransportType.taxi:
        _fare = _baseFares[TransportType.taxi]! + (_farePerKm[TransportType.taxi]! * _distance);
        break;
      case TransportType.bus:
        // Bus usually has a flat fare
        _fare = _baseFares[TransportType.bus]!;
        break;
      case TransportType.tramway:
        // Tramway usually has a flat fare
        _fare = _baseFares[TransportType.tramway]!;
        break;
      case TransportType.train:
        // Train fare based on distance
        _fare = _baseFares[TransportType.train]! + (_farePerKm[TransportType.train]! * _distance);
        break;
    }
    
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final String transportTypeName = widget.transportType.toString().split('.').last.toUpperCase();
    
    return Scaffold(
      appBar: AppBar(
        title: Text('$transportTypeName Fare Calculator'),
        backgroundColor: const Color(0xFFFDCB00),
      ),
      body: Column(
        children: [
          // Location selection
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Start location
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.trip_origin, color: Colors.green),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Starting point',
                              border: OutlineInputBorder(),
                            ),
                            value: _predefinedLocations.indexWhere(
                              (loc) => loc['name'] == _selectedStartLocation?['name']
                            ),
                            onChanged: (index) {
                              if (index != null && index >= 0) {
                                setState(() {
                                  _selectedStartLocation = _predefinedLocations[index];
                                  _calculateFare();
                                });
                              }
                            },
                            items: List.generate(
                              _predefinedLocations.length,
                              (index) => DropdownMenuItem<int>(
                                value: index,
                                child: Text(_predefinedLocations[index]['name'] as String),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // End location
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.place, color: Colors.red),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            decoration: const InputDecoration(
                              labelText: 'Destination',
                              border: OutlineInputBorder(),
                            ),
                            value: _predefinedLocations.indexWhere(
                              (loc) => loc['name'] == _selectedEndLocation?['name']
                            ),
                            onChanged: (index) {
                              if (index != null && index >= 0) {
                                setState(() {
                                  _selectedEndLocation = _predefinedLocations[index];
                                  _calculateFare();
                                });
                              }
                            },
                            items: List.generate(
                              _predefinedLocations.length,
                              (index) => DropdownMenuItem<int>(
                                value: index,
                                child: Text(_predefinedLocations[index]['name'] as String),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // Simple map representation
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: CustomPaint(
                size: const Size(double.infinity, double.infinity),
                painter: SimpleRoutePainter(
                  startLocation: _selectedStartLocation?['name'] ?? 'Start',
                  endLocation: _selectedEndLocation?['name'] ?? 'End',
                  transportType: widget.transportType,
                ),
              ),
            ),
          ),
          
          // Fare calculation results
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Distance',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${_distance.toStringAsFixed(1)} km',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getTransportIcon(widget.transportType),
                          color: _getTransportColor(widget.transportType),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$transportTypeName Fare',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${_fare.toStringAsFixed(1)} DH',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: _getTransportColor(widget.transportType),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    // Here you could implement booking functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking feature coming soon!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  icon: const Icon(Icons.confirmation_num),
                  label: const Text('Book Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF065d67),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getTransportColor(TransportType type) {
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

  IconData _getTransportIcon(TransportType type) {
    switch (type) {
      case TransportType.taxi:
        return Icons.local_taxi;
      case TransportType.bus:
        return Icons.directions_bus;
      case TransportType.tramway:
        return Icons.tram;
      case TransportType.train:
        return Icons.train;
    }
  }
}

// Simple route painter instead of using map
class SimpleRoutePainter extends CustomPainter {
  final String startLocation;
  final String endLocation;
  final TransportType transportType;

  SimpleRoutePainter({
    required this.startLocation,
    required this.endLocation,
    required this.transportType,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final color = _getTransportColor(transportType);
    final icon = _getTransportIcon(transportType);
    
    // Background
    final Paint bgPaint = Paint()
      ..color = Colors.grey[100]!
      ..style = PaintingStyle.fill;
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // Draw grid lines to simulate a map
    final gridPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    for (int i = 0; i < size.width; i += 20) {
      canvas.drawLine(
        Offset(i.toDouble(), 0), 
        Offset(i.toDouble(), size.height),
        gridPaint
      );
    }
    
    for (int i = 0; i < size.height; i += 20) {
      canvas.drawLine(
        Offset(0, i.toDouble()), 
        Offset(size.width, i.toDouble()),
        gridPaint
      );
    }
    
    // Draw route
    final routePaint = Paint()
      ..color = color
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;
    
    final startPoint = Offset(size.width * 0.2, size.height * 0.3);
    final endPoint = Offset(size.width * 0.8, size.height * 0.7);
    
    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    path.quadraticBezierTo(
      size.width / 2, 
      size.height / 2 - 20,
      endPoint.dx, 
      endPoint.dy
    );
    
    canvas.drawPath(path, routePaint);
    
    // Draw start and end points
    final startCirclePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.fill;
    
    final endCirclePaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(startPoint, 8, startCirclePaint);
    canvas.drawCircle(endPoint, 8, endCirclePaint);
    
    // Draw location names
    _drawText(canvas, startLocation, startPoint, Offset(-5, -25), Colors.green[700]!);
    _drawText(canvas, endLocation, endPoint, Offset(-5, 20), Colors.red[700]!);
    
    // Draw vehicle icon along the path
    final pathMetrics = path.computeMetrics().first;
    final tangent = pathMetrics.getTangentForOffset(pathMetrics.length * 0.6)!;
    
    final vehicleIcon = Icons.directions_car;
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(vehicleIcon.codePoint),
        style: TextStyle(
          color: color,
          fontSize: 24,
          fontFamily: vehicleIcon.fontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    canvas.save();
    canvas.translate(tangent.position.dx, tangent.position.dy);
    canvas.rotate(tangent.angle);
    textPainter.paint(canvas, Offset(-textPainter.width / 2, -textPainter.height / 2));
    canvas.restore();
  }

  void _drawText(Canvas canvas, String text, Offset position, Offset offset, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.white.withOpacity(0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(position.dx + offset.dx, position.dy + offset.dy));
  }

  Color _getTransportColor(TransportType type) {
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

  IconData _getTransportIcon(TransportType type) {
    switch (type) {
      case TransportType.taxi:
        return Icons.local_taxi;
      case TransportType.bus:
        return Icons.directions_bus;
      case TransportType.tramway:
        return Icons.tram;
      case TransportType.train:
        return Icons.train;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}