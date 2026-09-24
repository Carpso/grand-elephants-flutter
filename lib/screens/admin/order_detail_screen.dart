import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/cart_item.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_card.dart';

class OrderDetailScreen extends StatefulWidget {
  final String? orderId;

  const OrderDetailScreen({super.key, this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _orderId {
    final routeId = ModalRoute.of(context)?.settings.arguments as String?;
    return widget.orderId ?? routeId ?? '';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final id = _orderId;
    if (id.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'No order id provided.';
      });
      return;
    }
    try {
      final res = await ApiClient.instance.get('/api/orders/$id');
      if (!mounted) return;
      final data = res as Map<String, dynamic>;
      final orderJson = data['order'] is Map ? data['order'] as Map<String, dynamic> : data;
      setState(() {
        _order = Order.fromJson(orderJson);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e'.replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  String _formatCents(int cents) {
    final amount = cents / 100;
    final parts = amount.toStringAsFixed(2).split('.');
    final buf = StringBuffer();
    for (var i = 0; i < parts[0].length; i++) {
      if (i > 0 && (parts[0].length - i) % 3 == 0) buf.write(',');
      buf.write(parts[0][i]);
    }
    return 'K ${buf.toString()}.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final orderId = _orderId;

    return Scaffold(
      appBar: AppBar(title: Text(orderId.isEmpty ? 'Order Detail' : 'Order #$orderId')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 56, color: AppColors.brandMuted),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.brandMuted),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildOrder(_order!),
    );
  }

  Widget _buildOrder(Order order) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SoftCard(
            padding: const EdgeInsets.all(20),
            child: Container(
              decoration: const BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.brandPrimary, width: 4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CURRENT STATUS',
                    style: TextStyle(color: AppColors.brandMuted, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.status,
                    style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.brandDark),
                  ),
                  if (order.date.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Placed on ${order.date}',
                      style: const TextStyle(color: AppColors.brandMuted, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark),
                ),
                const SizedBox(height: 12),
                if (order.customerPhone != null && order.customerPhone!.isNotEmpty)
                  _buildInfoRow(Icons.phone, order.customerPhone!),
                if (order.businessName != null && order.businessName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: _buildInfoRow(Icons.storefront, order.businessName!),
                  ),
                if (order.deliveryAddress.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_pin, size: 20, color: AppColors.brandMuted),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.deliveryAddress,
                          style: const TextStyle(color: AppColors.brandSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
                if (order.riderName != null && order.riderName!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.delivery_dining, order.riderName!),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Items',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark),
                ),
                const SizedBox(height: 16),
                if (order.items.isEmpty)
                  const Text('No items in this order.', style: TextStyle(color: AppColors.brandMuted))
                else
                  ...order.items.map((CartItem item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.shopping_bag, size: 20, color: AppColors.brandMuted),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark)),
                                  Text('Qty: ${item.quantity}', style: const TextStyle(color: AppColors.brandMuted, fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              _formatCents(item.priceCents * item.quantity),
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark),
                            ),
                          ],
                        ),
                      )),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
                    Text(
                      _formatCents(order.totalCents),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.brandPrimary),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (order.invoiceNo != null && order.invoiceNo!.isNotEmpty)
            SoftCard(
              child: Row(
                children: [
                  const Icon(Icons.receipt, size: 20, color: AppColors.brandPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Invoice ${order.invoiceNo} • ${order.invoiceStatus ?? 'issued'}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark),
                    ),
                  ),
                  Text(
                    'Payment: ${order.paymentStatus}',
                    style: const TextStyle(color: AppColors.brandMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),
          SoftCard(
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 20, color: AppColors.brandSecondary),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Admins cannot reassign riders or refund orders from this app. Status changes are managed in the backend or the rider app. Contact admin support to refund this order.',
                    style: TextStyle(color: AppColors.brandSecondary, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton(
              onPressed: _load,
              child: const Text('Refresh', style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.brandMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(color: AppColors.brandSecondary, fontWeight: FontWeight.w500)),
        ),
      ],
    );
  }
}