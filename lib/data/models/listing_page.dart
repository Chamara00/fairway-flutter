import 'listing.dart';

class ListingPage {
  const ListingPage({
    required this.items,
    required this.total,
    required this.skip,
    required this.limit,
  });

  final List<Listing> items;
  final int total;
  final int skip;
  final int limit;

  const ListingPage.empty() : items = const [], total = 0, skip = 0, limit = 0;

  bool get hasMore => skip + items.length < total;

  int get nextSkip => skip + items.length;

  factory ListingPage.fromJson(Map<String, dynamic> json) => ListingPage(
    items: (json['products'] as List? ?? const [])
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList(),
    total: (json['total'] as num?)?.toInt() ?? 0,
    skip: (json['skip'] as num?)?.toInt() ?? 0,
    limit: (json['limit'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'products': items.map((e) => e.toJson()).toList(),
    'total': total,
    'skip': skip,
    'limit': limit,
  };

  ListingPage merge(ListingPage next) => ListingPage(
    items: [...items, ...next.items],
    total: next.total,
    skip: next.skip,
    limit: next.limit,
  );
}
