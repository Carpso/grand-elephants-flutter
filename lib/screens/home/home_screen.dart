import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/product.dart';
import 'package:grand_elephants/providers/cart_provider.dart';
import 'package:grand_elephants/providers/catalog_provider.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/services/product_feed_service.dart';
import 'package:grand_elephants/widgets/product_card.dart';
import 'package:grand_elephants/widgets/skeleton.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _loading = true;
  String _searchQuery = '';
  String _debouncedSearch = '';

  bool _feedsLoaded = false;
  List<Product> _newArrivals = [];
  List<Product> _trending = [];
  List<Product> _suggested = [];

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    final catalog = context.read<CatalogProvider>();
    final feeds = _loadFeeds();
    await catalog.load();
    if (mounted) setState(() => _loading = false);
    await feeds;
  }

  /// Curated merchandising rows. Failures resolve to an empty list so the
  /// row silently hides instead of breaking the home screen.
  Future<void> _loadFeeds() async {
    if (mounted) setState(() => _feedsLoaded = false);
    final feeds = await ProductFeedService.loadAll();
    if (!mounted) return;
    setState(() {
      _newArrivals = feeds['new'] ?? const [];
      _trending = feeds['trending'] ?? const [];
      _suggested = feeds['suggested'] ?? const [];
      _feedsLoaded = true;
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
        context.read<CatalogProvider>().search(value);
      }
    });
  }

  static const List<String> _safeBannerPrefixes = [
    '/product/',
    '/orders',
    '/explore',
    '/cart',
    '/profile',
    '/admin',
    '/support',
  ];

  /// Banner links come from the server and are unvalidated, so only follow
  /// ones that point at routes this app actually owns. Anything else is
  /// ignored rather than pushing a dead "Route not found" page.
  String? _safeBannerLink(Object? link) {
    if (link is! String) return null;
    final value = link.trim();
    if (value.isEmpty) return null;
    return _safeBannerPrefixes.any(value.startsWith) ? value : null;
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final cart = context.watch<CartProvider>();
    final catalog = context.watch<CatalogProvider>();

    final filteredProducts = _debouncedSearch.isNotEmpty
        ? catalog.products
            .where((p) =>
                p.name.toLowerCase().contains(_debouncedSearch.toLowerCase()) ||
                p.description.toLowerCase().contains(_debouncedSearch.toLowerCase()))
            .toList()
        : catalog.products;
    final displayProducts =
        filteredProducts.isNotEmpty ? filteredProducts : <Product>[];

    final categories = catalog.categories;

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadCatalog();
            if (mounted) setState(() => _loading = true);
            await Future.delayed(const Duration(milliseconds: 400));
            if (mounted) setState(() => _loading = false);
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 56, 32, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Verified Heritage',
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
                        Text(
                          config.appName,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pushNamed('/profile'),
                      child: Stack(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                'https://ui-avatars.com/api/?name=User&background=0A0A0A&color=FFD700',
                                width: 44,
                                height: 44,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          if (cart.itemCount > 0)
                            Positioned(
                              right: -4,
                              top: -4,
                              child: Container(
                                constraints: const BoxConstraints(
                                  minWidth: 22,
                                  minHeight: 22,
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.brandAccent,
                                  borderRadius: BorderRadius.circular(11),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                                child: Text(
                                  '${cart.itemCount}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
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
                            hintText: 'Discover the collection...',
                            hintStyle:
                                TextStyle(color: Color(0xFF8E8E93)),
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
                      IconButton(
                        tooltip: 'Scan',
                        onPressed: () => Navigator.of(context).pushNamed('/scan'),
                        icon: const Icon(
                          Icons.qr_code_scanner,
                          size: 22,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_loading)
                _buildSkeletons()
              else if (displayProducts.isEmpty)
                _buildEmptySearchState()
              else ...[
                _buildBannerCarousel(config, catalog.banners),
                _buildProductRow(
                  eyebrow: 'JUST LANDED',
                  title: 'New Arrivals',
                  products: _newArrivals,
                  cart: cart,
                ),
                _buildProductRow(
                  eyebrow: 'MOST WANTED',
                  title: 'Trending Now',
                  products: _trending,
                  cart: cart,
                ),
                _buildProductRow(
                  eyebrow: 'PICKED FOR YOU',
                  title: 'Suggested For You',
                  products: _suggested,
                  cart: cart,
                ),
                _buildFeaturedSection(displayProducts, cart, config),
                _buildCategoriesSection(categories),
              ],
            ],
          ),
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletons() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Skeleton(height: 240, borderRadius: 32),
          SizedBox(height: 40),
          Skeleton(width: 200, height: 28),
          SizedBox(height: 24),
          Row(
            children: [
              Skeleton(width: 260, height: 320, borderRadius: 32),
              SizedBox(width: 24),
              Skeleton(width: 260, height: 320, borderRadius: 32),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySearchState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 32),
      child: Column(
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.brandMuted),
          const SizedBox(height: 16),
          const Text(
            'No items found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandDark),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term.',
            style: TextStyle(color: AppColors.brandMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerCarousel(ConfigProvider config, List<Map<String, dynamic>> banners) {
    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 32),
        itemCount: banners.isNotEmpty ? banners.length : 1,
        itemBuilder: (context, index) {
          if (banners.isEmpty) {
            return Container(
              width: MediaQuery.of(context).size.width - 64,
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A0A0A), Color(0xFF1A1A1A)],
                ),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    config.appName,
                    style: const TextStyle(
                      color: AppColors.brandPrimary,
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Text(
                    'Coming Soon to your Device',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }

          final banner = banners[index];
          return GestureDetector(
            onTap: () {
              final link = _safeBannerLink(banner['link']);
              if (link == null) return;
              Navigator.of(context).pushNamed(link);
            },
            child: Container(
              width: 350,
              margin: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      banner['image'] as String? ?? '',
                      fit: BoxFit.cover,
                      opacity: const AlwaysStoppedAnimation(0.8),
                      errorBuilder: (context, error, stackTrace) =>
                          Container(color: AppColors.brandDark),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment(0, 0.9),
                          end: Alignment.topCenter,
                          colors: [Colors.black, Colors.transparent, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 32,
                    right: 32,
                    bottom: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exhibition ${banner['id'] ?? ''}',
                          style: const TextStyle(
                            color: AppColors.brandPrimary,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banner['title'] as String? ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          banner['subtitle'] as String? ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandPrimary.withValues(alpha: 0.4),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: const Text(
                            'View Exhibit',
                            style: TextStyle(
                              color: AppColors.brandDark,
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// A merchandising row: eyebrow + title + "See all" over a horizontal
  /// carousel of ProductCards. Hidden when the feed is empty or failed.
  Widget _buildProductRow({
    required String eyebrow,
    required String title,
    required List<Product> products,
    required CartProvider cart,
  }) {
    if (_feedsLoaded && products.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: const TextStyle(
                      color: AppColors.brandMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/explore'),
                child: const Text(
                  'See all',
                  style: TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 360,
            child: !_feedsLoaded
                ? ListView(
                    scrollDirection: Axis.horizontal,
                    children: const [
                      Skeleton(width: 224, height: 340, borderRadius: 16),
                      SizedBox(width: 16),
                      Skeleton(width: 224, height: 340, borderRadius: 16),
                      SizedBox(width: 16),
                      Skeleton(width: 224, height: 340, borderRadius: 16),
                    ],
                  )
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: ProductCard(
                          product: product,
                          onAddToCart: () => cart.addToCart(product),
                          onTap: () => Navigator.of(context)
                              .pushNamed('/product/${product.id}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedSection(
      List<Product> products, CartProvider cart, ConfigProvider config) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURATED DAILY',
                    style: TextStyle(
                      color: AppColors.brandMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                    ),
                  ),
                  const Text(
                    'Featured Selection',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/explore'),
                child: const Text(
                  'All Items',
                  style: TextStyle(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 360,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ProductCard(
                    product: product,
                    onAddToCart: () => cart.addToCart(product),
                    onTap: () => Navigator.of(context)
                        .pushNamed('/product/${product.id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesSection(List<Map<String, dynamic>> categories) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'DEPARTMENT',
            style: TextStyle(
              color: AppColors.brandMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Haute Categories',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: AppColors.brandDark,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 160,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final cat = categories[index];
                final name = cat['name'] as String? ?? '';
                return GestureDetector(
                  onTap: () {
                    context.read<CatalogProvider>().filterByCategory(name);
                    Navigator.of(context).pushNamed('/explore');
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 32),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: Center(
                              child: Text(
                                cat['icon'] as String? ?? '🛍️',
                                style: const TextStyle(fontSize: 40),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: AppColors.brandDark,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
