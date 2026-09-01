import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart' as geo;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? currentPosition;
  String currentCity = 'New Delhi';
  String currentArea = 'Connaught Place, New Delhi';
  bool isLocating = false;

  /// Request GPS Location and reverse geocode
  Future<Position?> getCurrentLocation() async {
    isLocating = true;
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        isLocating = false;
        return currentPosition;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          isLocating = false;
          return currentPosition;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        isLocating = false;
        return currentPosition;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 8)),
      );

      currentPosition = position;

      try {
        final geocoding = geo.Geocoding();
        List<geo.Placemark> placemarks = await geocoding.placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          final locality = p.locality ?? p.subLocality ?? p.subAdministrativeArea ?? 'New Delhi';
          final name = p.name ?? p.street ?? locality;
          currentCity = locality.isNotEmpty ? locality : 'New Delhi';
          currentArea = '$name, $currentCity';
        }
      } catch (e) {
        debugPrint('Geocoding error: $e');
      }

      isLocating = false;
      return position;
    } catch (e) {
      debugPrint('LocationService error: $e');
      isLocating = false;
      return currentPosition;
    }
  }

  void setManualCity(String city) {
    currentCity = city;
    currentArea = '$city, Central';
  }
}
