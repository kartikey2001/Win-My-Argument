import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_argument.dart';

enum SortOption {
  newest,
  oldest,
  alphabetical,
  mostRelevant,
}

class LibraryProvider with ChangeNotifier {
  static const String _storageKey = 'saved_arguments';
  List<SavedArgument> _savedArguments = [];
  List<SavedArgument> _filteredArguments = [];
  bool _isLoading = true;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.newest;
  bool _showFavoritesOnly = false;
  Set<String> _selectedTags = {};

  List<SavedArgument> get savedArguments => _filteredArguments;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  SortOption get sortOption => _sortOption;
  bool get showFavoritesOnly => _showFavoritesOnly;
  Set<String> get selectedTags => _selectedTags;

  Set<String> get allTags {
    final tags = <String>{};
    for (final arg in _savedArguments) {
      tags.addAll(arg.tags);
    }
    return tags;
  }

  LibraryProvider() {
    _loadSavedArguments();
  }

  Future<void> _loadSavedArguments() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? savedJson = prefs.getString(_storageKey);

      if (savedJson != null) {
        final List<dynamic> decoded = jsonDecode(savedJson);
        _savedArguments =
            decoded.map((item) => SavedArgument.fromJson(item)).toList();
      }
      _applyFilters();
    } catch (e) {
      debugPrint('Error loading saved arguments: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _applyFilters() {
    var filtered = List<SavedArgument>.from(_savedArguments);

    // Apply search
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((arg) => arg.matches(_searchQuery)).toList();
    }

    // Apply favorites filter
    if (_showFavoritesOnly) {
      filtered = filtered.where((arg) => arg.isFavorite).toList();
    }

    // Apply tags filter
    if (_selectedTags.isNotEmpty) {
      filtered = filtered
          .where((arg) => _selectedTags.every((tag) => arg.tags.contains(tag)))
          .toList();
    }

    // Apply sorting
    switch (_sortOption) {
      case SortOption.newest:
        filtered.sort((a, b) => b.savedAt.compareTo(a.savedAt));
        break;
      case SortOption.oldest:
        filtered.sort((a, b) => a.savedAt.compareTo(b.savedAt));
        break;
      case SortOption.alphabetical:
        filtered.sort((a, b) => a.query.compareTo(b.query));
        break;
      case SortOption.mostRelevant:
        if (_searchQuery.isNotEmpty) {
          filtered.sort((a, b) {
            final aInTitle =
                a.query.toLowerCase().contains(_searchQuery.toLowerCase());
            final bInTitle =
                b.query.toLowerCase().contains(_searchQuery.toLowerCase());
            if (aInTitle && !bInTitle) return -1;
            if (!aInTitle && bInTitle) return 1;
            return 0;
          });
        }
        break;
    }

    _filteredArguments = filtered;
    notifyListeners();
  }

  Future<void> saveArgument(String query, String response) async {
    try {
      final references = _extractReferences(response);
      final argument = SavedArgument(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        query: query,
        response: response,
        savedAt: DateTime.now(),
        references: references,
      );

      _savedArguments.insert(0, argument);
      await _persistArguments();
      _applyFilters();
    } catch (e) {
      debugPrint('Error saving argument: $e');
      rethrow;
    }
  }

  List<String> _extractReferences(String text) {
    try {
      final referenceSection = text.split('References:');
      if (referenceSection.length > 1) {
        return referenceSection[1]
            .trim()
            .split('\n')
            .where((line) => line.isNotEmpty)
            .map((line) => line.trim())
            .where((line) => line.startsWith('['))
            .toList();
      }
    } catch (e) {
      debugPrint('Error extracting references: $e');
    }
    return [];
  }

  Future<void> toggleFavorite(String id) async {
    final index = _savedArguments.indexWhere((arg) => arg.id == id);
    if (index != -1) {
      _savedArguments[index] = _savedArguments[index].copyWith(
        isFavorite: !_savedArguments[index].isFavorite,
      );
      await _persistArguments();
      _applyFilters();
    }
  }

  Future<void> updateTags(String id, List<String> tags) async {
    final index = _savedArguments.indexWhere((arg) => arg.id == id);
    if (index != -1) {
      _savedArguments[index] = _savedArguments[index].copyWith(tags: tags);
      await _persistArguments();
      _applyFilters();
    }
  }

  Future<void> deleteArgument(String id) async {
    try {
      _savedArguments.removeWhere((arg) => arg.id == id);
      await _persistArguments();
      _applyFilters();
    } catch (e) {
      debugPrint('Error deleting argument: $e');
      rethrow;
    }
  }

  Future<void> _persistArguments() async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(
      _savedArguments.map((arg) => arg.toJson()).toList(),
    );
    await prefs.setString(_storageKey, encoded);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    _applyFilters();
  }

  void toggleFavoritesOnly() {
    _showFavoritesOnly = !_showFavoritesOnly;
    _applyFilters();
  }

  void toggleTag(String tag) {
    if (_selectedTags.contains(tag)) {
      _selectedTags.remove(tag);
    } else {
      _selectedTags.add(tag);
    }
    _applyFilters();
  }

  void clearFilters() {
    _searchQuery = '';
    _showFavoritesOnly = false;
    _selectedTags.clear();
    _sortOption = SortOption.newest;
    _applyFilters();
  }

  Future<String> exportLibrary() async {
    final exportData = {
      'version': '1.0',
      'exportDate': DateTime.now().toIso8601String(),
      'arguments': _savedArguments.map((arg) => arg.toJson()).toList(),
    };
    return jsonEncode(exportData);
  }

  Future<void> importLibrary(String jsonData) async {
    try {
      final data = jsonDecode(jsonData);
      if (data['version'] == '1.0') {
        final List<dynamic> arguments = data['arguments'];
        _savedArguments =
            arguments.map((item) => SavedArgument.fromJson(item)).toList();
        await _persistArguments();
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error importing library: $e');
      rethrow;
    }
  }

  Future<String> getShareableText() async {
    final buffer = StringBuffer();
    buffer.writeln('Win My Argument - Exported Library');
    buffer.writeln('Exported on: ${DateTime.now().toLocal()}');
    buffer.writeln('\n---\n');

    for (final arg in _savedArguments) {
      buffer.writeln('Question: ${arg.query}');
      buffer.writeln('Answer: ${arg.response}');
      if (arg.references.isNotEmpty) {
        buffer.writeln('\nReferences:');
        for (final ref in arg.references) {
          buffer.writeln(ref);
        }
      }
      buffer.writeln('\n---\n');
    }

    return buffer.toString();
  }

  // Statistics methods
  Map<String, dynamic> getLibraryStats() {
    return {
      'totalArguments': _savedArguments.length,
      'favorites': _savedArguments.where((arg) => arg.isFavorite).length,
      'totalTags': allTags.length,
      'mostUsedTags': _getMostUsedTags(),
      'oldestArgument': _savedArguments.isEmpty
          ? null
          : _savedArguments
              .reduce((a, b) => a.savedAt.isBefore(b.savedAt) ? a : b)
              .savedAt,
      'newestArgument': _savedArguments.isEmpty
          ? null
          : _savedArguments
              .reduce((a, b) => a.savedAt.isAfter(b.savedAt) ? a : b)
              .savedAt,
    };
  }

  Map<String, int> _getMostUsedTags() {
    final tagCount = <String, int>{};
    for (final arg in _savedArguments) {
      for (final tag in arg.tags) {
        tagCount[tag] = (tagCount[tag] ?? 0) + 1;
      }
    }
    return Map.fromEntries(tagCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(5));
  }

  // Batch operations
  Future<void> deleteMultiple(List<String> ids) async {
    _savedArguments.removeWhere((arg) => ids.contains(arg.id));
    await _persistArguments();
    _applyFilters();
  }

  Future<void> addTagToMultiple(List<String> ids, String tag) async {
    for (final id in ids) {
      final index = _savedArguments.indexWhere((arg) => arg.id == id);
      if (index != -1) {
        final currentTags = List<String>.from(_savedArguments[index].tags);
        if (!currentTags.contains(tag)) {
          currentTags.add(tag);
          _savedArguments[index] =
              _savedArguments[index].copyWith(tags: currentTags);
        }
      }
    }
    await _persistArguments();
    _applyFilters();
  }

  Future<void> removeTagFromMultiple(List<String> ids, String tag) async {
    for (final id in ids) {
      final index = _savedArguments.indexWhere((arg) => arg.id == id);
      if (index != -1) {
        final currentTags = List<String>.from(_savedArguments[index].tags);
        currentTags.remove(tag);
        _savedArguments[index] =
            _savedArguments[index].copyWith(tags: currentTags);
      }
    }
    await _persistArguments();
    _applyFilters();
  }

  // Backup and Restore
  Future<Map<String, dynamic>> createBackup() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'data': {
        _storageKey: prefs.getString(_storageKey),
      }
    };
  }

  Future<void> restoreBackup(Map<String, dynamic> backup) async {
    try {
      if (backup['version'] != '1.0') throw 'Unsupported backup version';

      final prefs = await SharedPreferences.getInstance();
      final data = backup['data'] as Map<String, dynamic>;

      if (data.containsKey(_storageKey)) {
        await prefs.setString(_storageKey, data[_storageKey]);
        await _loadSavedArguments();
      }
    } catch (e) {
      debugPrint('Error restoring backup: $e');
      rethrow;
    }
  }

  // Merge libraries
  Future<void> mergeLibrary(String jsonData) async {
    try {
      final data = jsonDecode(jsonData);
      if (data['version'] == '1.0') {
        final List<dynamic> arguments = data['arguments'];
        final newArguments =
            arguments.map((item) => SavedArgument.fromJson(item)).toList();

        // Merge strategy: keep existing if ID conflicts
        for (final newArg in newArguments) {
          if (!_savedArguments.any((arg) => arg.id == newArg.id)) {
            _savedArguments.add(newArg);
          }
        }

        await _persistArguments();
        _applyFilters();
      }
    } catch (e) {
      debugPrint('Error merging library: $e');
      rethrow;
    }
  }
}
