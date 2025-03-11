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