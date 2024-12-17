import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../models/saved_argument.dart';
import '../screens/results_screen.dart';

class ArgumentCard extends StatelessWidget {
  final SavedArgument argument;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final Function(List<String>) onUpdateTags;
  final VoidCallback onShare;

  const ArgumentCard({
    super.key,
    required this.argument,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.onUpdateTags,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ResultsScreen(
                query: argument.query,
                initialResponse: argument.response,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      argument.query,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      argument.isFavorite ? Iconsax.heart5 : Iconsax.heart,
                      color: argument.isFavorite ? Colors.red : null,
                    ),
                    onPressed: onToggleFavorite,
                  ),
                  PopupMenuButton(
                    icon: const Icon(Iconsax.more),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        onTap: () => _showTagsDialog(context),
                        child: const Row(
                          children: [
                            Icon(Iconsax.tag),
                            SizedBox(width: 8),
                            Text('Edit Tags'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: onShare,
                        child: const Row(
                          children: [
                            Icon(Iconsax.share),
                            SizedBox(width: 8),
                            Text('Share'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        onTap: onDelete,
                        child: Row(
                          children: [
                            Icon(Iconsax.trash, color: theme.colorScheme.error),
                            const SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                argument.summary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              if (argument.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: argument.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Iconsax.clock,
                    size: 16,
                    color: theme.colorScheme.onSurface.withOpacity(0.5),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeago.format(argument.savedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(width: 16),
                  if (argument.references.isNotEmpty) ...[
                    Icon(
                      Iconsax.book,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${argument.references.length} sources',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTagsDialog(BuildContext context) {
    final controller = TextEditingController();
    final currentTags = List<String>.from(argument.tags);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Tags'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Add tag and press Enter',
                  suffixIcon: Icon(Iconsax.tag),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty && !currentTags.contains(value)) {
                    currentTags.add(value);
                    controller.clear();
                    (context as Element).markNeedsBuild();
                  }
                },
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: currentTags.map((tag) {
                  return Chip(
                    label: Text(tag),
                    onDeleted: () {
                      currentTags.remove(tag);
                      (context as Element).markNeedsBuild();
                    },
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                onUpdateTags(currentTags);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
