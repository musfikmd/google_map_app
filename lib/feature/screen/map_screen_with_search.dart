import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import '../controller/map_controller.dart';

class MapScreenWithSearch extends StatelessWidget {
  MapScreenWithSearch({Key? key}) : super(key: key);

  final controller = Get.put(MapController());
  final String _googleApiKey = 'AIzaSyBURAx29cyivINvJysvLxh1bdHYq9BG1FY';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Map'),
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: Stack(
        children: [
          // Google Map
          Obx(() {
            if (controller.isLoadingLocation.value) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading Location...'),
                  ],
                ),
              );
            }

            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: controller.currentPosition.value,
                zoom: 15,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              onMapCreated: (GoogleMapController mapController) {
                controller.setMapController(mapController);
              },
              markers: {
                Marker(
                  markerId: const MarkerId("currentLocation"),
                  position: controller.currentPosition.value,
                  infoWindow: InfoWindow(
                    title: 'Your Location',
                    snippet: controller.currentAddress.value,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                ),
                if (controller.searchedPosition.value != null)
                  Marker(
                    markerId: const MarkerId("searchedLocation"),
                    position: controller.searchedPosition.value!,
                    infoWindow: InfoWindow(
                      title: 'Searched Location',
                      snippet: controller.searchedAddress.value,
                    ),
                    icon: BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    ),
                  ),
              },
            );
          }),

          // Search Bar with debounce (2 seconds)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: GooglePlaceAutoCompleteTextField(
                textEditingController: controller.searchTextController,
                googleAPIKey: _googleApiKey,
                debounceTime: 2000,
                isLatLngRequired: true,
                getPlaceDetailWithLatLng: (Prediction prediction) async {
                  final lat = double.tryParse(prediction.lat ?? '');
                  final lng = double.tryParse(prediction.lng ?? '');

                  if (lat != null && lng != null) {
                    controller.setSearchedLocation(
                      latLng: LatLng(lat, lng),
                      address:
                          prediction.description ?? 'Selected searched place',
                    );
                  }
                },
                itemClick: (Prediction prediction) {
                  controller.searchTextController.text =
                      prediction.description ?? '';
                },
                boxDecoration: const BoxDecoration(color: Colors.white),
                inputDecoration: const InputDecoration(
                  hintText: 'Search location',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                ),
                itemBuilder: (context, index, prediction) {
                  return ListTile(
                    title: Text(prediction.description ?? 'Unknown location'),
                  );
                },
              ),
            ),
          ),

          // Current Location Info at bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Obx(() {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Current Location',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lat: ${controller.currentPosition.value.latitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lng: ${controller.currentPosition.value.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 8),
                    if (controller.currentAddress.value.isNotEmpty)
                      Text(
                        'Address: ${controller.currentAddress.value}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              );
            }),
          ),

          // My Location Button (top right)
          Positioned(
            top: 84,
            right: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: () {
                if (controller.mapController.value != null) {
                  controller.mapController.value!.animateCamera(
                    CameraUpdate.newLatLng(controller.currentPosition.value),
                  );
                }
              },
              backgroundColor: Colors.blue,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}
