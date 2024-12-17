import 'package:flutter/material.dart';
import '../services/groq_service.dart';

class AIProvider with ChangeNotifier {
  final GroqService _groqService = GroqService();
  String? _currentResponse;
  List<String> _relatedQuestions = [];
  bool _isLoading = false;
  String? _error;

  String? get currentResponse => _currentResponse;
  List<String> get relatedQuestions => _relatedQuestions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> getArgumentResponse(String query) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _groqService.getResponse(query);
      _currentResponse = response['choices'][0]['message']['content'];
      _relatedQuestions = [];
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearResponse() {
    _currentResponse = null;
    _relatedQuestions = [];
    _error = null;
    notifyListeners();
  }
}
