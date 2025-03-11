import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;
  static const String _apiKeyParam = 'groq_api_key';
  static const String _modelParam = 'groq_model';

  static RemoteConfigService? _instance;
  static Future<RemoteConfigService> getInstance() async {
    if (_instance == null) {
      final remoteConfig = FirebaseRemoteConfig.instance;
      await remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1),
      ));

      await remoteConfig.setDefaults({
        _apiKeyParam:
            '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',
        _modelParam: 'llama-3.3-70b-versatile',
      });

      await remoteConfig.fetchAndActivate();
      _instance = RemoteConfigService._(remoteConfig);
    }
    return _instance!;
  }

  RemoteConfigService._(this._remoteConfig);

  String get apiKey => _remoteConfig.getString(_apiKeyParam);
  String get model => _remoteConfig.getString(_modelParam);

  Future<void> fetchAndActivate() async {
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (e) {
      debugPrint('Error fetching remote config: $e');
    }
  }
}
