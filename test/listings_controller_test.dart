import 'package:fairway/core/api_exception.dart';
import 'package:fairway/core/providers.dart';
import 'package:fairway/data/listing_repository.dart';
import 'package:fairway/data/models/listing_page.dart';
import 'package:fairway/features/listings/listings_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers.dart';

class MockListingRepository extends Mock implements ListingRepository {}

void main() {
  late MockListingRepository repo;

  // mocktail needs a concrete instance to stand in for any(named: 'sort').
  setUpAll(() => registerFallbackValue(PriceSort.none));

  setUp(() => repo = MockListingRepository());

  /// Container with the repository replaced by a mock: no network, no prefs.
  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [listingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  void stubFetch(ListingPage result) {
    when(
      () => repo.fetchListings(
        skip: any(named: 'skip'),
        search: any(named: 'search'),
        category: any(named: 'category'),
        sort: any(named: 'sort'),
      ),
    ).thenAnswer((_) async => result);
  }

  void stubFailure(ApiException error) {
    when(
      () => repo.fetchListings(
        skip: any(named: 'skip'),
        search: any(named: 'search'),
        category: any(named: 'category'),
        sort: any(named: 'sort'),
      ),
    ).thenThrow(error);
  }

  group('initial load', () {
    test('loads the first page and exposes its items', () async {
      stubFetch(page(count: 20));
      final container = makeContainer();

      // build() kicks off load() in a microtask.
      container.read(listingsControllerProvider);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(listingsControllerProvider);
      expect(state.items, hasLength(20));
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.hasMore, isTrue);
    });

    test('reports empty when the API returns nothing', () async {
      stubFetch(page(count: 0, total: 0));
      final container = makeContainer();

      container.read(listingsControllerProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(listingsControllerProvider).isEmpty, isTrue);
    });
  });

  group('pagination', () {
    test('loadMore appends the next page', () async {
      stubFetch(page(count: 20));
      final container = makeContainer();
      container.read(listingsControllerProvider);
      await Future<void>.delayed(Duration.zero);

      stubFetch(page(count: 20, skip: 20, startId: 21));
      await container.read(listingsControllerProvider.notifier).loadMore();

      final state = container.read(listingsControllerProvider);
      expect(state.items, hasLength(40));
      expect(state.items.last.id, 40);
    });

    test('loadMore does nothing once every item is loaded', () async {
      stubFetch(page(count: 20, total: 20));
      final container = makeContainer();
      container.read(listingsControllerProvider);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(listingsControllerProvider).hasMore, isFalse);

      await container.read(listingsControllerProvider.notifier).loadMore();

      // Still only the single initial call.
      verify(
        () => repo.fetchListings(
          skip: any(named: 'skip'),
          search: any(named: 'search'),
          category: any(named: 'category'),
          sort: any(named: 'sort'),
        ),
      ).called(1);
    });
  });

  group('failure handling', () {
    test('falls back to cached listings when offline', () async {
      stubFailure(
        const ApiException(ApiErrorKind.network, 'No internet connection.'),
      );
      final cachedAt = DateTime(2026, 1, 1);
      when(repo.cachedListings).thenReturn(page(count: 5));
      when(repo.cacheSavedAt).thenReturn(cachedAt);

      final container = makeContainer();
      container.read(listingsControllerProvider);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(listingsControllerProvider);
      expect(state.isOffline, isTrue);
      expect(state.items, hasLength(5));
      expect(state.cachedAt, cachedAt);
      // Cached content is shown instead of an error screen.
      expect(state.error, isNull);
      expect(state.hasFatalError, isFalse);
    });

    test('surfaces a fatal error when offline with no cache', () async {
      stubFailure(
        const ApiException(ApiErrorKind.network, 'No internet connection.'),
      );
      when(repo.cachedListings).thenReturn(null);
      when(repo.cacheSavedAt).thenReturn(null);

      final container = makeContainer();
      container.read(listingsControllerProvider);
      await Future<void>.delayed(Duration.zero);

      final state = container.read(listingsControllerProvider);
      expect(state.hasFatalError, isTrue);
      expect(state.error?.kind, ApiErrorKind.network);
    });

    test('does not use the cache when filters are active', () async {
      stubFetch(page(count: 20));
      final container = makeContainer();
      final controller = container.read(listingsControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      stubFailure(
        const ApiException(ApiErrorKind.network, 'No internet connection.'),
      );
      when(repo.cachedListings).thenReturn(page(count: 5));
      when(repo.cacheSavedAt).thenReturn(null);

      controller.onCategoryChanged('laptops');
      await Future<void>.delayed(Duration.zero);

      // The cache only holds the unfiltered list, so a filtered failure is
      // an error rather than stale results presented as a match.
      expect(container.read(listingsControllerProvider).hasFatalError, isTrue);
      verifyNever(repo.cachedListings);
    });
  });

  group('filters', () {
    test('search is debounced and hits the API once', () async {
      stubFetch(page(count: 20));
      final container = makeContainer();
      final controller = container.read(listingsControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      controller
        ..onSearchChanged('d')
        ..onSearchChanged('dr')
        ..onSearchChanged('dri');

      // Nothing yet: the debounce timer has not fired.
      verifyNever(
        () => repo.fetchListings(
          skip: any(named: 'skip'),
          search: 'dri',
          category: any(named: 'category'),
          sort: any(named: 'sort'),
        ),
      );

      await Future<void>.delayed(ListingsController.debounceDelay * 2);

      expect(container.read(listingsControllerProvider).search, 'dri');
      verify(
        () => repo.fetchListings(
          skip: 0,
          search: 'dri',
          category: any(named: 'category'),
          sort: any(named: 'sort'),
        ),
      ).called(1);
    });

    test('clearFilters resets search, category and sort', () async {
      stubFetch(page(count: 20));
      final container = makeContainer();
      final controller = container.read(listingsControllerProvider.notifier);
      await Future<void>.delayed(Duration.zero);

      controller.onCategoryChanged('laptops');
      controller.onSortChanged(PriceSort.asc);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(listingsControllerProvider).hasFilters, isTrue);

      controller.clearFilters();
      await Future<void>.delayed(Duration.zero);

      final state = container.read(listingsControllerProvider);
      expect(state.hasFilters, isFalse);
      expect(state.category, isNull);
      expect(state.sort, PriceSort.none);
    });
  });

  group('local delete', () {
    test('removeLocally drops the listing and decrements the total', () async {
      stubFetch(page(count: 20));
      final container = makeContainer();
      container.read(listingsControllerProvider);
      await Future<void>.delayed(Duration.zero);

      container.read(listingsControllerProvider.notifier).removeLocally(3);

      final state = container.read(listingsControllerProvider);
      expect(state.items, hasLength(19));
      expect(state.items.any((l) => l.id == 3), isFalse);
      expect(state.page.total, 99);
    });
  });
}
