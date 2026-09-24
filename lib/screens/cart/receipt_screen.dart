import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/toast.dart';
import 'package:grand_elephants/providers/cart_provider.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/models/cart_item.dart';
import 'package:grand_elephants/services/receipt_service.dart';

class ReceiptScreen extends StatefulWidget {
  const ReceiptScreen({super.key});

  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  Order? _order;
  OrderReceipt? _serverReceipt;
  bool _loading = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final orderId =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final cart = context.read<CartProvider>();
    Order? order;
    if (orderId.isNotEmpty) {
      order = await cart.fetchOrder(orderId);
    } else if (cart.orders.isNotEmpty) {
      order = cart.orders.first;
    }

    // Server receipt (owner/rider/business manager authorised) — powers the
    // PDF. Falls back to local order data when the endpoint is unreachable.
    OrderReceipt? receipt;
    final receiptId = orderId.isNotEmpty
        ? orderId
        : (order?.id ?? '');
    if (receiptId.isNotEmpty) {
      try {
        receipt = await ReceiptService.fetch(receiptId);
      } catch (e) {
        debugPrint('Receipt fetch failed: $e');
      }
    }

    if (!mounted) return;
    setState(() {
      _order = order;
      _serverReceipt = receipt;
      _loading = false;
    });
  }

  /// Receipt used for printing: server payload when available, otherwise a
  /// locally built one from the order the client already holds.
  OrderReceipt? _receiptFor(Order order, ConfigProvider config) {
    if (_serverReceipt != null) return _serverReceipt;
    return OrderReceipt.fromOrder(
      order,
      businessName: order.businessName ?? '',
      vatPct: config.taxRate,
    );
  }

  Future<void> _print(Order order, ConfigProvider config) async {
    final receipt = _receiptFor(order, config);
    if (receipt == null) return;
    setState(() => _busy = true);
    try {
      await ReceiptService.print(receipt);
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show(
        'Could not open the print dialog. Please try again.',
        ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _share(Order order, ConfigProvider config) async {
    final receipt = _receiptFor(order, config);
    if (receipt == null) return;
    setState(() => _busy = true);
    try {
      final shared = await ReceiptService.share(receipt);
      if (!mounted) return;
      if (!shared) {
        ToastProvider.of(context)
            .show('Sharing is not available here', ToastType.info);
      }
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show(
        'Could not share the receipt. Please try again.',
        ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final config = context.watch<ConfigProvider>();
    final order = _order ?? (cart.orders.isNotEmpty ? cart.orders.first : null);

    return Scaffold(
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandPrimary),
            )
          : order == null
              ? SafeArea(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.receipt_long,
                              size: 64, color: AppColors.brandMuted),
                          const SizedBox(height: 16),
                          Text(
                            'No recent order found.',
                            style: TextStyle(
                                color: AppColors.brandMuted, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          SoftButton(
                            title: 'Return Home',
                            variant: SoftButtonVariant.secondary,
                            onPressed: () => Navigator.pushReplacementNamed(
                                context, '/home'),
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
                                  _receiptRow(
                                      'Invoice #', order.invoiceNo ?? 'Pending'),
                                  const SizedBox(height: 8),
                                  _receiptRow(
                                      'Payment',
                                      order.paymentStatus == 'successful'
                                          ? 'Paid'
                                          : order.paymentStatus),
                                  if ((_serverReceipt?.buyerTpin ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    _receiptRow(
                                        'Buyer TPIN', _serverReceipt!.buyerTpin),
                                  ],
                                  if (order.invoiceNo == null ||
                                      order.invoiceNo!.isEmpty) ...[
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        'Invoice issued after payment confirmation',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontStyle: FontStyle.italic,
                                          color: AppColors.brandMuted,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                children: [
                                  ...order.items.map((item) => Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 8),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${item.quantity}x ${item.name}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      AppColors.brandSecondary,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              config.formatPrice(
                                                  item.price * item.quantity),
                                              style: const TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold),
                                            ),
                                          ],
                                        ),
                                      )),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  _receiptRow(
                                      'Subtotal',
                                      config.formatPrice(
                                          order.total /
                                              (1 + config.taxRate / 100))),
                                  const SizedBox(height: 4),
                                  _receiptRow(
                                    'VAT (${config.taxRate.toStringAsFixed(0)}%)',
                                    config.formatPrice(order.total *
                                        config.taxRate /
                                        (100 + config.taxRate)),
                                  ),
                                  const Divider(thickness: 1),
                                  const SizedBox(height: 12),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
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
                                    width: 120,
                                    height: 120,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: CustomPaint(
                                      painter: _QrPainter(data: order.id),
                                      size: const Size.square(104),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Order ${order.id}',
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 12,
                                      color: AppColors.brandDark,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    order.invoiceNo == null ||
                                            order.invoiceNo!.isEmpty
                                        ? 'Awaiting fiscal signature'
                                        : 'Fiscal Signature: ${order.invoiceNo}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.brandMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: SoftButton(
                              title: _busy ? 'Working...' : 'Print / Save PDF',
                              variant: SoftButtonVariant.primary,
                              isLoading: _busy,
                              icon: const Icon(
                                Icons.print,
                                size: 20,
                                color: AppColors.brandDark,
                              ),
                              onPressed:
                                  _busy ? null : () => _print(order, config),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SoftButton(
                              title: 'Share',
                              variant: SoftButtonVariant.secondary,
                              isLoading: _busy,
                              icon: const Icon(
                                Icons.share,
                                size: 20,
                                color: AppColors.brandPrimary,
                              ),
                              onPressed:
                                  _busy ? null : () => _share(order, config),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SoftButton(
                        title: 'Back to Home',
                        variant: SoftButtonVariant.outline,
                        onPressed: () => Navigator.pushReplacementNamed(
                            context, '/home'),
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

class _QrPainter extends CustomPainter {
  final String data;

  _QrPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    const n = 21;
    final cell = size.width / n;
    final cells = List.generate(n, (i) => List<bool>.filled(n, false));

    void finder(int ox, int oy) {
      for (var y = 0; y < 7; y++) {
        for (var x = 0; x < 7; x++) {
          final ring = x == 0 || y == 0 || x == 6 || y == 6;
          final core = (x >= 2 && x <= 4) && (y >= 2 && y <= 4);
          cells[oy + y][ox + x] = ring || core;
        }
      }
    }

    finder(0, 0);
    finder(0, n - 7);
    finder(n - 7, 0);

    var seed = 0;
    for (final unit in data.codeUnits) {
      seed = (seed * 31 + unit) & 0x7fffffff;
    }
    final rng = Random(seed);
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        final inFinder = (x < 8 && y < 8) ||
            (x < 8 && y >= n - 8) ||
            (y < 8 && x >= n - 8);
        if (inFinder) continue;
        cells[y][x] = rng.nextBool();
      }
    }

    final paint = Paint()..color = AppColors.brandDark;
    for (var y = 0; y < n; y++) {
      for (var x = 0; x < n; x++) {
        if (cells[y][x]) {
          canvas.drawRect(
            Rect.fromLTWH(x * cell, y * cell, cell, cell),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _QrPainter oldDelegate) =>
      oldDelegate.data != data;
}