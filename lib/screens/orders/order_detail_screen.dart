import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/cart_item.dart';
import 'package:sell_on_app/models/product.dart';
import 'package:sell_on_app/providers/cart_provider.dart';
import 'package:sell_on_app/widgets/toast.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final cart = context.watch<CartProvider>();
    final order = cart.orders.where((o) => o.id == orderId).firstOrNull;

    final displayId = order?.id ?? orderId;
    final displayDate = order?.date ?? '';
    final displayStatus = order?.status ?? 'Unknown';
    final displayTotal = order?.total ?? 0;

    final items = order?.items ?? [];

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      appBar: AppBar(
        title: Text('Order #$displayId'),
        backgroundColor: const Color(0xFFE0E5EC),
        foregroundColor: AppColors.brandDark,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(displayStatus, displayDate, displayId),
            const SizedBox(height: 24),
            const Text(
              'Items Ordered',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 16),
            ...items.asMap().entries.map((entry) => _buildItemCard(entry.value, entry.key)),
            const SizedBox(height: 16),
            if (order != null) _buildInfoRow(order.deliveryAddress, order.paymentMethod),
            const SizedBox(height: 24),
            _buildSummary(displayTotal),
            const SizedBox(height: 24),
            if (order != null && order.isCancellable)
              SoftButton(
                title: 'Cancel Order',
                variant: SoftButtonVariant.outline,
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  cart.updateOrderStatus(orderId, 'Cancelled');
                  ToastProvider.of(context).show('Order cancelled', ToastType.info);
                  Navigator.pop(context);
                },
              ),
            const SizedBox(height: 12),
            SoftButton(
              title: 'Buy Again',
              variant: SoftButtonVariant.primary,
              onPressed: () {
                HapticFeedback.heavyImpact();
                for (final item in items) {
                  cart.addToCartWithQuantity(
                    Product(
                      id: item.id,
                      name: item.name,
                      price: item.price,
                      image: item.image,
                      description: '',
                      category: '',
                      isGhost: false,
                    ),
                    quantity: item.quantity,
                  );
                }
                  ToastProvider.of(context).show('${items.length} item(s) added to cart', ToastType.success);
                  Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            SoftButton(
              title: 'Download Invoice',
              variant: SoftButtonVariant.secondary,
              icon: const Icon(Icons.file_download, size: 20, color: AppColors.brandPrimary),
              onPressed: () {
                HapticFeedback.mediumImpact();
                ToastProvider.of(context).show('Invoice downloading...', ToastType.info);
              },
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status, String date, String id) {
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 24),
      child: Container(
        decoration: const BoxDecoration(
          border: Border(
            left: BorderSide(color: Colors.green, width: 4),
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Status',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ordered on $date',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Order ID: $id',
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(CartItem item, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SoftCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.softSurface,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  item.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.image,
                    color: AppColors.brandMuted,
                    size: 32,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Qty: ${item.quantity}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'K ${item.price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String shipping, String payment) {
    return Row(
      children: [
        Expanded(
          child: SoftCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on, size: 24, color: AppColors.brandPrimary),
                const SizedBox(height: 8),
                const Text(
                  'Shipping',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  shipping.isEmpty ? 'No address provided' : shipping,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: SoftCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.payment, size: 24, color: AppColors.brandPrimary),
                const SizedBox(height: 8),
                const Text(
                  'Payment',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  payment,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(double total) {
    return SoftCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              Text(
                'K ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Paid',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              Text(
                'K ${total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
