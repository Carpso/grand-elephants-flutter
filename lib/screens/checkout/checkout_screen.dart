import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/soft_input.dart';
import 'package:sell_on_app/providers/cart_provider.dart';
import 'package:sell_on_app/providers/config_provider.dart';

enum _DeliveryMethod { standard, express, pickup }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameController = TextEditingController(text: 'John Doe');
  final _addressController = TextEditingController(text: 'Plot 44, Independence Ave');
  final _cityController = TextEditingController(text: 'Lusaka');
  final _phoneController = TextEditingController(text: '+260 97 123 4567');

  bool _loading = false;
  _DeliveryMethod _deliveryMethod = _DeliveryMethod.standard;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.isNotEmpty &&
      _addressController.text.isNotEmpty &&
      _cityController.text.isNotEmpty &&
      _phoneController.text.isNotEmpty;

  double get _deliveryFee => _deliveryMethod == _DeliveryMethod.express ? 50 : 0;

  double get _cartTotal {
    final cart = context.read<CartProvider>();
    return cart.items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
  }

  double get _total => _cartTotal + _deliveryFee;

  Future<void> _handleCheckout() async {
    if (!_isValid) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all shipping details.')),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _loading = true);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    setState(() => _loading = false);

    final success = Random().nextDouble() > 0.05;
    if (success) {
      HapticFeedback.mediumImpact();
      await context.read<CartProvider>().placeOrder();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/checkout/success');
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment Failed. Transaction declined. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final config = context.watch<ConfigProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),
            const SizedBox(height: 16),
            SoftCard(
              margin: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  ...cart.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${item.quantity}x ${item.name}',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              config.formatPrice(item.price * item.quantity),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      )),
                  const Divider(),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        config.formatPrice(_cartTotal),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandPrimary,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms).slideY(begin: -0.1),
            Text(
              'Delivery Method',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),
            const SizedBox(height: 16),
            Row(
              children: [
                _deliveryOption(_DeliveryMethod.standard, Icons.local_shipping, 'Standard', 'Free'),
                const SizedBox(width: 12),
                _deliveryOption(_DeliveryMethod.express, Icons.rocket_launch, 'Express', 'K 50'),
                const SizedBox(width: 12),
                _deliveryOption(_DeliveryMethod.pickup, Icons.store, 'Pickup', 'Free'),
              ],
            ).animate().fadeIn(delay: 200.ms).slideY(begin: -0.1),
            const SizedBox(height: 40),
            Text(
              'Shipping Details',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.1),
            const SizedBox(height: 16),
            SoftCard(
              margin: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  SoftInput(
                    label: 'Full Name',
                    controller: _nameController,
                    hint: 'John Doe',
                    icon: const Icon(Icons.person, size: 20, color: AppColors.brandMuted),
                    onChanged: (_) => setState(() {}),
                  ),
                  SoftInput(
                    label: 'Address',
                    controller: _addressController,
                    hint: 'Street Address',
                    icon: const Icon(Icons.home, size: 20, color: AppColors.brandMuted),
                    onChanged: (_) => setState(() {}),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: SoftInput(
                          label: 'City',
                          controller: _cityController,
                          hint: 'City',
                          icon: const Icon(Icons.location_city, size: 20, color: AppColors.brandMuted),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SoftInput(
                          label: 'Phone',
                          controller: _phoneController,
                          hint: '+260...',
                          keyboardType: TextInputType.phone,
                          icon: const Icon(Icons.phone, size: 20, color: AppColors.brandMuted),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: -0.1),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Amount',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandMuted,
                    fontSize: 18,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      config.formatPrice(_total),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandDark,
                        fontSize: 28,
                      ),
                    ),
                    if (_deliveryFee > 0)
                      Text(
                        '(Includes ${config.formatPrice(_deliveryFee.toDouble())} delivery)',
                        style: TextStyle(fontSize: 12, color: AppColors.brandMuted),
                      ),
                  ],
                ),
              ],
            ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 24),
            SoftButton(
              title: _loading ? 'Processing...' : 'Pay ${config.formatPrice(_total)}',
              variant: SoftButtonVariant.primary,
              onPressed: _loading ? null : _handleCheckout,
            ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.verified_user, size: 14, color: AppColors.brandSecondary.withValues(alpha: 0.5)),
                const SizedBox(width: 8),
                Text(
                  'Secured by SSL Encryption',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.brandSecondary.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _deliveryOption(_DeliveryMethod method, IconData icon, String label, String price) {
    final isActive = _deliveryMethod == method;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _deliveryMethod = method);
          HapticFeedback.selectionClick();
        },
        child: SoftCard(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive ? AppColors.brandPrimary : AppColors.brandMuted,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                price,
                style: TextStyle(fontSize: 10, color: AppColors.brandMuted),
              ),
            ],
          ),
        ),
        // We manually build the border effect using the parent
      ),
    );
  }
}
