import 'dart:convert';
import 'package:http/http.dart' as http;

class LocationService {
  final String apiKey = 'pk.b952536ad093256ea4aca56f038d2b69'; // Replace with your LocationIQ API key

  Future<Map<String, dynamic>> getCoordinates(String address) async {
    final String url = 'https://us1.locationiq.com/v1/search.php?key=$apiKey&q=$address&format=json';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body)[0]; // Get the first result
    } else {
      throw Exception('Failed to load location');
    }
  }
}
