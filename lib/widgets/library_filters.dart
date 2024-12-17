import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import '../providers/library_provider.dart';

class LibraryFilters extends StatelessWidget {
  final LibraryProvider provider;
  final VoidCallback onClose;

  const LibraryFilters({
    super.key,
    required this.provider,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filters',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: onClose,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Sort by',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SortOption.values.map((option) {
              final isSelected = provider.sortOption == option;
              return FilterChip(
                selected: isSelected,
                label: Text(_getSortLabel(option)),
                onSelected: (_) => provider.setSortOption(option),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Text(
                'Show favorites only',
                style: theme.textTheme.titleMedium,
              ),
              const Spacer(),
              Switch(
                value: provider.showFavoritesOnly,
                onChanged: (_) => provider.toggleFavoritesOnly(),
              ),
            ],
          ),
          if (provider.allTags.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Tags',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: provider.allTags.map((tag) {
                final isSelected = provider.selectedTags.contains(tag);
                return FilterChip(
                  selected: isSelected,
                  label: Text(tag),
                  onSelected: (_) => provider.toggleTag(tag),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: provider.clearFilters,
              icon: const Icon(Iconsax.filter_remove),
              label: const Text('Clear All Filters'),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel(SortOption option) {
    switch (option) {
      case SortOption.newest:
        return 'Newest First';
      case SortOption.oldest:
        return 'Oldest First';
      case SortOption.alphabetical:
        return 'A to Z';
      case SortOption.mostRelevant:
        return 'Most Relevant';
    }
  }
}
