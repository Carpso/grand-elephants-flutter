import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/config_provider.dart';

class PriceTag extends StatelessWidget {
  final double amount;
  final TextStyle? style;

  const PriceTag({
    super.key,
    required this.amount,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    return Text(
      config.formatPrice(amount),
      style: (style ?? const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.brandDark,
      )),
    );
  }
}
