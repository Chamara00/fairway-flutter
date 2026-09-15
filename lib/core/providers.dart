import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/listing_cache.dart';
import '../data/listing_repository.dart';
import 'api_client.dart';

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPrefsProvider must be overridden'),
);

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final listingCacheProvider = Provider<ListingCache>(
  (ref) => ListingCache(ref.watch(sharedPrefsProvider)),
);

final listingRepositoryProvider = Provider<ListingRepository>(
  (ref) => ListingRepository(
    ref.watch(apiClientProvider),
    ref.watch(listingCacheProvider),
  ),
);

final categoriesProvider = FutureProvider<List<String>>(
  (ref) => ref.watch(listingRepositoryProvider).fetchCategories(),
);

final connectivityProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();

  bool isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  yield isOnline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(isOnline);
});
