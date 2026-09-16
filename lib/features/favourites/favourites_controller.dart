import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers.dart';
import '../../data/models/listing.dart';

class FavouritesController extends Notifier<Map<int, Listing>> {
  static const _key = 'favourites_v1';

  @override
  Map<int, Listing> build() => _read();

  Map<int, Listing> _read() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return const {};
    try {
      final list = jsonDecode(raw) as List;
      final listings = list
          .map((e) => Listing.fromJson(e as Map<String, dynamic>))
          .toList();
      return {for (final l in listings) l.id: l};
    } catch (_) {
      // Corrupt or written by an older model: drop it rather than crash.
      ref.read(sharedPrefsProvider).remove(_key);
      return const {};
    }
  }

  Future<void> _persist(Map<int, Listing> value) async {
    await ref
        .read(sharedPrefsProvider)
        .setString(
          _key,
          jsonEncode(value.values.map((l) => l.toJson()).toList()),
        );
  }

  bool isFavourite(int id) => state.containsKey(id);

  bool toggle(Listing listing) {
    final next = {...state};
    final added = !next.containsKey(listing.id);

    if (added) {
      next[listing.id] = listing;
    } else {
      next.remove(listing.id);
    }

    state = next;
    _persist(next);
    return added;
  }

  void remove(int id) {
    if (!state.containsKey(id)) return;
    final next = {...state}..remove(id);
    state = next;
    _persist(next);
  }
}

final favouritesProvider =
    NotifierProvider<FavouritesController, Map<int, Listing>>(
      FavouritesController.new,
    );

final favouritesFilterProvider = StateProvider<bool>((ref) => false);
