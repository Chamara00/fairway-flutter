import 'package:fairway/data/models/listing.dart';
import 'package:fairway/data/models/listing_page.dart';

/// [thumbnail] defaults to empty so widget tests render the offline
/// placeholder instead of attempting a network image fetch.
Listing listing(
  int id, {
  String title = 'Listing',
  double price = 10,
  String thumbnail = '',
}) => Listing(
  id: id,
  title: '$title $id',
  description: 'Description $id',
  price: price,
  category: 'sports-accessories',
  thumbnail: thumbnail,
  images: const [],
);

ListingPage page({
  required int count,
  int total = 100,
  int skip = 0,
  int startId = 1,
}) => ListingPage(
  items: List.generate(count, (i) => listing(startId + i)),
  total: total,
  skip: skip,
  limit: 20,
);
