class Product {
  final String id;
  final String name;
  final double price;
  final int priceCents;
  final String image;
  final String description;
  final String category;
  final bool isGhost;
  final int stock;
  final String businessId;
  final String businessName;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.priceCents,
    required this.image,
    required this.description,
    required this.category,
    this.isGhost = false,
    this.stock = 0,
    this.businessId = '',
    this.businessName = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'priceCents': priceCents,
        'image': image,
        'description': description,
        'category': category,
        'isGhost': isGhost,
        'stock': stock,
        'businessId': businessId,
        'businessName': businessName,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: '${json['id']}',
        name: json['name'] as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ??
            ((json['priceCents'] as num?)?.toDouble() ?? 0) / 100,
        priceCents: (json['priceCents'] as num?)?.toInt() ??
            ((json['price'] as num?)?.toDouble() ?? 0 * 100).round() * 100,
        image: json['image'] as String? ?? '',
        description: json['description'] as String? ?? '',
        category: json['category'] as String? ?? '',
        isGhost: json['isGhost'] as bool? ?? false,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        businessId: '${json['businessId'] ?? ''}',
        businessName: json['businessName'] as String? ?? '',
      );
}
