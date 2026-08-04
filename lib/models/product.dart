class Product {
  final String id;
  final String name;
  final double price;
  final String image;
  final String description;
  final String category;
  final bool isGhost;

  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.image,
    required this.description,
    required this.category,
    this.isGhost = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'image': image,
        'description': description,
        'category': category,
        'isGhost': isGhost,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        image: json['image'] as String,
        description: json['description'] as String,
        category: json['category'] as String,
        isGhost: json['isGhost'] as bool? ?? false,
      );

  static final List<Product> all = [
        Product(
          id: '1',
          name: 'Royal Gold Handbag',
          price: 3500,
          image: 'assets/products/luxury_handbag_gold_1765539658142.png',
          description:
              'A high-end, luxury golden leather handbag on a soft, neutral background. Perfect for evening galas.',
          category: 'Handbags',
          isGhost: true,
        ),
        Product(
          id: '2',
          name: 'Chic Beige Tote',
          price: 1800,
          image: 'assets/products/chic_tote_bag_beige_1765539674873.png',
          description:
              'A chic, beige canvas and leather tote bag. Ideal for daily office use with premium durability.',
          category: 'Totes',
        ),
        Product(
          id: '3',
          name: 'Modern Black Clutch',
          price: 2200,
          image: 'assets/products/modern_clutch_black_1765539690984.png',
          description:
              'A sleek, modern black evening clutch with gold accents. The ultimate accessory for formal events.',
          category: 'Clutches',
        ),
        Product(
          id: '4',
          name: 'Tan Leather Backpack',
          price: 2800,
          image: 'assets/products/elegant_backpack_tan_1765539717712.png',
          description:
              'A sophisticated, tan leather backpack for women. Minimalist design with maximum utility.',
          category: 'Backpacks',
        ),
        Product(
          id: '5',
          name: 'Ruby Satchel',
          price: 3100,
          image: 'assets/products/red_leather_satchel_1765540591490.png',
          description:
              'A vibrant red leather satchel bag with silver hardware. Make a bold statement anywhere you go.',
          category: 'Satchels',
        ),
        Product(
          id: '6',
          name: 'Navy Chain Crossbody',
          price: 1500,
          image: 'assets/products/blue_crossbody_bag_1765540608590.png',
          description:
              'A stylish navy blue crossbody bag with a chain strap. Compact yet spacious enough for essentials.',
          category: 'Crossbody',
        ),
        Product(
          id: '7',
          name: 'Pristine White Handbag',
          price: 2600,
          image: 'assets/products/white_structured_handbag_1765540624619.png',
          description:
              'A pristine white structured handbag. Elegant, modern design for the contemporary woman.',
          category: 'Handbags',
          isGhost: true,
        ),
        Product(
          id: '8',
          name: 'Artisan Travel Duffle',
          price: 4500,
          image: 'assets/products/patterned_travel_duffle_1765540640522.png',
          description:
              'A luxury patterned travel duffle bag. Leather straps and premium canvas for stylish getaways.',
          category: 'Travel',
        ),
        Product(
          id: '9',
          name: 'Heritage Messenger',
          price: 3200,
          image: 'assets/products/vintage_leather_messenger_1765541166445.png',
          description:
              'A vintage brown leather messenger bag with brass buckles. Rugged yet sophisticated.',
          category: 'Messenger',
        ),
        Product(
          id: '10',
          name: 'Boho Suede Bucket',
          price: 2400,
          image: 'assets/products/boho_bucket_bag_suede_1765541183472.png',
          description:
              'A stylish suede bucket bag in earthy tones with tassel details. Bohemian chic fashion.',
          category: 'Bucket Bags',
        ),
        Product(
          id: '11',
          name: 'Urban Belt Bag',
          price: 1200,
          image: 'assets/products/urban_belt_bag_black_1765541201845.png',
          description:
              'A sleek, modern black leather belt bag (fanny pack). Urban streetwear style.',
          category: 'Accessories',
        ),
        Product(
          id: '12',
          name: 'Nautical Weekender',
          price: 3800,
          image: 'assets/products/canvas_weekender_striped_1765541218222.png',
          description:
              'A large canvas weekender bag with nautical stripes and leather handles. Premium quality travel companion.',
          category: 'Travel',
        ),
      ];
}
