class Dimensions {
  const Dimensions({
    required this.width,
    required this.height,
    required this.depth,
  });

  final double width;
  final double height;
  final double depth;

  factory Dimensions.fromJson(Map<String, dynamic> json) => Dimensions(
    width: (json['width'] as num?)?.toDouble() ?? 0,
    height: (json['height'] as num?)?.toDouble() ?? 0,
    depth: (json['depth'] as num?)?.toDouble() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'width': width,
    'height': height,
    'depth': depth,
  };

  @override
  String toString() => '$width x $height x $depth cm';
}

class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.thumbnail,
    required this.images,
    this.rating = 0,
    this.stock = 0,
    this.brand,
    this.sku,
    this.weight,
    this.dimensions,
    this.warrantyInformation,
    this.shippingInformation,
    this.returnPolicy,
    this.availabilityStatus,
    this.tags = const [],
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String thumbnail;
  final List<String> images;
  final double rating;
  final int stock;
  final String? brand;
  final String? sku;
  final num? weight;
  final Dimensions? dimensions;
  final String? warrantyInformation;
  final String? shippingInformation;
  final String? returnPolicy;
  final String? availabilityStatus;
  final List<String> tags;

  String get condition => stock > 50 ? 'New' : 'Used - good';

  List<String> get galleryImages {
    if (images.isNotEmpty) return images;
    if (thumbnail.isNotEmpty) return [thumbnail];
    return const [];
  }

  Map<String, String> get specifications => {
    if (brand != null) 'Brand': brand!,
    if (sku != null) 'SKU': sku!,
    if (weight != null) 'Weight': '$weight',
    if (dimensions != null) 'Dimensions': '$dimensions',
    if (availabilityStatus != null) 'Availability': availabilityStatus!,
    if (warrantyInformation != null) 'Warranty': warrantyInformation!,
    if (shippingInformation != null) 'Shipping': shippingInformation!,
    if (returnPolicy != null) 'Returns': returnPolicy!,
  };

  factory Listing.fromJson(Map<String, dynamic> json) => Listing(
    id: json['id'] as int,
    title: json['title'] as String? ?? 'Untitled',
    description: json['description'] as String? ?? '',
    // num, not double: the API returns whole prices as int.
    price: (json['price'] as num?)?.toDouble() ?? 0,
    category: json['category'] as String? ?? 'unknown',
    thumbnail: json['thumbnail'] as String? ?? '',
    images: (json['images'] as List?)?.cast<String>() ?? const [],
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    stock: (json['stock'] as num?)?.toInt() ?? 0,
    brand: json['brand'] as String?,
    sku: json['sku'] as String?,
    weight: json['weight'] as num?,
    dimensions: json['dimensions'] == null
        ? null
        : Dimensions.fromJson(json['dimensions'] as Map<String, dynamic>),
    warrantyInformation: json['warrantyInformation'] as String?,
    shippingInformation: json['shippingInformation'] as String?,
    returnPolicy: json['returnPolicy'] as String?,
    availabilityStatus: json['availabilityStatus'] as String?,
    tags: (json['tags'] as List?)?.cast<String>() ?? const [],
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'price': price,
    'category': category,
    'thumbnail': thumbnail,
    'images': images,
    'rating': rating,
    'stock': stock,
    'brand': brand,
    'sku': sku,
    'weight': weight,
    'dimensions': dimensions?.toJson(),
    'warrantyInformation': warrantyInformation,
    'shippingInformation': shippingInformation,
    'returnPolicy': returnPolicy,
    'availabilityStatus': availabilityStatus,
    'tags': tags,
  };
}
