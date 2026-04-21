import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Singleton so token is shared across all services
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String baseUrl = 'http://192.168.100.2:3000'; // Computer's LAN IP for physical device

  String? _token;

  void setToken(String token) {
    _token = token;
    debugPrint('[ApiService] Token set: ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
  }

  String? get token => _token;

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    debugPrint('[ApiService] POST $endpoint | hasToken: ${_token != null}');
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          if (_token != null) 'Authorization': 'Bearer $_token',
        },
        body: jsonEncode(body),
      );
      debugPrint('[ApiService] POST $endpoint => ${response.statusCode}');
      return response;
    } catch (e) {
      debugPrint('[ApiService] POST $endpoint ERROR: $e');
      rethrow;
    }
  }

  Future<http.Response> get(String endpoint) async {
    debugPrint('[ApiService] GET $endpoint | hasToken: ${_token != null}');
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
    );
    return response;
  }
}
