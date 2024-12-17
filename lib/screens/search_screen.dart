import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import '../providers/search_history_provider.dart';
import '../providers/trending_topics_provider.dart';
import 'results_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showClear = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _showClear = _searchController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    if (query.trim().isEmpty) return;

    // Add to search history
    context.read<SearchHistoryProvider>().addSearch(query);

    // Navigate to results
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsScreen(query: query),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: theme.colorScheme.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search any argument...',
                  hintStyle: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6)),
                  prefixIcon: Icon(Iconsax.search_normal,
                      color: theme.colorScheme.onSurface),
                  suffixIcon: _showClear
                      ? IconButton(
                          icon: Icon(Iconsax.close_circle,
                              color: theme.colorScheme.onSurface),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: _onSearch,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSearchHistory(),
                    const SizedBox(height: 16),
                    _buildTrendingTopics(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHistory() {
    return Consumer<SearchHistoryProvider>(
      builder: (context, provider, child) {
        if (provider.searchHistory.isEmpty) return const SizedBox.shrink();

        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Searches',
                    style: TextStyle(
                      color: theme.colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextButton(
                    onPressed: () => provider.clearHistory(),
                    child: Text(
                      'Clear All',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: provider.searchHistory.length,
              itemBuilder: (context, index) {
                final query = provider.searchHistory[index];
                return Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(Iconsax.clock,
                        color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    title: Text(
                      query,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    trailing: IconButton(
                      icon: Icon(Iconsax.close_circle,
                          color: theme.colorScheme.onSurface.withOpacity(0.7)),
                      onPressed: () => provider.removeSearch(query),
                    ),
                    onTap: () => _onSearch(query),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrendingTopics() {
    return Consumer<TrendingTopicsProvider>(
      builder: (context, provider, child) {
        final theme = Theme.of(context);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Trending Topics',
                    style: TextStyle(
                      color: theme.colorScheme.onBackground,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Iconsax.refresh,
                        color: theme.colorScheme.onSurface.withOpacity(0.7)),
                    onPressed: () => provider.refreshTopics(),
                  ),
                ],
              ),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.trendingTopics.map((topic) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ActionChip(
                    backgroundColor: theme.colorScheme.surface,
                    side: BorderSide.none,
                    label: Text(
                      topic,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    onPressed: () => _onSearch(topic),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}
