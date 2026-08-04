import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';

class AppBackButton extends StatelessWidget {
  final Color? color;
  final VoidCallback? onPressed;

  const AppBackButton({super.key, this.color, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 0),
      child: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: color ?? AppColors.brandDark,
          size: 24,
        ),
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        splashRadius: 20,
      ),
    );
  }
}
