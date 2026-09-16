import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_exception.dart';
import '../../core/providers.dart';
import '../../data/models/listing.dart';
import '../../data/models/listing_page.dart';
import '../../data/listing_repository.dart';

class ListingsState {
  const ListingsState({
    this.page = const ListingPage.empty(),
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.isOffline = false,
    this.cachedAt,
    this.search = '',
    this.category,
    this.sort = PriceSort.none,
  });

  final ListingPage page;

  final bool isLoading;

  final bool isLoadingMore;

  final ApiException? error;

  final bool isOffline;
  final DateTime? cachedAt;

  final String search;
  final String? category;
  final PriceSort sort;

  List<Listing> get items => page.items;
  bool get hasMore => page.hasMore;
  bool get isEmpty => !isLoading && error == null && items.isEmpty;

  bool get hasFatalError => error != null && items.isEmpty;

  bool get hasFilters =>
      search.isNotEmpty || category != null || sort != PriceSort.none;

  ListingsState copyWith({
    ListingPage? page,
    bool? isLoading,
    bool? isLoadingMore,
    ApiException? error,
    bool clearError = false,
    bool? isOffline,
    DateTime? cachedAt,
    String? search,
    String? category,
    bool clearCategory = false,
    PriceSort? sort,
  }) {
    return ListingsState(
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      isOffline: isOffline ?? this.isOffline,
      cachedAt: cachedAt ?? this.cachedAt,
      search: search ?? this.search,
      category: clearCategory ? null : (category ?? this.category),
      sort: sort ?? this.sort,
    );
  }
}

class ListingsController extends Notifier<ListingsState> {
  Timer? _debounce;

  int _requestId = 0;

  static const debounceDelay = Duration(milliseconds: 400);

  @override
  ListingsState build() {
    ref.onDispose(() => _debounce?.cancel());
    Future.microtask(load);
    // Starts loading: load() runs a microtask later, and without this the
    // first frame would briefly render the empty state.
    return const ListingsState(isLoading: true);
  }

  ListingRepository get _repo => ref.read(listingRepositoryProvider);

  Future<void> load({bool resetItems = false}) async {
    final id = ++_requestId;
    state = state.copyWith(
      page: resetItems ? const ListingPage.empty() : null,
      isLoading: true,
      clearError: true,
      isOffline: false,
    );

    try {
      final page = await _repo.fetchListings(
        skip: 0,
        search: state.search,
        category: state.category,
        sort: state.sort,
      );
      if (id != _requestId) return; // superseded
      state = state.copyWith(page: page, isLoading: false, isOffline: false);
    } on ApiException catch (e) {
      if (id != _requestId) return;
      _handleLoadFailure(e);
    }
  }

  void _handleLoadFailure(ApiException e) {
    if (e.isOffline && !state.hasFilters) {
      final cached = _repo.cachedListings();
      if (cached != null && cached.items.isNotEmpty) {
        state = state.copyWith(
          page: cached,
          isLoading: false,
          isOffline: true,
          cachedAt: _repo.cacheSavedAt(),
          clearError: true,
        );
        return;
      }
    }
    state = state.copyWith(isLoading: false, error: e, isOffline: e.isOffline);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    if (state.isOffline) return; // cached data has no further pages

    final id = ++_requestId;
    state = state.copyWith(isLoadingMore: true);

    try {
      final next = await _repo.fetchListings(
        skip: state.page.nextSkip,
        search: state.search,
        category: state.category,
        sort: state.sort,
      );
      if (id != _requestId) return;
      state = state.copyWith(
        page: state.page.merge(next),
        isLoadingMore: false,
      );
    } on ApiException catch (e) {
      if (id != _requestId) return;
      state = state.copyWith(isLoadingMore: false, error: e);
    }
  }

  void onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(debounceDelay, () {
      if (value == state.search) return;
      // The API cannot combine a search term with a category, so starting a
      // search clears the category rather than leaving a stale one on screen.
      state = state.copyWith(search: value, clearCategory: value.isNotEmpty);
      load(resetItems: true);
    });
  }

  void onCategoryChanged(String? category) {
    if (category == state.category) return;
    state = state.copyWith(category: category, clearCategory: category == null);
    load(resetItems: true);
  }

  void onSortChanged(PriceSort sort) {
    if (sort == state.sort) return;
    state = state.copyWith(sort: sort);
    load(resetItems: true);
  }

  void clearFilters() {
    _debounce?.cancel();
    state = state.copyWith(
      search: '',
      clearCategory: true,
      sort: PriceSort.none,
    );
    load(resetItems: true);
  }

  Future<void> refresh() => load();

  void removeLocally(int id) {
    final remaining = state.items.where((l) => l.id != id).toList();
    state = state.copyWith(
      page: ListingPage(
        items: remaining,
        total: state.page.total - 1,
        skip: state.page.skip,
        limit: state.page.limit,
      ),
    );
  }
}

final listingsControllerProvider =
    NotifierProvider<ListingsController, ListingsState>(ListingsController.new);
