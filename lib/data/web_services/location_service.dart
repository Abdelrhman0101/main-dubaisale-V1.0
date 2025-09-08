import 'package:location/location.dart' as loc;
// import 'package:geolocator/geolocator.dart'; // Temporarily disabled
import 'package:geocoding/geocoding.dart' as geo;

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();
  
  final loc.Location _location = loc.Location();
  
  // Check if location service is enabled
  Future<bool> isLocationServiceEnabled() async {
    return await _location.serviceEnabled();
  }
  
  // Request to enable location service
  Future<bool> requestLocationService() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
    }
    return serviceEnabled;
  }
  
  // Check location permission
  Future<loc.PermissionStatus> checkLocationPermission() async {
    return await _location.hasPermission();
  }
  
  // Request location permission
  Future<loc.PermissionStatus> requestLocationPermission() async {
    loc.PermissionStatus permission = await _location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }
    return permission;
  }
  
  // Get current location using location package
  Future<loc.LocationData?> getCurrentLocationData() async {
    try {
      // Check if service is enabled
      bool serviceEnabled = await requestLocationService();
      if (!serviceEnabled) {
        throw Exception('Location service is not enabled');
      }
      
      // Check permission
      loc.PermissionStatus permission = await requestLocationPermission();
      if (permission == loc.PermissionStatus.denied || 
          permission == loc.PermissionStatus.deniedForever) {
        throw Exception('Location permission denied');
      }
      
      // Get location
      return await _location.getLocation();
    } catch (e) {
      print('Error getting location data: $e');
      return null;
    }
  }
  
  // Get current position using geolocator - TEMPORARILY DISABLED
  /*
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }
      
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied');
      }
      
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting current position: $e');
      return null;
    }
  }
  */
  
  // Listen to location changes
  Stream<loc.LocationData> getLocationStream() {
    return _location.onLocationChanged;
  }
  
  // Get address from coordinates
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<geo.Placemark> placemarks = await geo.placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        geo.Placemark place = placemarks[0];
        return '${place.street ?? ''}, ${place.locality ?? ''}, ${place.administrativeArea ?? ''}, ${place.country ?? ''}';
      }
      return null;
    } catch (e) {
      print('Error getting address from coordinates: $e');
      return null;
    }
  }
  
  // Get coordinates from address
  Future<geo.Location?> getCoordinatesFromAddress(String address) async {
    try {
      List<geo.Location> locations = await geo.locationFromAddress(address);
      if (locations.isNotEmpty) {
        return locations.first;
      }
      return null;
    } catch (e) {
      print('Error getting coordinates from address: $e');
      return null;
    }
  }
  
  // Calculate distance between two points in meters - TEMPORARILY DISABLED
  /*
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }
  */
  
  // Temporary replacement for distance calculation
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    // Simple approximation - replace with proper calculation later
    return 0.0;
  }
  
  // Format distance for display
  String formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.toStringAsFixed(0)} م';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} كم';
    }
  }
  
  // Check if location is within radius
  bool isWithinRadius(double lat1, double lon1, double lat2, double lon2, double radiusInMeters) {
    double distance = calculateDistance(lat1, lon1, lat2, lon2);
    return distance <= radiusInMeters;
  }
}