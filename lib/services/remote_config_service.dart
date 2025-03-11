import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class ApiConfigService {
  static ApiConfigService? _instance;
  
  // Direct API key and model configuration
  static const String _apiKey = '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';
  static const String _model = 'llama-3.3-70b-versatile';

  static ApiConfigService getInstance() {
    instance ??= ApiConfigService.();
    return _instance!;
  }

  ApiConfigService._();

  String get apiKey => _apiKey;
  String get model => _model;
}