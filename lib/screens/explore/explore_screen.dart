import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/product.dart';
import 'package:sell_on_app/providers/cart_provider.dart';
import 'package:sell_on_app/providers/wishlist_provider.dart';
import 'package:sell_on_app/widgets/price_tag.dart';
import 'package:sell_on_app/widgets/skeleton.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String _activeCategory = 'All';
  String _searchQuery = '';
  String _debouncedSearch = '';

  final List<String> _categories = [
    'All',
    'Handbags',
    'Travel',
    'Clutches',
    'Backpacks',
    'Satchels',
    'Crossbody',
    'Accessories',
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchQuery = value;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_searchQuery == value && mounted) {
        setState(() => _debouncedSearch = value);
      }
    });
  }

  List<Product> get _filteredProducts {
    return Product.all.where((p) {
      final matchesCategory =
          _activeCategory == 'All' || p.category == _activeCategory;
      final matchesSearch = p.name
          .toLowerCase()
          .contains(_debouncedSearch.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200
        ? 5
        : width > 900
            ? 4
            : width > 600
                ? 3
                : 2;

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(32, 80, 32, 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(48),
                    bottomRight: Radius.circular(48),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildHeader(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
                child: _buildCategoryChips(),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(32, 0, 32, 96),
              sliver: _loading
                  ? _buildSkeletonGrid(crossAxisCount)
                  : _buildProductGrid(crossAxisCount),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'VERIFIED ARCHIVE',
              style: TextStyle(
                color: AppColors.brandPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 1,
              color: AppColors.brandPrimary.withValues(alpha: 0.3),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Digital Catalogue',
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: AppColors.brandDark,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.softSurface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 22, color: Color(0xFF8E8E93)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search the collection...',
                    hintStyle: TextStyle(color: Color(0xFF8E8E93)),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isActive = cat == _activeCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activeCategory = cat);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.brandDark
                      : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isActive
                        ? AppColors.brandDark
                        : Colors.white,
                  ),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 16,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  cat,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 10,
                    letterSpacing: 2,
                    color: isActive
                        ? AppColors.brandPrimary
                        : AppColors.brandMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  SliverGrid _buildSkeletonGrid(int crossAxisCount) {
    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 0.65,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return SoftCard(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                const Expanded(
                  child: Skeleton(height: double.infinity, borderRadius: 32),
                ),
                const SizedBox(height: 12),
                const Skeleton(height: 16, width: 120),
                const SizedBox(height: 8),
                const Skeleton(height: 20, width: 80),
              ],
            ),
          );
        },
        childCount: 8,
      ),
    );
  }

  Widget _buildProductGrid(int crossAxisCount) {
    final products = _filteredProducts;

    if (products.isEmpty) {
      return SliverToBoxAdapter(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 80),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: AppColors.brandMuted.withValues(alpha: 0.3),
              style: BorderStyle.solid,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.search_off,
                size: 64,
                color: Color(0xFFD1D1D6),
              ),
              const SizedBox(height: 24),
              const Text(
                'The Archive is Empty',
                style: TextStyle(
                  color: AppColors.brandMuted,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
        childAspectRatio: 0.65,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final product = products[index];
          return _ProductGridItem(
            product: product,
            onTap: () =>
                Navigator.of(context).pushNamed('/product/${product.id}'),
          );
        },
        childCount: products.length,
      ),
    );
  }
}

class _ProductGridItem extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductGridItem({required this.product, required this.onTap});

  @override
  State<_ProductGridItem> createState() => _ProductGridItemState();
}

class _ProductGridItemState extends State<_ProductGridItem> {
  bool _imageLoaded = false;

  @override
  Widget build(BuildContext context) {
    final wishlist = context.watch<WishlistProvider>();
    final cart = context.read<CartProvider>();
    final isWishlisted = wishlist.isInWishlist(widget.product.id);

    return SoftCard(
      onTap: widget.onTap,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.softSurface,
                    borderRadius: BorderRadius.circular(32),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    children: [
                      if (!_imageLoaded)
                        const Positioned.fill(
                          child: Skeleton(
                            height: double.infinity,
                            borderRadius: 32,
                          ),
                        ),
                      Image.asset(
                        widget.product.image,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: AppColors.softSurface,
                          child: const Icon(
                            Icons.image,
                            color: AppColors.brandMuted,
                            size: 48,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      if (isWishlisted) {
                        wishlist.removeFromWishlist(widget.product.id);
                      } else {
                        wishlist.addToWishlist(widget.product);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isWishlisted
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 18,
                        color: isWishlisted
                            ? const Color(0xFFFF3B30)
                            : const Color(0xFF8E8E93),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'AUTHENTICATED',
            style: TextStyle(
              color: AppColors.brandMuted,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppColors.brandDark,
              fontSize: 18,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              PriceTag(
                amount: widget.product.price,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  color: AppColors.brandDark,
                  fontSize: 22,
                  letterSpacing: -0.5,
                ),
              ),
              GestureDetector(
                onTap: () {
                  cart.addToCart(widget.product);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${widget.product.name} added to cart'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.brandPrimary.withValues(alpha: 0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.add,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
