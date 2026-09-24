import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/cart_item.dart';
import 'package:grand_elephants/providers/cart_provider.dart';

class TrackingDetailScreen extends StatefulWidget {
  final String orderId;

  const TrackingDetailScreen({super.key, required this.orderId});

  @override
  State<TrackingDetailScreen> createState() => _TrackingDetailScreenState();
}

class _TrackingDetailScreenState extends State<TrackingDetailScreen> {
  Order? _order;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final order = await context.read<CartProvider>().fetchOrder(widget.orderId);
    if (mounted) {
      setState(() {
        _order = order;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order #${widget.orderId}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Delivery Status',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            order != null ? 'Status: ${order.status}' : 'Loading order...',
            style: TextStyle(color: AppColors.brandMuted),
          ),
          const SizedBox(height: 32),
          if (_loading || order == null)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.brandPrimary,
              ),
            )
          else
            ..._buildSteps(order),
        ],
      ),
    );
  }

  List<Widget> _buildSteps(Order order) {
    final statuses = Order.validStatuses;
    final currentIndex = statuses.indexOf(order.status);
    final activeCount = currentIndex >= 0 ? currentIndex + 1 : 1;

    const labels = {
      'Pending': 'Order Placed',
      'Confirmed': 'Order Confirmed',
      'Processing': 'Processing',
      'Shipped': 'Shipped',
      'Out for Delivery': 'Out for Delivery',
      'Delivered': 'Delivered',
      'Cancelled': 'Cancelled',
      'Refunded': 'Refunded',
    };

    final steps = statuses.where((s) => labels.containsKey(s)).toList();

    return List.generate(steps.length, (index) {
      final status = steps[index];
      final isCompleted = status == 'Cancelled'
          ? order.status == 'Cancelled'
          : index < activeCount;
      final isCancelled = order.status == 'Cancelled' || order.status == 'Refunded';

      return Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCompleted ? AppColors.brandPrimary : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    status == 'Delivered' ? Icons.check : Icons.local_shipping,
                    size: 16,
                    color: isCompleted ? Colors.white : AppColors.brandMuted,
                  ),
                ),
                if (index < steps.length - 1)
                  Container(
                    width: 2,
                    height: 60,
                    color: isCompleted ? AppColors.brandPrimary : Colors.grey.shade200,
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      labels[status]!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isCompleted ? AppColors.brandDark : AppColors.brandMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      status == 'Delivered'
                          ? 'Your order has been delivered. Enjoy!'
                          : status == 'Cancelled'
                              ? 'This order was cancelled.'
                              : isCancelled
                                  ? 'Order was cancelled before reaching this step.'
                                  : 'Your order is progressing through fulfilment.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.brandMuted,
                      ),
                    ),
                    if (order.businessName?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Sold by: ${order.businessName}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}