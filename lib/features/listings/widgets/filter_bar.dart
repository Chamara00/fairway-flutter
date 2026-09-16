import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/providers.dart';
import '../../../data/listing_repository.dart';
import '../listings_controller.dart';

class FilterBar extends ConsumerStatefulWidget {
  const FilterBar({super.key});

  @override
  ConsumerState<FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends ConsumerState<FilterBar> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(listingsControllerProvider).search,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(listingsControllerProvider.notifier);
    final state = ref.watch(listingsControllerProvider);

    if (state.search.isEmpty && _searchController.text.isNotEmpty) {
      _searchController.clear();
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.pad,
        8,
        AppTheme.pad,
        AppTheme.gap,
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: controller.onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search listings',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radius),
                borderSide: BorderSide.none,
              ),
              suffixIcon: state.search.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear search',
                      onPressed: () {
                        _searchController.clear();
                        controller.onSearchChanged('');
                      },
                    ),
            ),
          ),
          const SizedBox(height: AppTheme.gap),
          Row(
            children: [
              Expanded(child: _CategoryFilter(state: state)),
              const SizedBox(width: AppTheme.gap),
              _SortMenu(state: state),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter({required this.state});

  final ListingsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final controller = ref.read(listingsControllerProvider.notifier);
    final searching = state.search.isNotEmpty;

    return categories.when(
      loading: () => const _FilterShell(child: Text('Loading categories...')),
      error: (_, __) =>
          const _FilterShell(child: Text('Categories unavailable')),
      data: (items) => _FilterShell(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String?>(
            value: state.category,
            isExpanded: true,
            isDense: true,
            hint: Text(
              searching ? 'Not available while searching' : 'All categories',
            ),
            onChanged: searching ? null : controller.onCategoryChanged,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All categories'),
              ),
              ...items.map(
                (c) => DropdownMenuItem<String?>(
                  value: c,
                  child: Text(_label(c), overflow: TextOverflow.ellipsis),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _label(String slug) {
    final words = slug.replaceAll('-', ' ');
    return words[0].toUpperCase() + words.substring(1);
  }
}

class _SortMenu extends ConsumerWidget {
  const _SortMenu({required this.state});

  final ListingsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(listingsControllerProvider.notifier);
    final active = state.sort != PriceSort.none;

    return _FilterShell(
      child: PopupMenuButton<PriceSort>(
        initialValue: state.sort,
        onSelected: controller.onSortChanged,
        tooltip: 'Sort by price',
        itemBuilder: (_) => PriceSort.values
            .map((s) => PopupMenuItem(value: s, child: Text(s.label)))
            .toList(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.sort : Icons.sort_outlined,
              size: 18,
              color: active ? Theme.of(context).colorScheme.primary : null,
            ),
            const SizedBox(width: 6),
            Text(
              state.sort == PriceSort.none ? 'Sort' : state.sort.label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterShell extends StatelessWidget {
  const _FilterShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppTheme.radius),
      ),
      child: child,
    );
  }
}
