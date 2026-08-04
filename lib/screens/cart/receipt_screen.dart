import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/providers/cart_provider.dart';
import 'package:sell_on_app/providers/config_provider.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final config = context.watch<ConfigProvider>();
    final orders = cart.orders;
    final order = orders.isNotEmpty ? orders.first : null;

    return Scaffold(
      body: order == null
          ? SafeArea(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.receipt_long, size: 64, color: AppColors.brandMuted),
                      const SizedBox(height: 16),
                      Text(
                        'No recent order found.',
                        style: TextStyle(color: AppColors.brandMuted, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      SoftButton(
                        title: 'Return Home',
                        variant: SoftButtonVariant.secondary,
                        onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  SoftCard(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(16),
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            color: AppColors.brandDark,
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                config.appName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 24,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'TAX INVOICE',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(
                                color: Color(0xFFE5E7EB),
                                style: BorderStyle.solid,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              _receiptRow('Date', order.date),
                              const SizedBox(height: 8),
                              _receiptRow('Invoice #', 'INV-${order.id}'),
                              const SizedBox(height: 8),
                              _receiptRow('TPIN', '1001234567'),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              ...order.items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            '${item.quantity}x ${item.name}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.brandSecondary,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          config.formatPrice(item.price * item.quantity),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ],
                                    ),
                                  )),
                              const Divider(),
                              const SizedBox(height: 16),
                              _receiptRow('Subtotal', config.formatPrice(order.total / (1 + config.taxRate / 100))),
                              const SizedBox(height: 4),
                              _receiptRow(
                                'VAT (${config.taxRate.toStringAsFixed(0)}%)',
                                config.formatPrice(order.total * config.taxRate / (100 + config.taxRate)),
                              ),
                              const Divider(thickness: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: AppColors.brandDark,
                                    ),
                                  ),
                                  Text(
                                    config.formatPrice(order.total),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: AppColors.brandPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '||| ||||| || |||||| |||',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Fiscal Signature: FA-2025-X99',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.brandDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SoftButton(
                    title: 'Back to Home',
                    variant: SoftButtonVariant.secondary,
                    onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.brandMuted)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
