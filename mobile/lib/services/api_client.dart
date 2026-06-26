import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../config.dart';

class ApiClient {
  String _messageFromResponse(http.Response response) {
    try {
      final payload = jsonDecode(response.body);
      if (payload is Map && payload['message'] != null) {
        return payload['message'].toString();
      }
    } catch (_) {
      // Keep fallback below when backend body is not JSON.
    }
    return response.body;
  }

  Future<List<dynamic>> getSchedules({String? token}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/schedules');
    try {
      final response = await http
          .get(
            url,
            headers: token == null ? {} : {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Impossible de charger les horaires (HTTP ${response.statusCode})',
        );
      }

      return jsonDecode(response.body) as List<dynamic>;
    } on TimeoutException {
      throw Exception('Delai depasse vers $url');
    } on http.ClientException catch (e) {
      throw Exception('Erreur reseau vers $url: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/login');
    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200 && response.statusCode != 201) {
        String details = '';
        try {
          final payload = jsonDecode(response.body);
          if (payload is Map && payload['message'] != null) {
            details = payload['message'].toString();
          }
        } catch (_) {
          details = response.body;
        }

        throw Exception(
          'Connexion impossible (HTTP ${response.statusCode})${details.isNotEmpty ? ': $details' : ''}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw Exception('Delai depasse vers $url');
    } on http.ClientException catch (e) {
      throw Exception('Erreur reseau vers $url: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> book(String scheduleId, String token, [int seatNumber = 1]) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/bookings');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'scheduleId': scheduleId, 'seatNumber': seatNumber}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 201 && response.statusCode != 200) {
        final details = _messageFromResponse(response);
        throw Exception(
          'Reservation impossible (HTTP ${response.statusCode})${details.isNotEmpty ? ': $details' : ''}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw Exception('Delai depasse vers $url');
    } on http.ClientException catch (e) {
      throw Exception('Erreur reseau vers $url: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> me(String token) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/me');
    try {
      final response = await http
          .get(
            url,
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Profil indisponible (HTTP ${response.statusCode}): ${_messageFromResponse(response)}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw Exception('Delai depasse vers $url');
    } on http.ClientException catch (e) {
      throw Exception('Erreur reseau vers $url: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> updateMyAvatar({required String token, String? avatarUrl}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/auth/me/avatar');
    try {
      final response = await http
          .patch(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'avatarUrl': avatarUrl}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Mise a jour photo impossible (HTTP ${response.statusCode}): ${_messageFromResponse(response)}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw Exception('Delai depasse vers $url');
    } on http.ClientException catch (e) {
      throw Exception('Erreur reseau vers $url: ${e.message}');
    }
  }

  Future<List<dynamic>> getMyBookings(String token) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/bookings/mine');
    try {
      final response = await http
          .get(
            url,
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Billets indisponibles (HTTP ${response.statusCode}): ${_messageFromResponse(response)}',
        );
      }

      return jsonDecode(response.body) as List<dynamic>;
    } on TimeoutException {
      throw Exception('Delai depasse vers $url');
    } on http.ClientException catch (e) {
      throw Exception('Erreur reseau vers $url: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> validateQr({required String qrData, required String token}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/bookings/validate-qr');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'qrData': qrData}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Validation QR impossible (HTTP ${response.statusCode}): ${_messageFromResponse(response)}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw Exception('Delai depasse vers $url');
    } on http.ClientException catch (e) {
      throw Exception('Erreur reseau vers $url: ${e.message}');
    }
  }

  Future<Map<String, dynamic>> sendChatMessage({required String token, required String message, String category = 'GENERAL'}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/chat/send');
    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'message': message, 'category': category}),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 201 && response.statusCode != 200) {
        throw Exception(
          'Erreur lors de l\'envoi du message (HTTP ${response.statusCode}): ${_messageFromResponse(response)}',
        );
      }

      return jsonDecode(response.body) as Map<String, dynamic>;
    } on TimeoutException {
      throw Exception('Delai depasse vers $url');
    } on http.ClientException catch (e) {
      throw Exception('Erreur reseau vers $url: ${e.message}');
    }
  }

  Future<List<dynamic>> getChatConversation({required String token}) async {
    final url = Uri.parse('${AppConfig.apiBaseUrl}/chat/conversation');
    try {
      final response = await http
          .get(
            url,
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        throw Exception(
          'Impossible de charger la conversation (HTTP ${response.statusCode}): ${_messageFromResponse(response)}',
        );
      }

      final data = jsonDecode(response.body);
      if (data is Map && data['data'] is List) {
        return data['data'] as List<dynamic>;
      }

      return data is List ? data : <dynamic>[];
    } on TimeoutException {
      throw Exception('Delai depasse vers $url');
    } on http.ClientException catch (e) {
      throw Exception('Erreur reseau vers $url: ${e.message}');
    }
  }
}
