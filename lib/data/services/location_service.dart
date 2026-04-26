// lib/data/services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double? latitude;
  final double? longitude;
  final String? error;
  bool get success => latitude != null && longitude != null;

  const LocationResult({this.latitude, this.longitude, this.error});
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    // Check if location services enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return const LocationResult(
          error: 'Location services are disabled. Please enable them in Settings.');
    }

    // Check/request permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return const LocationResult(
            error: 'Location permission denied. Enable it to use Near Me.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      return const LocationResult(
          error: 'Location permission permanently denied. Please enable it in App Settings.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult(
          latitude: position.latitude, longitude: position.longitude);
    } catch (e) {
      return LocationResult(error: 'Could not get location: $e');
    }
  }

  /// Distance in km between two coordinates (Haversine approximation)
  static double distanceKm(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000;
  }
}
