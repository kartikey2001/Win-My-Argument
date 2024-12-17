import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ResultsScreen(query: query),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Win My Argument',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Where knowledge begins',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Ask anything...',
                  suffixIcon: IconButton(
                    icon: const Icon(Iconsax.arrow_right_3),
                    onPressed: _handleSearch,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _handleSearch(),
              ),
              const SizedBox(height: 24),
              const Text(
                'Trending Questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildTrendingQuestion('🧬 What is DNA?'),
                  _buildTrendingQuestion('🌍 Is climate change real?'),
                  _buildTrendingQuestion('🧠 How does memory work?'),
                  _buildTrendingQuestion('🌌 What is dark matter?'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingQuestion(String question) {
    return GestureDetector(
      onTap: () {
        _searchController.text = question.replaceAll(RegExp(r'[^\w\s]'), '');
        _handleSearch();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(question),
      ),
    );
  }
}
