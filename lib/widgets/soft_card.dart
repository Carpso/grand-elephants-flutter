import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';

enum SoftCardVariant { elevated, sunken }

class SoftCard extends StatelessWidget {
  final Widget child;
  final SoftCardVariant variant;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry? borderRadius;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;

  const SoftCard({
    super.key,
    required this.child,
    this.variant = SoftCardVariant.elevated,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius,
    this.onTap,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: (borderRadius ?? BorderRadius.circular(16)) as BorderRadius,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: padding,
            decoration: _buildDecoration(),
            child: child,
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration() {
    final radius = borderRadius ?? BorderRadius.circular(16);
    switch (variant) {
      case SoftCardVariant.elevated:
        return BoxDecoration(
          color: AppColors.white,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        );
      case SoftCardVariant.sunken:
        return BoxDecoration(
          color: AppColors.softSurface,
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        );
    }
  }
}
