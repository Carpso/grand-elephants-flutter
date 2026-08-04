import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/cart_item.dart';
import 'package:sell_on_app/providers/cart_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  static const _mockShippingAddress = '123 Independence Avenue, Lusaka, Zambia';
  static const _mockPaymentMethod = 'Airtel Money (*** 1234)';

  @override
  Widget build(BuildContext context) {
    final orderId = ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final cart = context.watch<CartProvider>();
    final realOrder = cart.orders.where((o) => o.id == orderId).firstOrNull;

    final displayId = realOrder?.id ?? 'ORD-2023-8821';
    final displayDate = realOrder?.date ?? 'Dec 12, 2023, 10:30 AM';
    final displayStatus = realOrder?.status ?? 'Delivered';
    final displayTotal = realOrder?.total ?? 5300.0;

    final items = realOrder?.items ?? [
      CartItem(id: '1', name: 'Royal Gold Handbag', price: 3500, image: 'assets/products/luxury_handbag_gold_1765539658142.png'),
      CartItem(id: '2', name: 'Chic Beige Tote', price: 1800, image: 'assets/products/chic_tote_bag_beige_1765539674873.png'),
    ];

    final shippingAddress = realOrder != null ? 'Standard Delivery Address' : _mockShippingAddress;
    final paymentMethod = realOrder != null ? 'Online Payment' : _mockPaymentMethod;

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      appBar: AppBar(
        title: Text('Order #$orderId'),
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
            _buildInfoRow(shippingAddress, paymentMethod),
            const SizedBox(height: 24),
            _buildSummary(displayTotal),
            const SizedBox(height: 24),
            SoftButton(
              title: 'Buy Again',
              variant: SoftButtonVariant.primary,
              onPressed: () {
                HapticFeedback.heavyImpact();
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('Reorder Initiated'),
                    content: Text('Items have been added to your cart.'),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            SoftButton(
              title: 'Download Invoice',
              variant: SoftButtonVariant.secondary,
              icon: const Icon(Icons.file_download, size: 20, color: AppColors.brandPrimary),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const AlertDialog(
                    title: Text('Download'),
                    content: Text('Invoice PDF downloading...'),
                  ),
                );
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
                  shipping,
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
                'K ${(total - 50).toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shipping',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
              const Text(
                'K 50.00',
                style: TextStyle(
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
