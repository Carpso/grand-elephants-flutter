import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/cart_provider.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';

enum _PaymentMethod { momo, card }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addressController = TextEditingController(text: 'Kabulonga, Lusaka');
  final _phoneController = TextEditingController();
  final _distanceController = TextEditingController(text: '3');
  final _tpinController = TextEditingController();

  _PaymentMethod _paymentMethod = _PaymentMethod.momo;
  bool _needTaxInvoice = false;
  bool _isProcessing = false;
  String? _tpinError;

  @override
  void dispose() {
    _addressController.dispose();
    _phoneController.dispose();
    _distanceController.dispose();
    _tpinController.dispose();
    super.dispose();
  }

  /// Normalises the buyer TPIN: strips spaces/hyphens, returns `null` when
  /// left blank (the field is optional) and throws nothing — the caller gets
  /// a 10-digit string or an inline error.
  String? _normalizedTpin() {
    final value = _tpinController.text.replaceAll(RegExp(r'[\s-]'), '');
    if (value.isEmpty) return null;
    if (!RegExp(r'^\d{10}$').hasMatch(value)) return '';
    return value;
  }

  void _onTpinChanged(String value) {
    if (_tpinError == null) return;
    final normalized = value.replaceAll(RegExp(r'[\s-]'), '');
    if (normalized.isEmpty || RegExp(r'^\d{10}$').hasMatch(normalized)) {
      setState(() => _tpinError = null);
    }
  }

  Future<void> _handlePayment() async {
    final cart = context.read<CartProvider>();

    if (cart.items.isEmpty) {
      ToastProvider.of(context).show('Your cart is empty!', ToastType.error);
      return;
    }

    final tpin = _normalizedTpin();
    if (tpin != null && tpin.isEmpty) {
      setState(() => _tpinError = 'TPIN must be exactly 10 digits');
      return;
    }
    if (_tpinError != null) setState(() => _tpinError = null);

    final distanceKm = double.tryParse(_distanceController.text) ?? 0;

    setState(() => _isProcessing = true);

    try {
      final order = await cart.submitOrder(
        paymentMethod: _paymentMethod == _PaymentMethod.momo ? 'mobile_money' : 'card',
        deliveryAddress: _addressController.text.trim(),
        deliveryMethod: 'standard',
        deliveryKm: distanceKm,
        customerPhone: _phoneController.text.trim(),
        tpin: tpin,
      );

      if (!mounted) return;
      setState(() => _isProcessing = false);

      if (order == null) {
        ToastProvider.of(context).show('Failed to place order. Please try again.', ToastType.error);
        return;
      }

      HapticFeedback.mediumImpact();

      if (_paymentMethod == _PaymentMethod.card) {
        ToastProvider.of(context).show(
          'Order placed. Complete card payment from the link sent.',
          ToastType.info,
        );
        Navigator.of(context).pushReplacementNamed('/cart/checkout/success', arguments: order.id);
        return;
      }

      if (_needTaxInvoice) {
        Navigator.of(context).pushReplacementNamed('/cart/receipt', arguments: order.id);
      } else {
        Navigator.of(context).pushReplacementNamed('/cart/checkout/success', arguments: order.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
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
                const SizedBox(height: 12),
                Text(
                  'Distance (km) — affects the delivery fee',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _distanceController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    LengthLimitingTextInputFormatter(4),
                  ],
                  decoration: InputDecoration(
                    hintText: 'e.g. 3',
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade100),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Delivery fee: K25 + K10/km · 16% VAT applies on the order total',
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
                    Text('Delivery Fee (est.)', style: TextStyle(color: AppColors.brandMuted)),
                    Text(
                      config.formatPrice((double.tryParse(_distanceController.text) ?? 0) > 0
                          ? 25 + (double.tryParse(_distanceController.text) ?? 0) * 10
                          : cart.deliveryFee),
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total (excl. VAT)',
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
                const SizedBox(height: 8),
                Text(
                  'Final total incl. 16% VAT and payment fees is quoted on the order.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
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
                  'Buyer TPIN (ZRA)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Optional — printed on your tax invoice and receipt.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const SizedBox(height: 12),
                SoftInput(
                  label: 'TPIN',
                  hint: 'e.g. 1000000000 — optional, appears on your receipt',
                  controller: _tpinController,
                  error: _tpinError,
                  onChanged: _onTpinChanged,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9\s-]')),
                    LengthLimitingTextInputFormatter(14),
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
            Text('Mobile Number (receives the payment prompt)', style: TextStyle(color: AppColors.brandMuted)),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(12)],
              decoration: InputDecoration(
                hintText: '097xxxxxxx (optional — defaults to your account)',
                filled: true,
                fillColor: AppColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'A payment prompt is sent to your phone. Approve it to confirm the order.',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500, fontStyle: FontStyle.italic),
            ),
          ] else ...[
            Text(
              'Card payments use a secure hosted checkout. You will receive a payment link after ordering.',
              style: TextStyle(fontSize: 13, color: AppColors.brandMuted),
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
            title: _isProcessing ? 'Placing Order...' : 'Place Order',
            variant: SoftButtonVariant.primary,
            onPressed: _isProcessing ? null : _handlePayment,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
