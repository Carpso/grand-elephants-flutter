import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/cart_provider.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/providers/auth_provider.dart';
import 'package:sell_on_app/services/lipila_payment_service.dart';
import 'package:sell_on_app/providers/collection_number_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

enum _PaymentMethod { momo, card }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController(text: 'My Saved Address (Home)');
  final _phoneController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvcController = TextEditingController();

  _PaymentMethod _paymentMethod = _PaymentMethod.momo;
  bool _needTaxInvoice = false;
  bool _isProcessing = false;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvcController.dispose();
    super.dispose();
  }

  void _handleAddressChange(String text) {
    _addressController.text = text;
    _addressController.selection = TextSelection.fromPosition(
      TextPosition(offset: text.length),
    );
    final km = Random().nextInt(13) + 2;
    context.read<CartProvider>().setDeliveryDistance(km.toDouble());
  }

  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) return 'Card number is required';
    final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.length < 13 || cleaned.length > 19) return 'Invalid card number';
    return null;
  }

  String? _validateExpiry(String? value) {
    if (value == null || value.isEmpty) return 'Expiry date is required';
    if (!RegExp(r'^\d{2}/\d{2}$').hasMatch(value)) return 'Use MM/YY format';
    return null;
  }

  String? _validateCvc(String? value) {
    if (value == null || value.isEmpty) return 'CVC is required';
    if (value.length < 3 || value.length > 4) return 'Invalid CVC';
    return null;
  }

  Future<void> _handlePayment() async {
    final cart = context.read<CartProvider>();
    final lipila = context.read<LipilaPaymentService>();
    final collectionProvider = context.read<CollectionNumberProvider>();

    if (cart.items.isEmpty) {
      ToastProvider.of(context).show('Your cart is empty!', ToastType.error);
      return;
    }

    if (_paymentMethod == _PaymentMethod.momo && _phoneController.text.isEmpty) {
      ToastProvider.of(context).show('Please enter your phone number', ToastType.error);
      return;
    }

    if (_paymentMethod == _PaymentMethod.card) {
      if (_validateCardNumber(_cardNumberController.text) != null) {
        ToastProvider.of(context).show('Please enter a valid card number', ToastType.error);
        return;
      }
      if (_validateExpiry(_expiryController.text) != null) {
        ToastProvider.of(context).show('Please enter a valid expiry date', ToastType.error);
        return;
      }
      if (_validateCvc(_cvcController.text) != null) {
        ToastProvider.of(context).show('Please enter a valid CVC', ToastType.error);
        return;
      }
    }

    setState(() => _isProcessing = true);

    String? transactionId;
    String? referenceId;

    try {
      if (_paymentMethod == _PaymentMethod.momo) {
        final collectionNumber = collectionProvider.getDefaultNumber();
        if (collectionNumber == null) {
          ToastProvider.of(context).show('No collection number configured. Contact support.', ToastType.error);
          setState(() => _isProcessing = false);
          return;
        }

        final result = await lipila.collectMobileMoney(
          amount: cart.total,
          customerPhone: _phoneController.text,
          orderReference: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
          collectionNumber: collectionNumber,
        );

        if (result.success) {
          transactionId = result.transactionId;
          referenceId = result.referenceId;
        } else {
          ToastProvider.of(context).show(result.message ?? 'Payment failed', ToastType.error);
          setState(() => _isProcessing = false);
          return;
        }
      }

      if (!mounted) return;

      setState(() => _isProcessing = false);

      final order = await cart.placeOrder(
        paymentMethod: _paymentMethod == _PaymentMethod.momo ? 'mobile_money' : 'card',
        deliveryAddress: _addressController.text,
        deliveryMethod: 'standard',
        customerPhone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        transactionId: transactionId,
        referenceId: referenceId,
      );

      if (!mounted) return;

      setState(() => _isProcessing = false);

      if (order != null) {
        HapticFeedback.mediumImpact();
        if (_needTaxInvoice) {
          Navigator.of(context).pushReplacementNamed('/cart/receipt');
        } else {
          ToastProvider.of(context).show('Order Placed Successfully!', ToastType.success);
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } else {
        ToastProvider.of(context).show('Failed to place order. Please try again.', ToastType.error);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ToastProvider.of(context).show('Payment error: $e', ToastType.error);
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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SoftCard(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Address',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.location_on, color: AppColors.brandPrimary, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _addressController,
                          onChanged: _handleAddressChange,
                          style: TextStyle(
                            color: AppColors.brandSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Typing changes distance calculation (Simulated)',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          SoftCard(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 16),
                ...cart.items.map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${item.quantity}x ${item.name}',
                            style: TextStyle(color: AppColors.textSecondary),
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
                const Divider(thickness: 1),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal', style: TextStyle(color: AppColors.brandMuted)),
                    Text(config.formatPrice(cart.subtotal), style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Delivery Fee', style: TextStyle(color: AppColors.brandMuted)),
                    Text(config.formatPrice(cart.deliveryFee), style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandDark,
                      ),
                    ),
                    Text(
                      config.formatPrice(cart.total),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            'Payment Method',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SoftButton(
                  title: 'Mobile Money',
                  variant: _paymentMethod == _PaymentMethod.momo
                      ? SoftButtonVariant.primary
                      : SoftButtonVariant.outline,
                  onPressed: () => setState(() => _paymentMethod = _PaymentMethod.momo),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SoftButton(
                  title: 'Card',
                  variant: _paymentMethod == _PaymentMethod.card
                      ? SoftButtonVariant.primary
                      : SoftButtonVariant.outline,
                  onPressed: () => setState(() => _paymentMethod = _PaymentMethod.card),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_paymentMethod == _PaymentMethod.momo) ...[
            Text('Select Provider', style: TextStyle(color: AppColors.brandMuted)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: SoftButton(
                    title: 'MTN Money',
                    variant: SoftButtonVariant.primary,
                    onPressed: () {},
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SoftButton(
                    title: 'Airtel Money',
                    variant: SoftButtonVariant.primary,
                    onPressed: () {},
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Mobile Number', style: TextStyle(color: AppColors.brandMuted)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
              decoration: InputDecoration(
                hintText: '097xxxxxxx',
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
          ] else ...[
            Text('Card Number', style: TextStyle(color: AppColors.brandMuted)),
            const SizedBox(height: 8),
            TextField(
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(19)],
              decoration: InputDecoration(
                hintText: '4000 0000 0000 0000',
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [LengthLimitingTextInputFormatter(5)],
                    decoration: InputDecoration(
                      hintText: 'MM/YY',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _cvcController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                    decoration: InputDecoration(
                      hintText: 'CVC',
                      filled: true,
                      fillColor: AppColors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          SoftCard(
            margin: const EdgeInsets.only(bottom: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ZRA Smart Invoice',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandDark,
                      ),
                    ),
                    Text(
                      'Generate tax compliant receipt',
                      style: TextStyle(fontSize: 12, color: AppColors.brandMuted),
                    ),
                  ],
                ),
                Switch(
                  value: _needTaxInvoice,
                  onChanged: (v) => setState(() => _needTaxInvoice = v),
                  activeThumbColor: AppColors.brandPrimary,
                ),
              ],
            ),
          ),
          SoftButton(
            title: _isProcessing ? 'Processing...' : 'Pay ${config.formatPrice(cart.total)}',
            variant: SoftButtonVariant.primary,
            onPressed: _isProcessing ? null : _handlePayment,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
