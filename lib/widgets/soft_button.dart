import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sell_on_app/constants/app_theme.dart';

enum SoftButtonVariant { primary, secondary, outline, ghost }

class SoftButton extends StatefulWidget {
  final String? title;
  final SoftButtonVariant variant;
  final Widget? icon;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;
  final bool isLoading;

  const SoftButton({
    super.key,
    this.title,
    this.variant = SoftButtonVariant.primary,
    this.icon,
    this.onPressed,
    this.padding,
    this.textStyle,
    this.isLoading = false,
  });

  @override
  State<SoftButton> createState() => _SoftButtonState();
}

class _SoftButtonState extends State<SoftButton> with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _controller.reverse();
    widget.onPressed?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null || widget.isLoading;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isDisabled ? 1.0 : _scaleAnimation.value,
          child: child,
        );
      },
      child: GestureDetector(
        onTapDown: isDisabled ? null : _handleTapDown,
        onTapUp: isDisabled ? null : _handleTapUp,
        onTapCancel: isDisabled ? null : _handleTapCancel,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: _buildDecoration(isDisabled),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.isLoading)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else ...[
                if (widget.icon != null) ...[
                  widget.icon!,
                  const SizedBox(width: 8),
                ],
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: _buildTextStyle(isDisabled),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _buildDecoration([bool disabled = false]) {
    final borderRadius = BorderRadius.circular(16);
    switch (widget.variant) {
      case SoftButtonVariant.primary:
        return BoxDecoration(
          color: disabled
              ? AppColors.brandPrimary.withValues(alpha: 0.5)
              : _isPressed
                  ? AppColors.softSurface
                  : AppColors.brandPrimary,
          borderRadius: borderRadius,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: disabled || _isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors.brandPrimary.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
        );
      case SoftButtonVariant.secondary:
        return BoxDecoration(
          color: disabled
              ? AppColors.softSurface.withValues(alpha: 0.5)
              : _isPressed
                  ? AppColors.brandDark.withValues(alpha: 0.05)
                  : AppColors.softSurface,
          borderRadius: borderRadius,
          border: Border.all(
            color: disabled ? Colors.white.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.4),
          ),
          boxShadow: disabled || _isPressed
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        );
      case SoftButtonVariant.outline:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
          border: Border.all(
            color: disabled
                ? AppColors.brandDark.withValues(alpha: 0.1)
                : AppColors.brandDark.withValues(alpha: 0.2),
            width: 1.5,
          ),
        );
      case SoftButtonVariant.ghost:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: borderRadius,
        );
    }
  }

  TextStyle _buildTextStyle([bool disabled = false]) {
    final base = widget.textStyle ?? TextStyle(
      fontWeight: widget.variant == SoftButtonVariant.primary ? FontWeight.bold : FontWeight.w600,
      fontSize: 16,
      color: widget.variant == SoftButtonVariant.primary
          ? (disabled ? AppColors.brandDark.withValues(alpha: 0.5) : AppColors.brandDark)
          : (disabled ? AppColors.brandDark.withValues(alpha: 0.3) : AppColors.brandDark),
    );
    return base;
  }
}
