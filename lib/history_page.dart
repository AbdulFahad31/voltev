import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Add this import
import 'booking_model.dart';
import 'booking_history_service.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<Booking>> _bookingsFuture;

  @override
  void initState() {
    super.initState();
    _bookingsFuture = BookingHistoryService.getBookings();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Booking History',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF103050), // App bar color
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<Booking>>(
        future: _bookingsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No bookings found'));
          }

          final bookings = snapshot.data!;
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final booking = bookings[index];
              return _buildBookingCard(booking);
            },
          );
        },
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Card(
      color: const Color(0xFF103050), // Card background color
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Status Chip
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Wrap station name to prevent overflow
                Expanded(
                  child: Text(
                    booking.stationName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white, // White text for contrast
                    ),
                    overflow: TextOverflow.ellipsis, // Ensures it fits inside card
                    maxLines: 1, // Ensures no overflow
                  ),
                ),
                const SizedBox(width: 8), // Space between text and chip
                Chip(
                  label: Text(
                    booking.status,
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(booking.status),
                  visualDensity: VisualDensity.compact, // Makes chip smaller
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Details
            Text('${booking.slotType} (${booking.connectorType})', style: _detailTextStyle()),
            Text('Vehicle: ${booking.vehicle}', style: _detailTextStyle()),
            Text('Date: ${DateFormat('MMM dd, yyyy').format(booking.startTime)}', style: _detailTextStyle()),
            Text('Time: ${DateFormat('hh:mm a').format(booking.startTime)}', style: _detailTextStyle()),
            Text('Duration: ${booking.duration} hour(s)', style: _detailTextStyle()),

            const Divider(color: Colors.white54), // Divider for clarity

            // Total Price & Cancel Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ₹${booking.totalPrice}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                if (booking.status == 'Upcoming')
                  TextButton(
                    onPressed: () => _cancelBooking(booking.id),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                    ),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Style for booking details
  TextStyle _detailTextStyle() {
    return const TextStyle(color: Colors.white70, fontSize: 14);
  }

  // Color for status chip
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Upcoming':
        return Colors.blue;
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Cancel booking function
  Future<void> _cancelBooking(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Booking'),
        content: const Text('Are you sure you want to cancel this booking?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await BookingHistoryService.updateBookingStatus(id, 'Cancelled');
      setState(() {
        _bookingsFuture = BookingHistoryService.getBookings();
      });
    }
  }
}
