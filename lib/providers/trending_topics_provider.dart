import 'package:flutter/material.dart';

class TrendingTopicsProvider extends ChangeNotifier {
  final List<String> _trendingTopics = [
    'Climate change impact on biodiversity',
    'Artificial intelligence ethics',
    'Quantum computing applications',
    'Renewable energy technologies',
    'Space exploration benefits',
    'Genetic engineering debates',
    'Neuroscience breakthroughs',
    'Sustainable agriculture',
    'Cybersecurity challenges',
    'Public health policies',
  ];

  List<String> get trendingTopics => _trendingTopics;

  // In a real app, this would fetch from an API
  Future<void> refreshTopics() async {
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    notifyListeners();
  }
}
