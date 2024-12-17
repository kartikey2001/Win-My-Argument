import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SearchHistoryProvider extends ChangeNotifier {
  static const String _key = 'search_history';
  final SharedPreferences _prefs;
  List<String> _searchHistory = [];

  SearchHistoryProvider(this._prefs) {
    _loadHistory();
  }

  List<String> get searchHistory => _searchHistory;

  void _loadHistory() {
    final String? historyJson = _prefs.getString(_key);
    if (historyJson != null) {
      _searchHistory = List<String>.from(json.decode(historyJson));
      notifyListeners();
    }
  }

  Future<void> addSearch(String query) async {
    if (query.trim().isEmpty) return;

    // Remove if exists and add to front
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);

    // Keep only last 10 searches
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }

    await _prefs.setString(_key, json.encode(_searchHistory));
    notifyListeners();
  }

  Future<void> removeSearch(String query) async {
    _searchHistory.remove(query);
    await _prefs.setString(_key, json.encode(_searchHistory));
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _searchHistory.clear();
    await _prefs.remove(_key);
    notifyListeners();
  }
}
