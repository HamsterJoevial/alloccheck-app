import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/app_constants.dart';
import '../models/situation.dart';
import '../models/droits_result.dart';

/// Service de calcul des droits CAF via l'Edge Function Supabase
class CalculService {
  final String _baseUrl;
  final String? _authToken;

  CalculService({String? baseUrl, String? authToken})
      : _baseUrl = baseUrl ?? AppConstants.supabaseUrl,
        _authToken = authToken;

  Future<CalculResponse> calculerDroits(Situation situation) async {
    final url = Uri.parse('$_baseUrl/functions/v1/${AppConstants.calculateRightsFunction}');

    final headers = {
      'Content-Type': 'application/json',
      if (_authToken != null) 'Authorization': 'Bearer $_authToken',
    };

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'situation': situation.toJson()}),
    );

    if (response.statusCode != 200) {
      throw CalculException(
        'Erreur de calcul (${response.statusCode})',
        response.body,
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return CalculResponse.fromJson(data);
  }
}

class CalculException implements Exception {
  final String message;
  final String? details;

  CalculException(this.message, [this.details]);

  @override
  String toString() => 'CalculException: $message${details != null ? ' — $details' : ''}';
}
