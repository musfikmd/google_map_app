import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapPolylineController extends GetxController {
  late GoogleMapController mapController;

  var lat = 23.8103.obs; // Dhaka latitude
  var lng = 90.4125.obs; // Dhaka longitude
  var polylines = <Polyline>{}.obs;
  var markers = <Marker>{}.obs;
  var isLocationLoading = false.obs;
  var routeDistance = ''.obs;
  var routeDuration = ''.obs;

  // Static points - Dhaka to Gazipur
  final LatLng originPoint = const LatLng(23.8103, 90.4125); // Dhaka
  final LatLng destinationPoint = const LatLng(23.9965, 90.4150); // Gazipur

  @override
  void onInit() {
    super.onInit();
    initializeMap();
  }

  Future<void> initializeMap() async {
    isLocationLoading.value = true;
    try {
      // Add markers for origin and destination
      _addMarkers();

      // Get route polyline
      await _getRoute(originPoint, destinationPoint);
    } catch (e) {
      debugPrint('Error initializing map: $e');
    } finally {
      isLocationLoading.value = false;
    }
  }

  void _addMarkers() {
    markers.clear();

    // Origin marker (Dhaka)
    markers.add(
      Marker(
        markerId: const MarkerId('origin'),
        position: originPoint,
        infoWindow: const InfoWindow(
          title: 'Origin - Dhaka',
          snippet: 'Starting Point',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      ),
    );

    // Destination marker (Gazipur)
    markers.add(
      Marker(
        markerId: const MarkerId('destination'),
        position: destinationPoint,
        infoWindow: const InfoWindow(
          title: 'Destination - Gazipur',
          snippet: 'End Point',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );
  }

  Future<void> _getRoute(LatLng origin, LatLng destination) async {
    final String apiKey = 'AIzaSyBURAx29cyivINvJysvLxh1bdHYq9BG1FY';
    final String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${origin.latitude},${origin.longitude}&destination=${destination.latitude},${destination.longitude}&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      debugPrint('API Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        debugPrint('API Response: ${response.body}');

        if (data['routes'].isNotEmpty) {
          debugPrint('Route found');

          // Extract polyline
          final String encodedPolyline =
              data['routes'][0]['overview_polyline']['points'];

          // Extract distance and duration
          final String distance =
              data['routes'][0]['legs'][0]['distance']['text'] ?? 'N/A';
          final String duration =
              data['routes'][0]['legs'][0]['duration']['text'] ?? 'N/A';

          routeDistance.value = distance;
          routeDuration.value = duration;

          List<LatLng> polylinePoints = _decodePolyline(encodedPolyline);
          _showRoute(polylinePoints);
        } else {
          debugPrint('No routes found');
        }
      } else {
        debugPrint('Failed to fetch route: ${response.reasonPhrase}');
      }
    } catch (e) {
      debugPrint('Error getting route: $e');
    }
  }

  List<LatLng> _decodePolyline(String polyline) {
    List<LatLng> points = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = polyline.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  void _showRoute(List<LatLng> points) {
    final Polyline routePolyline = Polyline(
      polylineId: const PolylineId('route'),
      color: const Color(0xFF4252FF),
      width: 6,
      points: points,
    );
    polylines.clear();
    polylines.add(routePolyline);
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  void onClose() {
    mapController.dispose();
    super.onClose();
  }
}
