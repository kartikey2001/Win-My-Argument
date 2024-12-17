import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../providers/library_provider.dart';
import '../widgets/argument_card.dart';
import '../widgets/library_filters.dart';
import 'package:timeago/timeago.dart' as timeago;

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilters(LibraryProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LibraryFilters(
        provider: provider,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  void _shareArgument(BuildContext context, String text) {
    Share.share(text, subject: 'Shared from Win My Argument');
  }

  void _showExportImportOptions(
      BuildContext context, LibraryProvider provider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.export),
              title: const Text('Export Library'),
              onTap: () async {
                Navigator.pop(context);
                final jsonData = await provider.exportLibrary();
                final text = await provider.getShareableText();
                Share.share(text, subject: 'Win My Argument Library Export');
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.import),
              title: const Text('Import Library'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.custom,
                    allowedExtensions: ['json', 'txt'],
                  );

                  if (result != null) {
                    final file = File(result.files.single.path!);
                    final contents = await file.readAsString();
                    await provider.importLibrary(contents);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Library imported successfully')),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error importing library: $e')),
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showStats(BuildContext context, LibraryProvider provider) {
    final stats = provider.getLibraryStats();
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Library Statistics', style: theme.textTheme.titleLarge),
            const SizedBox(height: 20),
            _buildStatRow('Total Arguments', '${stats['totalArguments']}'),
            _buildStatRow('Favorites', '${stats['favorites']}'),
            _buildStatRow('Total Tags', '${stats['totalTags']}'),
            if (stats['oldestArgument'] != null)
              _buildStatRow(
                  'Oldest Argument', timeago.format(stats['oldestArgument'])),
            if (stats['newestArgument'] != null)
              _buildStatRow(
                  'Newest Argument', timeago.format(stats['newestArgument'])),
            if ((stats['mostUsedTags'] as Map<String, int>).isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Most Used Tags', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: (stats['mostUsedTags'] as Map<String, int>)
                    .entries
                    .map((e) => Chip(
                          label: Text('${e.key} (${e.value})'),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<LibraryProvider>(
      builder: (context, libraryProvider, child) {
        if (libraryProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (!_showSearch) ...[
                        Text(
                          'Library',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Iconsax.chart),
                          onPressed: () => _showStats(context, libraryProvider),
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.search_normal),
                          onPressed: () => setState(() => _showSearch = true),
                        ),
                        IconButton(
                          icon: const Icon(Iconsax.export_1),
                          onPressed: () => _showExportImportOptions(
                              context, libraryProvider),
                        ),
                      ] else ...[
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            decoration: InputDecoration(
                              hintText: 'Search saved arguments...',
                              border: InputBorder.none,
                              prefixIcon: const Icon(Iconsax.search_normal),
                              suffixIcon: IconButton(
                                icon: const Icon(Iconsax.close_circle),
                                onPressed: () {
                                  _searchController.clear();
                                  libraryProvider.setSearchQuery('');
                                  setState(() => _showSearch = false);
                                },
                              ),
                            ),
                            onChanged: libraryProvider.setSearchQuery,
                          ),
                        ),
                      ],
                      IconButton(
                        icon: Stack(
                          children: [
                            const Icon(Iconsax.filter),
                            if (libraryProvider.showFavoritesOnly ||
                                libraryProvider.selectedTags.isNotEmpty ||
                                libraryProvider.sortOption != SortOption.newest)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onPressed: () => _showFilters(libraryProvider),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: libraryProvider.savedArguments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Iconsax.book,
                                size: 64,
                                color:
                                    theme.colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No saved arguments yet',
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your saved arguments will appear here',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onBackground
                                      .withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: libraryProvider.savedArguments.length,
                          itemBuilder: (context, index) {
                            final argument =
                                libraryProvider.savedArguments[index];
                            return ArgumentCard(
                              argument: argument,
                              onDelete: () async {
                                final shouldDelete = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Argument'),
                                    content: const Text(
                                      'Are you sure you want to delete this argument? This action cannot be undone.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Delete'),
                                      ),
                                    ],
                                  ),
                                );

                                if (shouldDelete == true) {
                                  await libraryProvider
                                      .deleteArgument(argument.id);
                                }
                              },
                              onToggleFavorite: () =>
                                  libraryProvider.toggleFavorite(argument.id),
                              onUpdateTags: (tags) =>
                                  libraryProvider.updateTags(argument.id, tags),
                              onShare: () => _shareArgument(
                                  context, argument.toShareText()),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
