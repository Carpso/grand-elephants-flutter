import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/product.dart';
import 'package:sell_on_app/providers/cart_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/price_tag.dart';

class ProductDetailScreen extends StatefulWidget {
  final String productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _activeSlide = 0;

  late final AnimationController _contentController;
  late final Animation<Offset> _contentSlide;
  late final Animation<double> _contentOpacity;

  bool _reviewModalVisible = false;
  int _newRating = 5;
  final TextEditingController _reviewController = TextEditingController();

  List<Map<String, String>> _reviews = [];

  Product get _product {
    final found = Product.all.where((p) => p.id == widget.productId).firstOrNull;
    return found ??
        Product(
          id: widget.productId,
          name: 'Royal Elephant Tote',
          price: 1200,
          image: Product.all.isNotEmpty
              ? Product.all.first.image
              : 'https://placehold.co/600x600/F3F4F6/D4AF37?text=Product+Image',
          description:
              'Handcrafted from premium leather, features signature golden elephant emblem.',
          category: 'Totes',
        );
  }

  List<String> get _images => [_product.image, _product.image, _product.image];

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeInOut,
    ));
    _contentOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _contentController, curve: Curves.easeInOut),
    );
    _contentController.forward();

    _reviews = [
      {
        'id': '1',
        'user': 'Sarah M.',
        'rating': '5',
        'comment': 'Absolutely stunning bag! The quality is unmatched.',
        'date': '2d ago',
      },
      {
        'id': '2',
        'user': 'James K.',
        'rating': '4',
        'comment': 'Great design, fast delivery.',
        'date': '1w ago',
      },
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentController.dispose();
    _reviewController.dispose();
    super.dispose();
  }

  void _handleAddToCart() {
    context.read<CartProvider>().addToCart(_product);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to Cart!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
    );
  }

  void _handleAddReview() {
    if (_reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write a comment'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() {
      _reviews.insert(
        0,
        {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'user': 'Guest User',
          'rating': _newRating.toString(),
          'comment': _reviewController.text,
          'date': 'Just now',
        },
      );
      _reviewModalVisible = false;
      _reviewController.clear();
      _newRating = 5;
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = _product;
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 450,
                pinned: false,
                backgroundColor: Colors.white,
                leading: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    margin: const EdgeInsets.only(left: 16, top: 8),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
                actions: [
                  GestureDetector(
                    onTap: () =>
                        Navigator.of(context).pushNamed('/cart/checkout'),
                    child: Container(
                      margin: const EdgeInsets.only(right: 16, top: 8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.shopping_bag,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (i) =>
                            setState(() => _activeSlide = i),
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          return Container(
                            width: width,
                            height: 450,
                            padding: const EdgeInsets.all(16),
                            child: Image.asset(
                              _images[index],
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: AppColors.softSurface,
                                child: const Icon(
                                  Icons.image,
                                  size: 80,
                                  color: AppColors.brandMuted,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(_images.length, (i) {
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: i == _activeSlide ? 32 : 8,
                              height: 8,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: i == _activeSlide
                                    ? AppColors.brandPrimary
                                    : const Color(0xFFD1D5DB),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  child: FadeTransition(
                    opacity: _contentOpacity,
                    child: SlideTransition(
                      position: _contentSlide,
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildProductInfo(product),
                          const SizedBox(height: 32),
                          _buildReviewsSection(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  SoftButton(
                    title: '',
                    icon: const Icon(Icons.camera_alt,
                        size: 24, color: Color(0xFF4B5563)),
                    variant: SoftButtonVariant.ghost,
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/try-on'),
                    padding: const EdgeInsets.all(16),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SoftButton(
                      title: 'Add to Cart',
                      variant: SoftButtonVariant.primary,
                      onPressed: _handleAddToCart,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_reviewModalVisible) _buildReviewModal(),
        ],
      ),
    );
  }

  Widget _buildProductInfo(Product product) {
    return FadeTransition(
      opacity: _contentOpacity,
      child: SoftCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.category.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.brandMuted,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                PriceTag(
                  amount: product.price,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandPrimary,
                    fontSize: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              product.description,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Reviews',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            Row(
              children: [
                const Text(
                  '4.8',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 20, color: Color(0xFFEAB308)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ..._reviews.take(3).map((r) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SoftCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          r['user'] ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandDark,
                          ),
                        ),
                        Text(
                          r['date'] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.brandMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildStars(int.parse(r['rating'] ?? '5')),
                    const SizedBox(height: 8),
                    Text(
                      '"${r['comment'] ?? ''}"',
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            )),
        SoftButton(
          title: 'Write a Review',
          variant: SoftButtonVariant.outline,
          onPressed: () => setState(() => _reviewModalVisible = true),
        ),
      ],
    );
  }

  Widget _buildStars(int rating) {
    return Row(
      children: List.generate(5, (star) {
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Icon(
            star < rating ? Icons.star : Icons.star_border,
            size: 16,
            color: const Color(0xFFD4AF37),
          ),
        );
      }),
    );
  }

  Widget _buildReviewModal() {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withValues(alpha: 0.6),
        child: GestureDetector(
          onTap: () => setState(() => _reviewModalVisible = false),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: GestureDetector(
              onTap: () {},
              child: Container(
                height: MediaQuery.of(context).size.height * 0.6,
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.softSurface,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1D5DB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Write a Review',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'RATING',
                      style: TextStyle(
                        color: AppColors.brandMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(5, (star) {
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _newRating = star + 1),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                star < _newRating
                                    ? Icons.star
                                    : Icons.star_border,
                                size: 32,
                                color: const Color(0xFFD4AF37),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'YOUR EXPERIENCE',
                      style: TextStyle(
                        color: AppColors.brandMuted,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _reviewController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            hintText:
                                'Share your thoughts about this product...',
                            hintStyle: TextStyle(
                              color: AppColors.brandMuted,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          style: const TextStyle(
                            color: AppColors.brandDark,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SoftButton(
                            title: 'Cancel',
                            variant: SoftButtonVariant.ghost,
                            onPressed: () => setState(
                                () => _reviewModalVisible = false),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SoftButton(
                            title: 'Submit Review',
                            variant: SoftButtonVariant.primary,
                            onPressed: _handleAddReview,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
