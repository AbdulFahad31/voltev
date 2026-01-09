class Booking {
  final String id;
  final String stationName;
  final String connectorType;
  final String slotType;
  final String vehicle;
  final DateTime startTime;
  final int duration;
  final int totalPrice;
  final String paymentMethod;
  final DateTime bookingTime;
  final String placeId;
  final double latitude;
  final double longitude;
  final String status; // 'Upcoming', 'Completed', 'Cancelled'

  Booking({
    required this.id,
    required this.stationName,
    required this.connectorType,
    required this.slotType,
    required this.vehicle,
    required this.startTime,
    required this.duration,
    required this.totalPrice,
    required this.paymentMethod,
    required this.placeId,
    required this.latitude,
    required this.longitude,
    this.status = 'Upcoming',
    DateTime? bookingTime,
  }) : bookingTime = bookingTime ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'stationName': stationName,
      'connectorType': connectorType,
      'slotType': slotType,
      'vehicle': vehicle,
      'startTime': startTime.toIso8601String(),
      'duration': duration,
      'totalPrice': totalPrice,
      'paymentMethod': paymentMethod,
      'bookingTime': bookingTime.toIso8601String(),
      'placeId': placeId,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
    };
  }

  factory Booking.fromMap(Map<String, dynamic> map) {
    return Booking(
      id: map['id'],
      stationName: map['stationName'],
      connectorType: map['connectorType'],
      slotType: map['slotType'],
      vehicle: map['vehicle'],
      startTime: DateTime.parse(map['startTime']),
      duration: map['duration'],
      totalPrice: map['totalPrice'],
      paymentMethod: map['paymentMethod'],
      placeId: map['placeId'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      status: map['status'],
      bookingTime: DateTime.parse(map['bookingTime']),
    );
  }
}