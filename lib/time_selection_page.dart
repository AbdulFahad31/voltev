import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'google_maps_service.dart';
import 'station_data.dart';

class TimeSelectionPage extends StatefulWidget {
  final String placeId;
  final String stationName;
  final String slotType; // 'AC' or 'DC'
  final int pricePerKwh;
  final int serviceCharge;
  final double latitude;
  final double longitude;

  const TimeSelectionPage({
    super.key,
    required this.placeId,
    required this.stationName,
    required this.slotType,
    required this.pricePerKwh,
    required this.serviceCharge,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<TimeSelectionPage> createState() => _TimeSelectionPageState();
}

class _TimeSelectionPageState extends State<TimeSelectionPage> {
  final Color primaryColor = const Color(0xFF103050);
  String? _selectedVehicle;
  TimeOfDay? _selectedStartTime;
  int _selectedDuration = 1;
  String? _selectedConnectorType;
  List<String> _connectorTypes = ['CCS2', 'Type 2', 'CHAdeMO'];
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _fetchConnectorTypes();
  }

  Future<void> _fetchConnectorTypes() async {
    try {
      final details = await GoogleMapsService.getPlaceDetails(widget.placeId);
      if (details['types'] != null) {
        setState(() {
          _connectorTypes = List<String>.from(details['types'])
              .where((type) => type.contains('charging'))
              .map((type) => type.replaceAll('_', ' ').toUpperCase())
              .toList();
          if (_connectorTypes.isEmpty) {
            _connectorTypes = ['CCS2', 'Type 2', 'CHAdeMO'];
          }
          _selectedConnectorType = _connectorTypes.first;
        });
      }
    } catch (e) {
      setState(() {
        _selectedConnectorType = _connectorTypes.first;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = (widget.pricePerKwh * _selectedDuration) + widget.serviceCharge;
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Time'),
        backgroundColor: primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Station Info
            Text(
              widget.stationName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Charging Type: ${widget.slotType} (₹${widget.pricePerKwh}/kWh)',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),

            // Price Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price Estimate',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildPriceRow('Energy Cost', '₹${widget.pricePerKwh} × $_selectedDuration hour(s)'),
                    _buildPriceRow('Service Charge', '₹${widget.serviceCharge}'),
                    const Divider(),
                    _buildPriceRow('Total', '₹$totalPrice', isTotal: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Connector Type Selection
            Text(
              'Connector Type',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedConnectorType,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select connector type',
              ),
              items: _connectorTypes.map((type) {
                return DropdownMenuItem<String>(
                  value: type,
                  child: Text(type),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedConnectorType = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Vehicle Selection
            Text(
              'Vehicle Selection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedVehicle,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Select your vehicle',
              ),
              items: StationData.vehicles.map((vehicle) {
                return DropdownMenuItem<String>(
                  value: vehicle,
                  child: Text(vehicle),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedVehicle = value;
                });
              },
            ),
            const SizedBox(height: 24),

            // Time Selection
            Text(
              'Select Start Time',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              title: Text(
                _selectedStartTime == null
                    ? 'Select time'
                    : _selectedStartTime!.format(context),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                if (time != null) {
                  setState(() {
                    _selectedStartTime = time;
                  });
                }
              },
            ),
            const SizedBox(height: 24),

            // Duration Selection
            Text(
              'Select Duration (hours)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _selectedDuration.toDouble(),
              min: 1,
              max: 8,
              divisions: 7,
              label: '$_selectedDuration hour${_selectedDuration > 1 ? 's' : ''}',
              onChanged: (value) {
                setState(() {
                  _selectedDuration = value.toInt();
                });
              },
            ),
            const SizedBox(height: 24),

            // Confirm Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                minimumSize: const Size(double.infinity, 50),
              ),
              onPressed: _isProcessing ? null : () => _confirmBooking(context, totalPrice),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                'CONFIRM BOOKING',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 16 : 14,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmBooking(BuildContext context, int totalPrice) async {
    if (_selectedStartTime == null || _selectedVehicle == null || _selectedConnectorType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select all required fields')),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      // Combine the selected time with today's date
      final startTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        _selectedStartTime!.hour,
        _selectedStartTime!.minute,
      );

      // Navigate to payment page
      Navigator.pushNamed(
        context,
        '/payment',
        arguments: {
          'stationName': widget.stationName,
          'connectorType': _selectedConnectorType!,
          'slotType': widget.slotType,
          'totalPrice': totalPrice,
          'placeId': widget.placeId,
          'latitude': widget.latitude,
          'longitude': widget.longitude,
          'vehicle': _selectedVehicle!,
          'startTime': startTime,
          'duration': _selectedDuration,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
}