import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapController extends GetxController {
  var currentPosition = Rx<LatLng>(const LatLng(0.0, 0.0));
  var mapController = Rx<GoogleMapController?>(null);
  var currentAddress = ''.obs;
  var searchedAddress = ''.obs;
  var searchedPosition = Rxn<LatLng>();
  var isLoadingLocation = false.obs;
  final searchTextController = TextEditingController();

  StreamSubscription<Position>? positionStream;
  Timer? _locationTimer;

  @override
  void onInit() {
    super.onInit();
    getCurrentLocation();
  }

  Future<void> getCurrentLocation() async {
    isLoadingLocation.value = true;

    bool serviceEnabled;
    LocationPermission permission;

    // Check if location service is enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      Get.snackbar(
        'Location Service',
        'Please enable location service',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isLoadingLocation.value = false;
      return;
    }

    // Check location permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        Get.snackbar(
          'Permission Denied',
          'Location permission is required',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        isLoadingLocation.value = false;
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      Get.snackbar(
        'Permission Denied',
        'Please enable location permission in settings',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isLoadingLocation.value = false;
      return;
    }

    // Get current position
    try {
      Position initialPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentPosition.value = LatLng(
        initialPosition.latitude,
        initialPosition.longitude,
      );

      getAddress();
      isLoadingLocation.value = false;

      // Cancel previous streams
      positionStream?.cancel();
      _locationTimer?.cancel();

      // Stream 1: Update marker & camera when user moves 10 meters
      positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10, // Update marker when moved 10 meters
            ),
          ).listen((Position position) {
            currentPosition.value = LatLng(
              position.latitude,
              position.longitude,
            );
            getAddress();

            // Update camera to follow user
            if (mapController.value != null) {
              mapController.value!.animateCamera(
                CameraUpdate.newLatLng(currentPosition.value),
              );
            }
          });

      // Stream 2: Send location to server/socket every 10 seconds
      _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        updateUserLocation();
      });
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to get location: $e',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isLoadingLocation.value = false;
    }
  }

  Future<void> getAddress() async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        currentPosition.value.latitude,
        currentPosition.value.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        currentAddress.value =
            '${place.street}, ${place.locality}, ${place.postalCode}';
      }
    } catch (e) {
      print('Error getting address: $e');
    }
  }

  void updateUserLocation() {
    // TODO: Send location to socket/server
    print(
      'Location update: ${currentPosition.value.latitude}, ${currentPosition.value.longitude}',
    );
  }

  void setMapController(GoogleMapController controller) {
    mapController.value = controller;
  }

  void setSearchedLocation({required LatLng latLng, required String address}) {
    searchedPosition.value = latLng;
    searchedAddress.value = address;

    if (mapController.value != null) {
      mapController.value!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: latLng, zoom: 15),
        ),
      );
    }
  }

  @override
  void onClose() {
    positionStream?.cancel();
    _locationTimer?.cancel();
    searchTextController.dispose();
    mapController.value?.dispose();
    super.onClose();
  }
}
