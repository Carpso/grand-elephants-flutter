import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/cart_provider.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final orders = cart.orders;

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
      ),
      body: orders.isNotEmpty
          ? ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed(
                    '/orders/${order.id}',
                    arguments: order.id,
                  ),
                  child: SoftCard(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order.id}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandDark,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: order.status == 'Delivered'
                                    ? Colors.green.shade100
                                    : Colors.yellow.shade100,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                order.status,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: order.status == 'Delivered'
                                      ? Colors.green.shade700
                                      : Colors.yellow.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.date,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${order.items.length} Items',
                              style: const TextStyle(
                                color: Color(0xFF4B5563),
                              ),
                            ),
                            Text(
                              'K ${order.total.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            )
          : _buildEmptyState(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag,
            size: 64,
            color: Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 16),
          const Text(
            'No orders yet',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Looks like you haven\'t placed any orders yet.',
            textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF9CA3AF),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
