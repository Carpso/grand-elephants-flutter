import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/product.dart';
import 'package:sell_on_app/utils/spring_curve.dart';
import 'package:sell_on_app/widgets/price_tag.dart';
import 'package:sell_on_app/widgets/product_image.dart';
import 'package:sell_on_app/widgets/skeleton.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback? onAddToCart;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool isLiked;
  final VoidCallback? onWishlistToggle;

  const ProductCard({
    super.key,
    required this.product,
    this.onAddToCart,
    this.onTap,
    this.isLoading = false,
    this.isLiked = false,
    this.onWishlistToggle,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
    _scaleAnim = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const SpringCurve(damping: 15),
      ),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return _buildSkeleton();
    }

    return AnimatedBuilder(
      animation: _animController,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Semantics(
              label: '${widget.product.name}, price ${widget.product.price.toStringAsFixed(0)} ZMW',
              button: true,
              child: child,
            ),
          ),
        );
      },
      child: SoftCard(
        onTap: widget.onTap,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 224,
          height: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImageArea(),
              _buildInfoArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SoftCard(
      padding: const EdgeInsets.all(8),
      child: SizedBox(
        width: 192,
        height: 256,
        child: Column(
          children: [
            const Skeleton(height: 128, borderRadius: 12),
            const SizedBox(height: 8),
            const Skeleton(height: 20, width: 150),
            const SizedBox(height: 4),
            const Skeleton(height: 24, width: 80),
            const SizedBox(height: 8),
            const Skeleton(height: 40, borderRadius: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea() {
    return Stack(
      children: [
        Container(
          height: 192,
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.softSurface,
            border: Border(
              bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Stack(
            children: [
              ProductImage(
                src: widget.product.image,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              _buildBadges(),
            ],
          ),
        ),
        _buildWishlistButton(),
      ],
    );
  }

  Widget _buildBadges() {
    return Positioned(
      top: 16,
      left: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.brandDark.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            ),
            child: const Text(
              'RARE PIECE',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w900,
                color: AppColors.brandDark,
                letterSpacing: 2,
              ),
            ),
          ),
          if (widget.product.isGhost)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: SizedBox(
                height: 20,
                child: _GhostBadge(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildWishlistButton() {
    return Positioned(
      top: 16,
      right: 16,
      child: GestureDetector(
        onTap: widget.onWishlistToggle,
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            widget.isLiked ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: widget.isLiked ? const Color(0xFFFF3B30) : const Color(0xFF8E8E93),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoArea() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AUTHENTIC HERITAGE',
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
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: AppColors.brandDark,
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
                    fontSize: 20,
                    letterSpacing: -0.5,
                  ),
                ),
                GestureDetector(
                  onTap: widget.onAddToCart,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.brandPrimary.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart,
                      size: 18,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GhostBadge extends StatelessWidget {
  const _GhostBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_fix_high, size: 10, color: Colors.black),
          SizedBox(width: 4),
          Text(
            'GHOST AI',
            style: TextStyle(
              fontSize: 6,
              fontWeight: FontWeight.w900,
              color: Colors.black,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}
