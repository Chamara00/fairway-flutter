import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/providers.dart';
import '../../data/models/listing.dart';
import '../listings/listings_controller.dart';

final listingDetailProvider =
    AsyncNotifierProvider.family<ListingDetailController, Listing, int>(
      ListingDetailController.new,
    );

class ListingDetailController extends FamilyAsyncNotifier<Listing, int> {
  @override
  Future<Listing> build(int id) async {
    // A listing created this session is not fetchable from the API.
    final local = ref.read(createdListingsProvider.notifier).byId(id);
    if (local != null) return local;

    return ref.read(listingRepositoryProvider).fetchListing(id);
  }

  Future<void> retry() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(listingRepositoryProvider).fetchListing(arg),
    );
  }

  Future<ApiException?> delete() async {
    try {
      await ref.read(listingRepositoryProvider).deleteListing(arg);
      ref.read(listingsControllerProvider.notifier).removeLocally(arg);
      return null;
    } on ApiException catch (e) {
      return e;
    }
  }
}

final similarListingsProvider =
    FutureProvider.family<List<Listing>, ({String category, int excludeId})>(
      (ref, args) => ref
          .watch(listingRepositoryProvider)
          .fetchSimilar(args.category, excludeId: args.excludeId),
    );
