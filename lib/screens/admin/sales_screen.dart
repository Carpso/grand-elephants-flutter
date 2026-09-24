import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/cart_item.dart';
import 'package:grand_elephants/providers/admin_provider.dart';
import 'package:grand_elephants/widgets/soft_card.dart';

class SalesScreen extends StatefulWidget {
  const SalesScreen({super.key});

  @override
  State<SalesScreen> createState() => _SalesScreenState();
}

class _SalesScreenState extends State<SalesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadOrders();
    });
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
    final admin = context.watch<AdminProvider>();
    final orders = admin.orders;

    final successful = orders.where((o) => o.status != 'Cancelled' && o.status != 'Refunded').toList();
    final totalCents = successful.fold<int>(0, (sum, o) => sum + o.totalCents);

    return Scaffold(
      appBar: AppBar(title: const Text('Sales Report')),
      body: RefreshIndicator(
        onRefresh: () => admin.loadOrders(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF111827)]),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
                  ],
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL REVENUE (SUCCESSFUL ORDERS)',
                      style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatCents(totalCents),
                      style: const TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${successful.length}',
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'successful orders',
                          style: TextStyle(color: AppColors.white, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Recent Orders',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
              ),
              const SizedBox(height: 16),
              if (orders.isEmpty)
                admin.error != null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                '${admin.error}'.replaceFirst('Exception: ', ''),
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.brandMuted),
                              ),
                              TextButton(
                                onPressed: () => admin.loadOrders(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(
                          child: Text('No orders yet.', style: TextStyle(color: AppColors.brandMuted)),
                        ),
                      )
              else
                ...orders.map((o) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SoftCard(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '#${o.id}${o.businessName != null ? ' • ${o.businessName}' : ''}',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _itemSummary(o),
                                    style: const TextStyle(color: AppColors.brandMuted, fontSize: 12, fontWeight: FontWeight.w500),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    o.date,
                                    style: const TextStyle(color: AppColors.brandMuted, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatCents(o.totalCents),
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandPrimary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  o.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: o.status == 'Cancelled' || o.status == 'Refunded'
                                        ? AppColors.error
                                        : o.status == 'Delivered'
                                            ? AppColors.success
                                            : AppColors.brandMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  String _itemSummary(Order order) {
    if (order.items.isEmpty) return order.deliveryMethod;
    return order.items.map((CartItem i) => '${i.name} x${i.quantity}').join(', ');
  }
}