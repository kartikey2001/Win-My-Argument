import 'dart:convert';

class SavedArgument {
  final String id;
  final String query;
  final String response;
  final DateTime savedAt;
  final List<String> tags;
  final bool isFavorite;
  final List<String> references;

  SavedArgument({
    required this.id,
    required this.query,
    required this.response,
    required this.savedAt,
    this.tags = const [],
    this.isFavorite = false,
    this.references = const [],
  });

  SavedArgument copyWith({
    String? id,
    String? query,
    String? response,
    DateTime? savedAt,
    List<String>? tags,
    bool? isFavorite,
    List<String>? references,
  }) {
    return SavedArgument(
      id: id ?? this.id,
      query: query ?? this.query,
      response: response ?? this.response,
      savedAt: savedAt ?? this.savedAt,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      references: references ?? this.references,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'query': query,
      'response': response,
      'savedAt': savedAt.toIso8601String(),
      'tags': tags,
      'isFavorite': isFavorite,
      'references': references,
    };
  }

  factory SavedArgument.fromJson(Map<String, dynamic> json) {
    return SavedArgument(
      id: json['id'] as String,
      query: json['query'] as String,
      response: json['response'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      tags: List<String>.from(json['tags'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
      references: List<String>.from(json['references'] ?? []),
    );
  }

  String toShareText() {
    final buffer = StringBuffer();
    buffer.writeln('Question: $query\n');
    buffer.writeln('Answer:\n$response\n');
    if (references.isNotEmpty) {
      buffer.writeln('References:');
      for (final ref in references) {
        buffer.writeln(ref);
      }
    }
    return buffer.toString();
  }

  String get summary {
    final firstLine = response.split('\n').first;
    return firstLine.length > 100
        ? '${firstLine.substring(0, 100)}...'
        : firstLine;
  }

  bool matches(String searchTerm) {
    final term = searchTerm.toLowerCase();
    return query.toLowerCase().contains(term) ||
        response.toLowerCase().contains(term) ||
        tags.any((tag) => tag.toLowerCase().contains(term));
  }
}
