import 'package:location/location.dart';

class LocationService {
  final Location _location = Location();

  Future<LocationData?> getCurrentLocation() async {
    try {
      bool serviceEnabled = await _location.serviceEnabled();
      if (!serviceEnabled) {
        serviceEnabled = await _location.requestService();
        if (!serviceEnabled) {
          throw Exception('Location service is disabled');
        }
      }

      PermissionStatus permissionGranted = await _location.hasPermission();
      if (permissionGranted == PermissionStatus.denied) {
        permissionGranted = await _location.requestPermission();
        if (permissionGranted != PermissionStatus.granted) {
          throw Exception('Location permission denied');
        }
      }

      return await _location.getLocation();
    } catch (e) {
      throw Exception('Failed to get location: $e');
    }
  }

  Future<bool> checkLocationPermissions() async {
    try {
      PermissionStatus permissionGranted = await _location.hasPermission();
      return permissionGranted == PermissionStatus.granted;
    } catch (e) {
      return false;
    }
  }

  Future<bool> isLocationServiceEnabled() async {
    try {
      return await _location.serviceEnabled();
    } catch (e) {
      return false;
    }
  }

  Future<PermissionStatus> requestLocationPermission() async {
    try {
      return await _location.requestPermission();
    } catch (e) {
      return PermissionStatus.denied;
    }
  }
}