import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/cart_item.dart';
import 'package:sell_on_app/providers/cart_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';

class CheckoutSuccessScreen extends StatefulWidget {
  const CheckoutSuccessScreen({super.key});

  @override
  State<CheckoutSuccessScreen> createState() => _CheckoutSuccessScreenState();
}

class _CheckoutSuccessScreenState extends State<CheckoutSuccessScreen> {
  Order? _order;
  Timer? _pollTimer;
  bool _pending = true;
  int _polls = 0;

  @override
  void initState() {
    super.initState();
    final orderId =
        ModalRoute.of(context)?.settings.arguments as String?;
    _load(orderId);
  }

  Future<void> _load(String? orderId) async {
    if (orderId == null || orderId.isEmpty) {
      final cart = context.read<CartProvider>();
      if (cart.orders.isNotEmpty) {
        _order = cart.orders.first;
        _pending = _order!.paymentStatus == 'pending';
      }
      if (mounted) setState(() {});
      return;
    }
    final order = await context.read<CartProvider>().fetchOrder(orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _pending = order?.paymentStatus == 'pending';
      });
      if (_pending) _startPolling(orderId);
    }
  }

  void _startPolling(String orderId) {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _polls++;
      final order = await context.read<CartProvider>().fetchOrder(orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _pending = order?.paymentStatus == 'pending';
      });
      if (!_pending || _polls >= 24) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paid = _order?.paymentStatus == 'successful';
    final status = _order?.status ?? 'Pending';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 200,
                height: 200,
                child: _pending
                    ? Lottie.network(
                        'https://assets2.lottiefiles.com/packages/lf20_5tl1xxnb.json',
                        repeat: true,
                      )
                    : Lottie.network(
                        'https://assets2.lottiefiles.com/packages/lf20_u4yrau.json',
                        repeat: false,
                      ),
              ).animate().scale(
                    begin: const Offset(0.8, 0.8),
                    duration: 600.ms,
                    curve: Curves.easeOutBack,
                  ),
              const SizedBox(height: 32),
              Column(
                children: [
                  Text(
                    _pending
                        ? 'Awaiting Payment'
                        : paid
                            ? 'Order Confirmed!'
                            : 'Order Placed',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '#${_order?.id ?? ''}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      _pending
                          ? 'A payment prompt was sent to your phone. Approve it and this screen will update automatically.'
                          : paid
                              ? 'Thank you for your purchase. Status: $status'
                              : 'Your order was placed. Status: $status',
                      style: TextStyle(color: AppColors.brandMuted),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 48),
                  SizedBox(
                    width: double.infinity,
                    child: SoftButton(
                      title: 'View Order',
                      variant: SoftButtonVariant.primary,
                      icon: const Icon(Icons.local_shipping, size: 20, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                        Navigator.pushNamed(context, '/orders/${_order?.id ?? ''}',
                            arguments: _order?.id);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: SoftButton(
                      title: 'Continue Shopping',
                      variant: SoftButtonVariant.outline,
                      onPressed: () {
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      },
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms, duration: 500.ms).slideY(begin: 0.1),
            ],
          ),
        ),
      ),
    );
  }
}
