import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'time_selection_page.dart';
import 'google_maps_service.dart';

class StationDetailsPage extends StatefulWidget {
  final String placeId;
  final double latitude;
  final double longitude;

  const StationDetailsPage({
    super.key,
    required this.placeId,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<StationDetailsPage> createState() => _StationDetailsPageState();
}

class _StationDetailsPageState extends State<StationDetailsPage> {
  late Future<Map<String, dynamic>> _stationFuture;
  bool _isLoading = true;
  Map<String, dynamic>? _station;
  String? _selectedSlotType; // 'AC' or 'DC'

  @override
  void initState() {
    super.initState();
    _stationFuture = _fetchStationDetails();
  }

  Future<Map<String, dynamic>> _fetchStationDetails() async {
    try {
      final details = await GoogleMapsService.getPlaceDetails(widget.placeId);
      if (!mounted) return details;

      setState(() {
        _isLoading = false;
        _station = details;
      });
      return details;
    } catch (e) {
      if (!mounted) rethrow;

      setState(() {
        _isLoading = false;
      });
      throw Exception('Failed to load station details: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charging Station'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _station == null
          ? const Center(child: Text('Failed to load station details'))
          : _buildStationDetails(context, _station!),
    );
  }

  Widget _buildStationDetails(BuildContext context, Map<String, dynamic> station) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Image
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: station['photos'] != null && station['photos'].isNotEmpty
                  ? DecorationImage(
                image: NetworkImage(
                  'https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=${station['photos'][0]['photo_reference']}&key=${GoogleMapsService.apiKey}',
                ),
                fit: BoxFit.cover,
              )
                  : null,
              color: Colors.grey[200],
            ),
            child: station['photos'] == null || station['photos'].isEmpty
                ? const Center(child: Icon(Icons.ev_station, size: 50, color: Colors.grey))
                : null,
          ),

          // Basic Info
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station['name'] ?? 'Unknown Station',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  station['formatted_address'] ?? 'Address not available',
                  style: TextStyle(color: Colors.grey[600]),
                  softWrap: true,
                ),
                if (station['rating'] != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text('${station['rating']}'),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Charging Info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Charging Information',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow('Status', station['opening_hours']?['open_now'] == true ? 'Open Now' : 'Closed'),
                  _buildInfoRow('Connector Types', _parseConnectorTypes(station)),
                  _buildInfoRow('AC Price', _getACPrice(station)),
                  _buildInfoRow('DC Price', _getDCPrice(station)),
                  _buildInfoRow('Service Charge', '₹20 (fixed)'),
                ],
              ),
            ),
          ),

          // Slot Type Selection
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Charging Type',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('AC (₹86/kWh)'),
                          selected: _selectedSlotType == 'AC',
                          onSelected: (selected) {
                            setState(() {
                              _selectedSlotType = selected ? 'AC' : null;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ChoiceChip(
                          label: const Text('DC (₹150/kWh)'),
                          selected: _selectedSlotType == 'DC',
                          onSelected: (selected) {
                            setState(() {
                              _selectedSlotType = selected ? 'DC' : null;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.directions),
                    label: const Text('Directions'),
                    onPressed: () => _openGoogleMaps(station),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.bolt),
                    label: const Text('Book Slot'),
                    onPressed: _selectedSlotType == null
                        ? null
                        : () {
                      _navigateToTimeSelection(station);
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _navigateToTimeSelection(Map<String, dynamic> station) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TimeSelectionPage(
          placeId: widget.placeId,
          stationName: station['name'] ?? 'Charging Station',
          slotType: _selectedSlotType!,
          pricePerKwh: _selectedSlotType == 'AC'
              ? _getACPriceValue(station)
              : _getDCPriceValue(station),
          serviceCharge: 20,
          latitude: widget.latitude,
          longitude: widget.longitude,
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: TextStyle(color: Colors.grey[600]),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  String _parseConnectorTypes(Map<String, dynamic> station) {
    if (station['types'] != null) {
      final types = List<String>.from(station['types'])
          .where((type) => type.contains('charging'))
          .join(', ');
      return types.isNotEmpty ? types : 'Various connectors available';
    }
    return 'Various connectors available';
  }

  String _getACPrice(Map<String, dynamic> station) {
    return '₹${_getACPriceValue(station)}/kWh';
  }

  String _getDCPrice(Map<String, dynamic> station) {
    return '₹${_getDCPriceValue(station)}/kWh';
  }

  int _getACPriceValue(Map<String, dynamic> station) {
    return station['ac_price'] ?? 86; // Default AC price
  }

  int _getDCPriceValue(Map<String, dynamic> station) {
    return station['dc_price'] ?? 150; // Default DC price
  }

  Future<void> _openGoogleMaps(Map<String, dynamic> station) async {
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${station['geometry']['location']['lat']},${station['geometry']['location']['lng']}&query_place_id=${widget.placeId}',
    );

    if (!mounted) return;

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not launch Google Maps')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _stationFuture.ignore();
    super.dispose();
  }
}