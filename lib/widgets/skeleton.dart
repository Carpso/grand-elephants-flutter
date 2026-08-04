import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sell_on_app/constants/app_theme.dart';

class Skeleton extends StatelessWidget {
  final double? width;
  final double? height;
  final double borderRadius;

  const Skeleton({
    super.key,
    this.width,
    this.height = 20,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.brandMuted.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true)).shimmer(
      duration: 1000.ms,
      color: Colors.white.withValues(alpha: 0.3),
    );
  }
}

class SkeletonGroup extends StatelessWidget {
  final int count;
  final double itemHeight;

  const SkeletonGroup({
    super.key,
    this.count = 3,
    this.itemHeight = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        count,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Skeleton(height: itemHeight),
        ),
      ),
    );
  }
}
