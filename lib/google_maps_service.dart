import 'dart:convert';
import 'package:http/http.dart' as http;

class GoogleMapsService {
  static const String _apiKey = 'AIzaSyDJJdfZ_OfyYWCBcifXE2VHjpqeq-Q5cbU';
  static String get apiKey => _apiKey; // Add this getter

  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  static Future<Map<String, dynamic>> getPlaceDetails(String placeId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/details/json?place_id=$placeId&key=$_apiKey'),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body)['result'];
    } else {
      throw Exception('Failed to load place details');
    }
  }

  static Future<List<Map<String, dynamic>>> findNearbyChargingStations(
      double lat, double lng, int radius) async {
    final response = await http.get(
      Uri.parse(
          '$_baseUrl/nearbysearch/json?location=$lat,$lng&radius=$radius&type=electric_vehicle_charging_station&key=$_apiKey'),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data['results']);
    } else {
      throw Exception('Failed to load charging stations');
    }
  }
}