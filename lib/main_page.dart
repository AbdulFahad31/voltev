import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_google_maps_webservices/places.dart' as gmws;
import 'package:location/location.dart' as loc;
import 'station_details_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final loc.Location location = loc.Location();
  final TextEditingController _searchController = TextEditingController();
  final gmws.GoogleMapsPlaces places = gmws.GoogleMapsPlaces(apiKey: "AIzaSyDJJdfZ_OfyYWCBcifXE2VHjpqeq-Q5cbU");

  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  bool _isLoading = true;
  LatLng _currentLatLng = const LatLng(11.0168, 76.9558);
  List<gmws.Prediction> _placePredictions = [];
  bool _showSearchResults = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _determinePosition();
  }

  void _onSearchChanged() {
    if (_searchController.text.isEmpty) {
      setState(() {
        _showSearchResults = false;
        _placePredictions.clear();
      });
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    final locData = await location.getLocation();
    if (locData.latitude == null || locData.longitude == null) return;

    setState(() {
      _currentLatLng = LatLng(locData.latitude!, locData.longitude!);
      _isLoading = false;
    });
    _fetchStationsNearLocation(_currentLatLng);
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final locData = await location.getLocation();
      if (locData.latitude == null || locData.longitude == null) return;

      final newPosition = LatLng(locData.latitude!, locData.longitude!);

      setState(() {
        _currentLatLng = newPosition;
      });

      mapController.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: newPosition,
            zoom: 14,
          ),
        ),
      );

      _fetchStationsNearLocation(newPosition);
    } catch (e) {
      debugPrint('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to get current location: ${e.toString()}'),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _onPlaceSearch(String query) async {
    if (query.isEmpty) return;

    setState(() => _showSearchResults = true);

    final response = await places.autocomplete(query);
    if (response.status == "OK" && mounted) {
      setState(() => _placePredictions = response.predictions);
    }
  }

  Future<void> _onPlaceSelected(String placeId) async {
    final detail = await places.getDetailsByPlaceId(placeId);
    if (detail.result.geometry?.location == null) return;

    final lat = detail.result.geometry!.location.lat;
    final lng = detail.result.geometry!.location.lng;

    if (!mounted) return;

    setState(() {
      _currentLatLng = LatLng(lat, lng);
      _searchController.text = detail.result.name ?? "";
      _showSearchResults = false;
      _placePredictions.clear();
    });

    mapController.animateCamera(CameraUpdate.newLatLngZoom(_currentLatLng, 15));
    _fetchStationsNearLocation(_currentLatLng);
  }

  Future<void> _fetchStationsNearLocation(LatLng location) async {
    setState(() => _isLoading = true);
    try {
      // First try with exact EV charging station type
      var response = await places.searchNearbyWithRadius(
        gmws.Location(lat: location.latitude, lng: location.longitude),
        5000, // 5km radius
        type: 'electric_vehicle_charging_station',
        keyword: 'EV charging station',
      );

      // If no results, try with more generic type
      if (response.results.isEmpty) {
        response = await places.searchNearbyWithRadius(
          gmws.Location(lat: location.latitude, lng: location.longitude),
          5000,
          type: 'charging_station',
          keyword: 'electric vehicle charging',
        );
      }

      // Additional manual filtering
      final evStations = response.results.where((place) {
        final name = place.name?.toLowerCase() ?? '';
        final types = place.types?.map((t) => t.toLowerCase()).toList() ?? [];

        return types.contains('electric_vehicle_charging_station') ||
            types.contains('charging_station') ||
            name.contains('ev') ||
            name.contains('electric') ||
            name.contains('charge') ||
            (place.name?.contains('EV') ?? false) ||
            (place.name?.contains('Electric') ?? false);
      }).toList();

      if (mounted) {
        if (evStations.isNotEmpty) {
          _createMarkersFromAPI(evStations);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No EV charging stations found in this area'),
              duration: Duration(seconds: 2),
            ),
          );
          _markers.clear();
          setState(() {});
        }
      }
    } catch (e) {
      debugPrint('Error fetching stations: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load stations: ${e.toString()}'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _createMarkersFromAPI(List<gmws.PlacesSearchResult> stations) {
    _markers.clear();
    for (final station in stations) {
      if (station.placeId == null || station.geometry?.location == null) continue;

      _markers.add(
        Marker(
          markerId: MarkerId(station.placeId!),
          position: LatLng(
            station.geometry!.location.lat,
            station.geometry!.location.lng,
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          infoWindow: InfoWindow(
            title: station.name ?? 'EV Charging Station',
            snippet: station.vicinity ?? 'Tap for details',
          ),
          onTap: () => _showStationDetails(station),
        ),
      );
    }
    if (mounted) setState(() {});
  }

  void _showStationDetails(gmws.PlacesSearchResult station) {
    if (station.placeId == null || station.geometry?.location == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StationDetailsPage(
          placeId: station.placeId!,
          latitude: station.geometry!.location.lat,
          longitude: station.geometry!.location.lng,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: (controller) => mapController = controller,
            initialCameraPosition: CameraPosition(
              target: _currentLatLng,
              zoom: 14,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
          ),

          if (_isLoading)
            const Center(child: CircularProgressIndicator()),

          // Custom Location Button - Top Right
          Positioned(
            top: 70,  // Positioned below the status bar
            right: 15,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(50),
              child: InkWell(
                borderRadius: BorderRadius.circular(50),
                onTap: _goToCurrentLocation,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const Icon(Icons.my_location, color: Colors.blue, size: 24),
                ),
              ),
            ),
          ),

          Positioned(
            top: 65,
            left: 15,
            right: 65,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [const BoxShadow(color: Colors.black26, blurRadius: 5)],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Search charging stations...",
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _showSearchResults = false;
                            _placePredictions.clear();
                          });
                        },
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                    ),
                    onChanged: (value) => _onPlaceSearch(value),
                  ),
                ),
                if (_showSearchResults && _placePredictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 5),
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 5)],
                    ),
                    child: Column(
                      children: _placePredictions
                          .map((p) => ListTile(
                        leading: const Icon(Icons.location_on),
                        title: Text(p.description ?? ""),
                        onTap: () => p.placeId != null ? _onPlaceSelected(p.placeId!) : null,
                      ))
                          .toList(),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      // Remove the floatingActionButton from Scaffold since we're using Positioned
    );
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
}