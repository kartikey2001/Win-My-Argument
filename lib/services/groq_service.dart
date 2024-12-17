import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'remote_config_service.dart';

class GroqService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';
  late RemoteConfigService _remoteConfig;
  bool _isInitialized = false;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      _remoteConfig = await RemoteConfigService.getInstance();
      _isInitialized = true;
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is http.ClientException) {
      return 'Unable to connect to the service. Please check your internet connection.';
    } else if (error.toString().contains('SocketException')) {
      return 'Network connection error. Please check your internet connection and try again.';
    } else if (error.toString().contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else {
      // Generic error message for other cases
      return 'An error occurred while processing your request. Please try again later.';
    }
  }

  Future<Map<String, dynamic>> getResponse(String query) async {
    await _ensureInitialized();
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${_remoteConfig.apiKey}',
        },
        body: jsonEncode({
          'model': _remoteConfig.model,
          'messages': [
            {
              'role': 'system',
              'content':
                  '''You are a research assistant helping to win arguments with factual information. 
              Your responses should:
              1. Be based on scientific research and academic papers
              2. Include citations and references
              3. Present balanced viewpoints while highlighting the strongest evidence-based position
              4. Use clear, concise language
              5. Focus on facts rather than opinions'''
            },
            {
              'role': 'user',
              'content': query,
            }
          ],
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Log the actual error for debugging (only in debug mode)
        if (kDebugMode) {
          print('API Error: ${response.statusCode} - ${response.body}');
        }
        throw 'Failed to get response. Please try again later.';
      }
    } catch (e) {
      // Log the actual error for debugging (only in debug mode)
      if (kDebugMode) {
        print('Error in getResponse: $e');
      }
      throw _getErrorMessage(e);
    }
  }
}
