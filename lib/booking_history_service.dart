import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'booking_model.dart';

class BookingHistoryService {
  static const String _bookingsKey = 'ev_charging_bookings';
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');

  /// Saves a new booking to local storage
  static Future<void> saveBooking(Booking booking) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> bookings = prefs.getStringList(_bookingsKey) ?? [];

    bookings.add(jsonEncode({
      'id': booking.id,
      'stationName': booking.stationName,
      'connectorType': booking.connectorType,
      'slotType': booking.slotType,
      'vehicle': booking.vehicle,
      'startTime': _dateFormat.format(booking.startTime),
      'duration': booking.duration,
      'totalPrice': booking.totalPrice,
      'paymentMethod': booking.paymentMethod,
      'status': booking.status,
      'placeId': booking.placeId,
      'latitude': booking.latitude,
      'longitude': booking.longitude,
      'bookingTime': _dateFormat.format(booking.bookingTime),
    }));

    await prefs.setStringList(_bookingsKey, bookings);
  }

  /// Retrieves all bookings from local storage
  static Future<List<Booking>> getBookings() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? bookingsJson = prefs.getStringList(_bookingsKey);

    if (bookingsJson == null || bookingsJson.isEmpty) {
      return [];
    }

    return bookingsJson.map((json) {
      final data = jsonDecode(json);
      return Booking(
        id: data['id'],
        stationName: data['stationName'],
        connectorType: data['connectorType'],
        slotType: data['slotType'],
        vehicle: data['vehicle'],
        startTime: _dateFormat.parse(data['startTime']),
        duration: data['duration'],
        totalPrice: data['totalPrice'],
        paymentMethod: data['paymentMethod'],
        status: data['status'],
        placeId: data['placeId'],
        latitude: data['latitude'],
        longitude: data['longitude'],
        bookingTime: _dateFormat.parse(data['bookingTime']),
      );
    }).toList();
  }

  /// Updates the status of a specific booking
  static Future<void> updateBookingStatus(String id, String newStatus) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? bookingsJson = prefs.getStringList(_bookingsKey);

    if (bookingsJson == null) return;

    final updatedBookings = bookingsJson.map((json) {
      final data = jsonDecode(json);
      if (data['id'] == id) {
        data['status'] = newStatus;
        return jsonEncode(data);
      }
      return json;
    }).toList();

    await prefs.setStringList(_bookingsKey, updatedBookings);
  }

  /// Deletes a specific booking
  static Future<void> deleteBooking(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? bookingsJson = prefs.getStringList(_bookingsKey);

    if (bookingsJson == null) return;

    final updatedBookings = bookingsJson.where((json) {
      final data = jsonDecode(json);
      return data['id'] != id;
    }).toList();

    await prefs.setStringList(_bookingsKey, updatedBookings);
  }

  /// Gets bookings filtered by status
  static Future<List<Booking>> getBookingsByStatus(String status) async {
    final allBookings = await getBookings();
    return allBookings.where((booking) => booking.status == status).toList();
  }

  /// Gets upcoming bookings (status = 'Upcoming')
  static Future<List<Booking>> getUpcomingBookings() async {
    return getBookingsByStatus('Upcoming');
  }

  /// Gets completed bookings (status = 'Completed')
  static Future<List<Booking>> getCompletedBookings() async {
    return getBookingsByStatus('Completed');
  }

  /// Gets cancelled bookings (status = 'Cancelled')
  static Future<List<Booking>> getCancelledBookings() async {
    return getBookingsByStatus('Cancelled');
  }

  /// Generates a unique ID for new bookings
  static String generateBookingId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Clears all booking history (for testing/debugging)
  static Future<void> clearAllBookings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_bookingsKey);
  }
}