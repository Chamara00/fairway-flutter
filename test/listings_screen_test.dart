import 'package:fairway/core/api_exception.dart';
import 'package:fairway/core/providers.dart';
import 'package:fairway/data/listing_repository.dart';
import 'package:fairway/data/models/listing_page.dart';
import 'package:fairway/features/listings/listings_screen.dart';
import 'package:fairway/features/listings/widgets/listing_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

class MockListingRepository extends Mock implements ListingRepository {}

void main() {
  late MockListingRepository repo;
  late SharedPreferences prefs;

  setUpAll(() => registerFallbackValue(PriceSort.none));

  setUp(() async {
    repo = MockListingRepository();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    // Categories load on first build of the filter bar.
    when(repo.fetchCategories).thenAnswer((_) async => ['laptops', 'beauty']);
    when(repo.cachedListings).thenReturn(null);
    when(repo.cacheSavedAt).thenReturn(null);
  });

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

  /// Pumps the listings screen with the repository and prefs mocked out.
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          listingRepositoryProvider.overrideWithValue(repo),
          sharedPrefsProvider.overrideWithValue(prefs),
        ],
        child: const MaterialApp(home: ListingsScreen()),
      ),
    );
  }

  testWidgets('shows a spinner while the first page loads', (tester) async {
    stubFetch(page(count: 4));
    await pumpScreen(tester);

    // Before the future completes.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(ListingCard), findsNothing);

    await tester.pumpAndSettle();
  });

  testWidgets('renders a card per listing once loaded', (tester) async {
    stubFetch(page(count: 4));
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.byType(ListingCard), findsNWidgets(4));
    expect(find.text('Listing 1'), findsOneWidget);
    expect(find.text('\$10.00'), findsNWidgets(4));
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows an error with a retry action, and retry refetches', (
    tester,
  ) async {
    stubFailure(
      const ApiException(ApiErrorKind.network, 'No internet connection.'),
    );
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('No connection'), findsOneWidget);
    expect(find.text('No internet connection.'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Try again'), findsOneWidget);

    // Network comes back, user taps retry.
    stubFetch(page(count: 2));
    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.byType(ListingCard), findsNWidgets(2));
    expect(find.text('No connection'), findsNothing);
  });

  testWidgets('shows the empty state when nothing matches', (tester) async {
    stubFetch(page(count: 0, total: 0));
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.text('No listings found'), findsOneWidget);
    expect(find.byType(ListingCard), findsNothing);
  });

  testWidgets('shows the offline banner when serving cached listings', (
    tester,
  ) async {
    stubFailure(
      const ApiException(ApiErrorKind.network, 'No internet connection.'),
    );
    when(repo.cachedListings).thenReturn(page(count: 3));
    when(repo.cacheSavedAt).thenReturn(DateTime.now());

    await pumpScreen(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('Offline'), findsOneWidget);
    expect(find.byType(ListingCard), findsNWidgets(3));
  });

  testWidgets('typing in search queries the API once, after the debounce', (
    tester,
  ) async {
    stubFetch(page(count: 4));
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'driver');
    await tester.pump(); // no request yet

    verifyNever(
      () => repo.fetchListings(
        skip: any(named: 'skip'),
        search: 'driver',
        category: any(named: 'category'),
        sort: any(named: 'sort'),
      ),
    );

    await tester.pumpAndSettle(const Duration(seconds: 1));

    verify(
      () => repo.fetchListings(
        skip: 0,
        search: 'driver',
        category: any(named: 'category'),
        sort: any(named: 'sort'),
      ),
    ).called(1);
  });

  testWidgets('favouriting a listing persists and filters the grid', (
    tester,
  ) async {
    stubFetch(page(count: 3));
    await pumpScreen(tester);
    await tester.pumpAndSettle();

    // Heart the first card.
    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pumpAndSettle();

    // Switch the grid to favourites only via the app bar toggle.
    await tester.tap(find.byIcon(Icons.favorite_border).last);
    await tester.pumpAndSettle();

    expect(find.byType(ListingCard), findsOneWidget);
    expect(find.text('Listing 1'), findsOneWidget);
  });
}
