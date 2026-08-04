import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/cart_provider.dart';
import 'package:sell_on_app/providers/wishlist_provider.dart';
import 'package:sell_on_app/widgets/product_card.dart';
import 'package:sell_on_app/widgets/soft_button.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  @override
  Widget build(BuildContext context) {
    final wishlistProvider = context.watch<WishlistProvider>();
    final cartProvider = context.watch<CartProvider>();
    final wishlist = wishlistProvider.wishlist;

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      appBar: AppBar(
        title: const Text('My Wishlist'),
        backgroundColor: const Color(0xFFE0E5EC),
        foregroundColor: AppColors.brandDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: wishlist.isNotEmpty
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${wishlist.length} Items Saved',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                      SoftButton(
                        title: 'Clear All',
                        variant: SoftButtonVariant.ghost,
                        textStyle: const TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                        ),
                        onPressed: () => wishlistProvider.clearWishlist(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 16,
                    runSpacing: 24,
                    children: wishlist.map((product) {
                      return ProductCard(
                        product: product,
                        isLiked: true,
                        onWishlistToggle: () => wishlistProvider.removeFromWishlist(product.id),
                        onAddToCart: () => cartProvider.addToCart(product),
                        onTap: () => Navigator.of(context).pushNamed('/product/${product.id}'),
                      );
                    }).toList(),
                  ),
                ],
              )
            : _buildEmptyState(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border,
              size: 48,
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your wishlist is empty',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Tap the heart on any product to save it for later.',
            textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
          const SizedBox(height: 32),
          SoftButton(
            title: 'Start Shopping',
            variant: SoftButtonVariant.primary,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false),
          ),
        ],
      ),
    );
  }
}
