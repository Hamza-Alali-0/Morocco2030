import 'package:cloud_firestore/cloud_firestore.dart';

enum TransportType {
  taxi,
  bus,
  tramway,
  train
}

class TransportRoute {
  final String id;
  final String name;
  final String cityId;
  final TransportType type;
  final GeoPoint startLocation;
  final GeoPoint endLocation;
  final String startName;
  final String endName;
  final double baseFare;
  final double farePerKm;
  final String imageUrl;
  final String description;
  final String schedule;

  TransportRoute({
    required this.id,
    required this.name,
    required this.cityId,
    required this.type,
    required this.startLocation,
    required this.endLocation,
    required this.startName,
    required this.endName,
    required this.baseFare,
    required this.farePerKm,
    this.imageUrl = '',
    this.description = '',
    this.schedule = '',
  });

  factory TransportRoute.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransportRoute(
      id: doc.id,
      name: data['name'] ?? '',
      cityId: data['cityId'] ?? '',
      type: _parseTransportType(data['type'] ?? 'taxi'),
      startLocation: data['startLocation'] as GeoPoint? ?? const GeoPoint(0, 0),
      endLocation: data['endLocation'] as GeoPoint? ?? const GeoPoint(0, 0),
      startName: data['startName'] ?? '',
      endName: data['endName'] ?? '',
      baseFare: (data['baseFare'] ?? 0.0).toDouble(),
      farePerKm: (data['farePerKm'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      description: data['description'] ?? '',
      schedule: data['schedule'] ?? '',
    );
  }

  static TransportType _parseTransportType(String type) {
    switch (type.toLowerCase()) {
      case 'bus':
        return TransportType.bus;
      case 'tramway':
        return TransportType.tramway;
      case 'train':
        return TransportType.train;
      case 'taxi':
      default:
        return TransportType.taxi;
    }
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'cityId': cityId,
      'type': type.toString().split('.').last,
      'startLocation': startLocation,
      'endLocation': endLocation,
      'startName': startName,
      'endName': endName,
      'baseFare': baseFare,
      'farePerKm': farePerKm,
      'imageUrl': imageUrl,
      'description': description,
      'schedule': schedule,
    };
  }
}