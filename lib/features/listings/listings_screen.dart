import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../shared/async_view.dart';
import 'listings_controller.dart';
import 'widgets/filter_bar.dart';
import 'widgets/listing_card.dart';

class ListingsScreen extends ConsumerStatefulWidget {
  const ListingsScreen({super.key});

  @override
  ConsumerState<ListingsScreen> createState() => _ListingsScreenState();
}

class _ListingsScreenState extends ConsumerState<ListingsScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 400) {
      ref.read(listingsControllerProvider.notifier).loadMore();
    }
  }

  int _columnsFor(double width) {
    if (width >= 1200) return 5;
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listingsControllerProvider);
    final controller = ref.read(listingsControllerProvider.notifier);

    ref.listen(listingsControllerProvider, (previous, next) {
      final error = next.error;
      if (error != null && next.items.isNotEmpty && previous?.error != error) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(error.message),
              action: SnackBarAction(
                label: 'Retry',
                onPressed: controller.loadMore,
              ),
            ),
          );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fairway'),
        actions: [
          if (state.hasFilters)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_outlined),
              tooltip: 'Clear filters',
              onPressed: controller.clearFilters,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.create),
        icon: const Icon(Icons.add),
        label: const Text('Sell'),
      ),
      body: Column(
        children: [
          if (state.isOffline)
            OfflineBanner(cachedAt: state.cachedAt, onRetry: controller.load),
          const FilterBar(),
          Expanded(
            child: _Body(
              state: state,
              controller: controller,
              scrollController: _scrollController,
              columnsFor: _columnsFor,
            ),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.state,
    required this.controller,
    required this.scrollController,
    required this.columnsFor,
  });

  final ListingsState state;
  final ListingsController controller;
  final ScrollController scrollController;
  final int Function(double) columnsFor;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading && state.items.isEmpty) return const LoadingView();

    if (state.hasFatalError) {
      return StatusView.error(error: state.error!, onRetry: controller.load);
    }

    if (state.isEmpty) {
      return StatusView.empty(
        message: state.hasFilters
            ? 'Nothing matches those filters.'
            : 'There is nothing here yet.',
        onRetry: state.hasFilters ? controller.clearFilters : controller.load,
        retryLabel: state.hasFilters ? 'Clear filters' : 'Reload',
      );
    }

    return RefreshIndicator(
      onRefresh: controller.refresh,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final columns = columnsFor(constraints.maxWidth);

          // Fixed tile height: the square image plus the text block.
          final tileWidth =
              (constraints.maxWidth -
                  AppTheme.pad * 2 -
                  AppTheme.gap * (columns - 1)) /
              columns;

          return CustomScrollView(
            controller: scrollController,
            // Keeps pull-to-refresh working even when the list is short.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.pad),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: AppTheme.gap,
                    mainAxisSpacing: AppTheme.gap,
                    mainAxisExtent: tileWidth + 118,
                  ),
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final listing = state.items[index];
                    return ListingCard(
                      listing: listing,
                      onTap: () =>
                          context.push(AppRoutes.listingPath(listing.id)),
                    );
                  },
                ),
              ),
              SliverToBoxAdapter(
                child: state.isLoadingMore
                    ? const LoadMoreIndicator()
                    : const SizedBox(height: 80), // clears the FAB
              ),
            ],
          );
        },
      ),
    );
  }
}
