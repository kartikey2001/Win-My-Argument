import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../services/groq_service.dart';
import '../providers/library_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:url_launcher/url_launcher.dart';

class ResultsScreen extends StatefulWidget {
  final String query;
  final String? initialResponse;

  const ResultsScreen({
    super.key,
    required this.query,
    this.initialResponse,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final GroqService _groqService = GroqService();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isLoading = false;
  bool _isLoadingRelated = false;
  bool _isSpeaking = false;
  bool _isSaved = false;
  bool _isExpanded = false;
  bool _isSourcesExpanded = false;
  String? _response;
  String? _error;
  List<String> _references = [];
  List<String> _relatedQuestions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialResponse != null) {
      _response = widget.initialResponse;
      _extractReferences(_response!);
      _getRelatedQuestions();
    } else {
      _getResponse();
    }
  }

  Future<void> _getRelatedQuestions() async {
    try {
      setState(() => _isLoadingRelated = true);

      final relatedResponse = await _groqService.getResponse(
        "Generate 5 scientific questions about ${widget.query}. Return only the questions, one per line, no numbering or additional text.",
      );
      final relatedContent =
          relatedResponse['choices'][0]['message']['content'] as String;

      setState(() {
        _relatedQuestions = relatedContent
            .split('\n')
            .where((line) => line.trim().isNotEmpty)
            .map((line) => line.replaceAll(RegExp(r'^[^a-zA-Z]*'), '').trim())
            .where((line) => line.isNotEmpty)
            .take(5)
            .toList();
        _isLoadingRelated = false;
      });
    } catch (e) {
      debugPrint('Error loading related questions: $e');
      setState(() => _isLoadingRelated = false);
    }
  }

  Future<void> _getResponse() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await _groqService.getResponse(widget.query);
      final content = response['choices'][0]['message']['content'] as String;

      setState(() {
        _response = content;
        _extractReferences(content);
        _isLoading = false;
      });

      // Get related questions after main response
      _getRelatedQuestions();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _extractReferences(String text) {
    try {
      final refRegex = RegExp(r'\[\d+\]');
      final refs =
          refRegex.allMatches(text).map((m) => m.group(0) ?? '').toList();

      final referenceSection = text.split('References:');
      if (referenceSection.length > 1) {
        _references = referenceSection[1]
            .trim()
            .split('\n')
            .where((line) => line.isNotEmpty)
            .map((line) => line.trim())
            .where((line) => line.startsWith('['))
            .toList();
      }
    } catch (e) {
      debugPrint('Error extracting references: $e');
      _references = [];
    }
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeech() async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else if (_response != null) {
      await _flutterTts.speak(_response!);
      setState(() => _isSpeaking = true);
    }
  }

  Future<void> _toggleSave() async {
    if (_response == null) return;

    final libraryProvider = context.read<LibraryProvider>();
    try {
      await libraryProvider.saveArgument(widget.query, _response!);
      setState(() => _isSaved = true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved to library'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _launchScholarSearch(String query) async {
    final url = Uri.parse(
        'https://scholar.google.com/scholar?q=${Uri.encodeComponent(query)}');
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open Google Scholar')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Scholar')),
        );
      }
    }
  }

  Widget _buildReferenceChip(String ref) {
    final number = RegExp(r'\[(\d+)\]').firstMatch(ref)?.group(1);
    return ActionChip(
      backgroundColor: Colors.grey[800],
      side: BorderSide.none,
      label: Text(
        '[$number]',
        style: const TextStyle(color: Colors.white),
      ),
      onPressed: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.grey[900],
          builder: (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Reference',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  ref,
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _launchScholarSearch(ref);
                      },
                      icon: const Icon(Iconsax.search_normal),
                      label: const Text('Search'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmerQuestions() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Related Questions',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onBackground,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(
          5,
          (index) => Shimmer.fromColors(
            baseColor: isDark ? Colors.grey[800]! : Colors.grey[300]!,
            highlightColor: isDark ? Colors.grey[700]! : Colors.grey[100]!,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        leading: IconButton(
          icon: Icon(Iconsax.arrow_left, color: theme.colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.query,
          style: TextStyle(color: theme.colorScheme.onBackground),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isSaved ? Iconsax.bookmark : Iconsax.bookmark_2,
              color: theme.colorScheme.onBackground,
            ),
            onPressed: _toggleSave,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Error: $_error',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _getResponse,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sources and Controls
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InkWell(
                              onTap: () => setState(() =>
                                  _isSourcesExpanded = !_isSourcesExpanded),
                              child: Row(
                                children: [
                                  Icon(Iconsax.book,
                                      color: theme.colorScheme.onSurface),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Sources',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    _isSourcesExpanded
                                        ? Iconsax.arrow_up_2
                                        : Iconsax.arrow_down_2,
                                    color: theme.colorScheme.onSurface,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                            if (_isSourcesExpanded &&
                                _references.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _references
                                    .map((ref) => _buildReferenceChip(ref))
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Main Response
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Answer',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    _isSpeaking
                                        ? Iconsax.pause
                                        : Iconsax.volume_high,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  onPressed: _toggleSpeech,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _response?.split('\n\nReferences:')[0] ?? '',
                              maxLines: _isExpanded ? null : 10,
                              overflow: _isExpanded ? null : TextOverflow.fade,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 15,
                              ),
                            ),
                            if (!_isExpanded) ...[
                              const SizedBox(height: 8),
                              Center(
                                child: TextButton.icon(
                                  onPressed: () =>
                                      setState(() => _isExpanded = true),
                                  icon: Icon(
                                    Iconsax.arrow_down_1,
                                    color: theme.colorScheme.onSurface
                                        .withOpacity(0.7),
                                  ),
                                  label: Text(
                                    'Read more',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.7),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Related Questions
                      if (_isLoadingRelated)
                        _buildShimmerQuestions()
                      else if (_relatedQuestions.isNotEmpty) ...[
                        Text(
                          'Related Questions',
                          style: TextStyle(
                            color: theme.colorScheme.onBackground,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List.generate(
                          _relatedQuestions.length,
                          (index) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(12),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ResultsScreen(
                                        query: _relatedQuestions[index],
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                    horizontal: 16,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          _relatedQuestions[index],
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        Iconsax.arrow_right_3,
                                        size: 16,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
    );
  }
}
