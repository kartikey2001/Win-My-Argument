import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/ai_provider.dart';
import 'package:flutter_tts/flutter_tts.dart';

class ArgumentScreen extends StatefulWidget {
  final String query;

  const ArgumentScreen({super.key, required this.query});

  @override
  State<ArgumentScreen> createState() => _ArgumentScreenState();
}

class _ArgumentScreenState extends State<ArgumentScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AIProvider>().getArgumentResponse(widget.query);
    });
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  Future<void> _toggleSpeech(String text) async {
    if (_isSpeaking) {
      await _flutterTts.stop();
      setState(() => _isSpeaking = false);
    } else {
      await _flutterTts.speak(text);
      setState(() => _isSpeaking = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.bookmark),
            onPressed: () {
              // TODO: Implement save to library
            },
          ),
        ],
      ),
      body: Consumer<AIProvider>(
        builder: (context, aiProvider, child) {
          if (aiProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (aiProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${aiProvider.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      aiProvider.getArgumentResponse(widget.query);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final response = aiProvider.currentResponse;
          if (response == null) {
            return const Center(
              child: Text('No response available'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.query,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    const Text('Sources'),
                    const Spacer(),
                    IconButton(
                      icon: Icon(
                        _isSpeaking ? Iconsax.pause : Iconsax.volume_high,
                      ),
                      onPressed: () => _toggleSpeech(response),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(response),
                  ),
                ),
                if (aiProvider.relatedQuestions.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Related Questions',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  ...aiProvider.relatedQuestions.map((question) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(question),
                        trailing: const Icon(Iconsax.arrow_right_3),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ArgumentScreen(
                                query: question,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
