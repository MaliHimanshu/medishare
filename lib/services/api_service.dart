import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Android Emulator URL
  static const String baseUrl = "http://10.0.2.2:5000/api";

  Future<dynamic> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final response = await http.post(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {
        "Content-Type": "application/json",
      },
      body: jsonEncode(body),
    );

    return jsonDecode(response.body);
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse("$baseUrl/$endpoint"),
      headers: {
        "Content-Type": "application/json",
      },
    );

    return jsonDecode(response.body);
  }
}