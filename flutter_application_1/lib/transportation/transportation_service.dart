import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/city/city_model.dart';
import 'package:flutter_application_1/transportation/transportation_model.dart';
import 'dart:math';

class TransportationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<TransportRoute>> getRoutesForCity(
    City city, {
    TransportType? type,
  }) async {
    try {
      Query query = _firestore
          .collection('transportRoutes')
          .where('cityId', isEqualTo: city.id);

      if (type != null) {
        query = query.where('type', isEqualTo: type.toString().split('.').last);
      }

      final querySnapshot = await query.get();
      return querySnapshot.docs
          .map((doc) => TransportRoute.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching transportation routes: $e');
      // Return mock data when there's no data in Firestore yet
      return _getMockRoutes(city.id);
    }
  }

  // Calculate fare based on distance between two points
  double calculateFare(TransportRoute route, double distanceInKm) {
    return route.baseFare + (route.farePerKm * distanceInKm);
  }

  // Calculate distance between two coordinates using Haversine formula
  double calculateDistance(GeoPoint start, GeoPoint end) {
    const double earthRadius = 6371; // Radius of the earth in km
    final double lat1 = start.latitude * (pi / 180);
    final double lon1 = start.longitude * (pi / 180);
    final double lat2 = end.latitude * (pi / 180);
    final double lon2 = end.longitude * (pi / 180);

    final double dLat = lat2 - lat1;
    final double dLon = lon2 - lon1;

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    final double distance = earthRadius * c;

    return distance;
  }

  // Provide mock data for demo purposes
  List<TransportRoute> _getMockRoutes(String cityId) {
    return [
      // TAXI ROUTES
      TransportRoute(
        id: '1',
        name: 'City Center - Airport',
        cityId: cityId,
        type: TransportType.taxi,
        startLocation: const GeoPoint(33.5731, -7.5898), // Casablanca center
        endLocation: const GeoPoint(33.3674, -7.5899), // Casablanca airport
        startName: 'City Center',
        endName: 'Mohammed V Airport',
        baseFare: 20.0,
        farePerKm: 2.5,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Ftaxi1.jpg?alt=media',
        description:
            'Direct taxi service from city center to the airport. Available 24/7 with professional drivers.',
        schedule: 'Available 24/7',
      ),
      TransportRoute(
        id: '2',
        name: 'Marina - Shopping Mall',
        cityId: cityId,
        type: TransportType.taxi,
        startLocation: const GeoPoint(33.6073, -7.6320),
        endLocation: const GeoPoint(33.5789, -7.7209),
        startName: 'Marina Bay',
        endName: 'Morocco Mall',
        baseFare: 15.0,
        farePerKm: 2.0,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Ftaxi2.jpg?alt=media',
        description:
            'Comfortable taxi service connecting Marina Bay with the largest shopping center in the city.',
        schedule: 'Available 24/7',
      ),
      TransportRoute(
        id: '3',
        name: 'Beach - Old Medina',
        cityId: cityId,
        type: TransportType.taxi,
        startLocation: const GeoPoint(33.6082, -7.6635),
        endLocation: const GeoPoint(33.5731, -7.5898),
        startName: 'Ain Diab Beach',
        endName: 'Old Medina',
        baseFare: 12.0,
        farePerKm: 2.0,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Ftaxi3.jpg?alt=media',
        description:
            'Quick taxi service from the beach area to the historic old city with fixed rates.',
        schedule: 'Available 24/7',
      ),

      // BUS ROUTES
      TransportRoute(
        id: '4',
        name: 'Bus Route 33',
        cityId: cityId,
        type: TransportType.bus,
        startLocation: const GeoPoint(33.5731, -7.5898),
        endLocation: const GeoPoint(33.5600, -7.6200),
        startName: 'Central Market',
        endName: 'University Campus',
        baseFare: 4.0,
        farePerKm: 0.0,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Fbus1.jpg?alt=media',
        description:
            'City bus connecting the central market to the university area. Air-conditioned buses with WiFi.',
        schedule: '5:30 AM - 9:00 PM, every 15 minutes',
      ),
      TransportRoute(
        id: '5',
        name: 'Bus Route 15',
        cityId: cityId,
        type: TransportType.bus,
        startLocation: const GeoPoint(33.5986, -7.6192),
        endLocation: const GeoPoint(33.5733, -7.6651),
        startName: 'Twin Center',
        endName: 'Corniche District',
        baseFare: 5.0,
        farePerKm: 0.0,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Fbus2.jpg?alt=media',
        description:
            'Express bus service from the business district to the coastal area. Limited stops for faster travel.',
        schedule: '6:00 AM - 10:00 PM, every 20 minutes',
      ),
      TransportRoute(
        id: '6',
        name: 'Bus Route 42',
        cityId: cityId,
        type: TransportType.bus,
        startLocation: const GeoPoint(33.5500, -7.6000),
        endLocation: const GeoPoint(33.5900, -7.5700),
        startName: 'Residential District',
        endName: 'Industrial Zone',
        baseFare: 3.5,
        farePerKm: 0.0,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Fbus3.jpg?alt=media',
        description:
            'Worker transport service connecting residential areas with the industrial zone. Extended hours for shift workers.',
        schedule: '4:30 AM - 11:30 PM, every 30 minutes',
      ),

      // TRAMWAY ROUTES
      TransportRoute(
        id: '7',
        name: 'Tramway Line 1',
        cityId: cityId,
        type: TransportType.tramway,
        startLocation: const GeoPoint(33.5731, -7.5898),
        endLocation: const GeoPoint(33.5900, -7.6100),
        startName: 'Sidi Moumen',
        endName: 'Ain Diab',
        baseFare: 6.0,
        farePerKm: 0.0,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Ftram1.jpg?alt=media',
        description:
            'Main tramway line connecting east and west of the city. Modern air-conditioned trams with WiFi access.',
        schedule: '6:00 AM - 10:30 PM, every 10 minutes',
      ),
      TransportRoute(
        id: '8',
        name: 'Tramway Line 2',
        cityId: cityId,
        type: TransportType.tramway,
        startLocation: const GeoPoint(33.5500, -7.6200),
        endLocation: const GeoPoint(33.6000, -7.5800),
        startName: 'Southern Station',
        endName: 'Northern Hub',
        baseFare: 6.0,
        farePerKm: 0.0,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Ftram2.jpg?alt=media',
        description:
            'North-south tramway line connecting major residential and commercial districts with multiple interchange stations.',
        schedule: '6:00 AM - 10:30 PM, every 12 minutes',
      ),

      // TRAIN ROUTES
      TransportRoute(
        id: '9',
        name: 'Metro Line A',
        cityId: cityId,
        type: TransportType.train,
        startLocation: const GeoPoint(33.5731, -7.5898),
        endLocation: const GeoPoint(33.5300, -7.6400),
        startName: 'Central Station',
        endName: 'South Terminal',
        baseFare: 8.0,
        farePerKm: 0.5,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Ftrain1.jpg?alt=media',
        description:
            'High-speed underground metro line with 10 stations covering the central and southern parts of the city.',
        schedule: '5:30 AM - 11:00 PM, every 8 minutes',
      ),
      TransportRoute(
        id: '10',
        name: 'Regional Express',
        cityId: cityId,
        type: TransportType.train,
        startLocation: const GeoPoint(33.5731, -7.5898),
        endLocation: const GeoPoint(33.8000, -7.4000),
        startName: 'Main Station',
        endName: 'Satellite City',
        baseFare: 15.0,
        farePerKm: 1.0,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Ftrain2.jpg?alt=media',
        description:
            'Regional train connecting the city center with the satellite city. Comfortable seating with dining car.',
        schedule: '6:00 AM - 9:00 PM, hourly service',
      ),
      TransportRoute(
        id: '11',
        name: 'Coastal Line',
        cityId: cityId,
        type: TransportType.train,
        startLocation: const GeoPoint(33.6082, -7.6635),
        endLocation: const GeoPoint(33.7200, -7.9000),
        startName: 'Coastal Station',
        endName: 'Beach Resort',
        baseFare: 12.0,
        farePerKm: 0.7,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Ftrain3.jpg?alt=media',
        description:
            'Scenic coastal railway with panoramic sea views. Popular with tourists and weekend travelers.',
        schedule: '7:00 AM - 8:00 PM, every 2 hours',
      ),

      // Additional specialized routes
      TransportRoute(
        id: '12',
        name: 'Airport Express Bus',
        cityId: cityId,
        type: TransportType.bus,
        startLocation: const GeoPoint(33.5731, -7.5898),
        endLocation: const GeoPoint(33.3674, -7.5899),
        startName: 'Central Station',
        endName: 'Airport Terminal',
        baseFare: 25.0,
        farePerKm: 0.0,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Fairportbus.jpg?alt=media',
        description:
            'Direct airport shuttle service with luggage compartments, WiFi, and comfortable seating. No stops between station and airport.',
        schedule: '4:00 AM - 12:00 AM, every 30 minutes',
      ),
      TransportRoute(
        id: '13',
        name: 'Tourist Hop-On Hop-Off',
        cityId: cityId,
        type: TransportType.bus,
        startLocation: const GeoPoint(33.5731, -7.5898),
        endLocation: const GeoPoint(33.5731, -7.5898), // Circular route
        startName: 'Tourist Information Center',
        endName: 'Tourist Information Center',
        baseFare: 18.0,
        farePerKm: 0.0,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Ftouristbus.jpg?alt=media',
        description:
            'Sightseeing bus with open top for tourists. Visits all major attractions with multilingual audio guide.',
        schedule: '9:00 AM - 6:00 PM, every 20 minutes',
      ),
      TransportRoute(
        id: '14',
        name: 'Night Bus N1',
        cityId: cityId,
        type: TransportType.bus,
        startLocation: const GeoPoint(33.5986, -7.6192),
        endLocation: const GeoPoint(33.5500, -7.6000),
        startName: 'Entertainment District',
        endName: 'Residential Areas',
        baseFare: 7.0,
        farePerKm: 0.0,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Fnightbus.jpg?alt=media',
        description:
            'Late night service connecting entertainment districts with residential areas. Enhanced security features.',
        schedule: '11:00 PM - 5:00 AM, hourly service',
      ),
      TransportRoute(
        id: '15',
        name: 'Executive Car Service',
        cityId: cityId,
        type: TransportType.taxi,
        startLocation: const GeoPoint(33.5731, -7.5898),
        endLocation: const GeoPoint(33.3674, -7.5899),
        startName: 'Custom Pickup',
        endName: 'Custom Dropoff',
        baseFare: 50.0,
        farePerKm: 3.5,
        imageUrl:
            'https://firebasestorage.googleapis.com/v0/b/your-project.appspot.com/o/transport%2Fexecutive.jpg?alt=media',
        description:
            'Premium transport service with luxury vehicles and professional drivers. Advance booking required.',
        schedule: 'Available 24/7 with reservation',
      ),
    ];
  }
}
