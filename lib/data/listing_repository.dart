import '../core/api_client.dart';
import '../core/api_exception.dart';
import 'listing_cache.dart';
import 'models/listing_page.dart';
import 'models/listing.dart';

enum PriceSort {
  none('Default'),
  asc('Price: Low to High'),
  desc('Price: High to Low');

  const PriceSort(this.label);
  final String label;
}

class ListingRepository {
  ListingRepository(this._api, this._cache);

  final ApiClient _api;
  final ListingCache _cache;

  static const pageSize = 20;

  Future<ListingPage> fetchListings({
    int skip = 0,
    String search = '',
    String? category,
    PriceSort sort = PriceSort.none,
  }) async {
    final hasSearch = search.trim().isNotEmpty;

    final path = hasSearch
        ? '/products/search'
        : (category != null ? '/products/category/$category' : '/products');

    final query = <String, dynamic>{
      'limit': pageSize,
      'skip': skip,

      if (hasSearch) 'q': search.trim(),
      if (sort != PriceSort.none) ...{
        'sortBy': 'price',
        'order': sort == PriceSort.asc ? 'asc' : 'desc',
      },
    };

    try {
      final page = ListingPage.fromJson(await _api.get(path, query: query));

      if (skip == 0 &&
          !hasSearch &&
          category == null &&
          sort == PriceSort.none) {
        await _cache.save(page);
      }
      return page;
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<String>> fetchCategories() async {
    try {
      final res = await _api.getList('/products/category-list');
      return res.cast<String>();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Listing> fetchListing(int id) async {
    try {
      return Listing.fromJson(await _api.get('/products/$id'));
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<List<Listing>> fetchSimilar(
    String category, {
    required int excludeId,
  }) async {
    try {
      final res = await _api.get(
        '/products/category/$category',
        query: {'limit': 10},
      );
      return ListingPage.fromJson(
        res,
      ).items.where((l) => l.id != excludeId).toList();
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<Listing> createListing({
    required String title,
    required String category,
    required double price,
    required String description,
    required int stock,
    required String condition,
  }) async {
    try {
      final res = await _api.post(
        '/products/add',
        body: {
          'title': title,
          'description': description,
          'price': price,
          'category': category,
          'stock': stock,
        },
      );
      return Listing.fromJson(res);
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  Future<void> deleteListing(int id) async {
    try {
      await _api.delete('/products/$id');
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  ListingPage? cachedListings() => _cache.read();

  DateTime? cacheSavedAt() => _cache.savedAt();
}
