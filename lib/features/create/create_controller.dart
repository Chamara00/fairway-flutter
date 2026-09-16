import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../core/providers.dart';
import '../../data/models/listing.dart';

class CreateState {
  const CreateState({this.isSubmitting = false, this.error});

  final bool isSubmitting;
  final ApiException? error;
}

class CreateController extends Notifier<CreateState> {
  @override
  CreateState build() => const CreateState();

  Future<Listing?> submit({
    required String title,
    required String category,
    required double price,
    required String description,
    required int stock,
    required String condition,
  }) async {
    if (state.isSubmitting) return null;
    state = const CreateState(isSubmitting: true);

    try {
      final listing = await ref
          .read(listingRepositoryProvider)
          .createListing(
            title: title,
            category: category,
            price: price,
            description: description,
            stock: stock,
            condition: condition,
          );

      // Keep it locally so its detail screen can render.
      ref.read(createdListingsProvider.notifier).add(listing);

      state = const CreateState();
      return listing;
    } on ApiException catch (e) {
      state = CreateState(error: e);
      return null;
    }
  }
}

final createControllerProvider =
    NotifierProvider<CreateController, CreateState>(CreateController.new);
