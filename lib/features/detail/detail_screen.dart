import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/api_exception.dart';
import '../../data/models/listing.dart';
import '../listings/widgets/listing_card.dart';
import '../shared/async_view.dart';
import 'detail_controller.dart';

class DetailScreen extends ConsumerWidget {
  const DetailScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = ref.watch(listingDetailProvider(id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Listing'),
        actions: [
          if (listing.hasValue)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Delete listing',
              onPressed: () => _confirmDelete(context, ref),
            ),
        ],
      ),
      body: listing.when(
        loading: () => const LoadingView(),
        error: (error, _) => StatusView.error(
          error: error.asApiException,
          onRetry: () => ref.read(listingDetailProvider(id).notifier).retry(),
        ),
        data: (listing) => _Content(listing: listing),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete listing?'),
        content: const Text(
          'This removes the listing from your view. It cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final error = await ref.read(listingDetailProvider(id).notifier).delete();
    if (!context.mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
      return;
    }

    context.go(AppRoutes.listings);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Listing deleted')));
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        _Carousel(images: listing.galleryImages),
        Padding(
          padding: const EdgeInsets.all(AppTheme.pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(listing.title, style: theme.textTheme.titleLarge),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    listing.price.asPrice,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (listing.providedCondition != null) ...[
                    const SizedBox(width: AppTheme.gap),
                    Chip(
                      label: Text(listing.condition),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppTheme.pad),
              Text('Description', style: theme.textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(listing.description, style: theme.textTheme.bodyMedium),
              if (listing.specifications.isNotEmpty) ...[
                const SizedBox(height: AppTheme.pad * 1.5),
                Text('Specifications', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                _SpecTable(specs: listing.specifications),
              ],
            ],
          ),
        ),
        _SimilarItems(category: listing.category, excludeId: listing.id),
        const SizedBox(height: AppTheme.pad),
      ],
    );
  }
}

class _Carousel extends StatefulWidget {
  const _Carousel({required this.images});

  final List<String> images;

  @override
  State<_Carousel> createState() => _CarouselState();
}

class _CarouselState extends State<_Carousel> {
  final _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // A listing created through the API comes back with no images.
    if (widget.images.isEmpty) {
      return Container(
        height: 280,
        color: scheme.surfaceContainerHighest,
        child: Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    return SizedBox(
      height: 280,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          PageView.builder(
            controller: _controller,
            itemCount: widget.images.length,
            onPageChanged: (i) => setState(() => _index = i),
            itemBuilder: (context, i) => CachedNetworkImage(
              imageUrl: widget.images[i],
              fit: BoxFit.contain,
              placeholder: (_, __) =>
                  ColoredBox(color: scheme.surfaceContainerHighest),
              errorWidget: (_, __, ___) => Icon(
                Icons.broken_image_outlined,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          if (widget.images.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  widget.images.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _index ? 18 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _index
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SpecTable extends StatelessWidget {
  const _SpecTable({required this.specs});

  final Map<String, String> specs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: specs.entries.map((e) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 120,
                child: Text(e.key, style: theme.textTheme.bodySmall),
              ),
              Expanded(child: Text(e.value, style: theme.textTheme.bodyMedium)),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SimilarItems extends ConsumerWidget {
  const _SimilarItems({required this.category, required this.excludeId});

  final String category;
  final int excludeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similar = ref.watch(
      similarListingsProvider((category: category, excludeId: excludeId)),
    );

    return similar.maybeWhen(
      // Supplementary content: stay silent while loading or on failure
      // rather than pushing an error into the middle of the page.
      orElse: () => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.pad,
                AppTheme.pad,
                AppTheme.pad,
                AppTheme.gap,
              ),
              child: Text(
                'Similar items',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(
              height: 240,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.pad),
                itemCount: items.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(width: AppTheme.gap),
                itemBuilder: (context, i) => SizedBox(
                  width: 150,
                  child: ListingCard(
                    listing: items[i],
                    // Replace so back returns to the grid, not through a
                    // chain of detail screens.
                    onTap: () => context.pushReplacement(
                      AppRoutes.listingPath(items[i].id),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
