import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/price_tag.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class OrderDetailScreen extends StatefulWidget {
  final String? orderId;

  const OrderDetailScreen({super.key, this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  String _status = 'Processing';
  String? _rider;
  bool _riderModalVisible = false;

  final List<_AvailableRider> _availableRiders = const [
    _AvailableRider(id: 1, name: 'Kyle Reese', status: 'Available', distance: '1.2km'),
    _AvailableRider(id: 2, name: 'T-800 Model', status: 'Busy', distance: '3.5km'),
    _AvailableRider(id: 3, name: 'Sarah Connor', status: 'Available', distance: '0.5km'),
  ];

  void _assignRider(String riderName) {
    setState(() {
      _rider = riderName;
      _status = 'Assigned';
      _riderModalVisible = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$riderName has been assigned to this order.')),
    );
  }

  void _handleRefund() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Refund'),
        content: const Text('Are you sure you want to refund this order? K 1,200 will be returned to the customer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _status = 'Refunded');
              Navigator.pop(ctx);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Refund'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderId = widget.orderId ?? '8842';

    return Scaffold(
      appBar: AppBar(title: Text('Order #$orderId')),
      body: SingleChildScrollView(
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'CURRENT STATUS',
                          style: TextStyle(color: AppColors.brandMuted, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                        ),
                        Text(
                          'Updated 10m ago',
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _status,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.brandDark),
                    ),
                    if (_rider != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Rider: $_rider',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
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
                  _buildInfoRow(Icons.person, 'John Doe'),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.phone, '+260 97 123 4567'),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_pin, size: 20, color: AppColors.brandMuted),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Plot 44, Independence Avenue, Lusaka',
                          style: TextStyle(color: AppColors.brandSecondary, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
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
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Royal Elephant Tote', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark)),
                            Text('Qty: 1', style: TextStyle(color: AppColors.brandMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      const Text('K 1,200', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
                      PriceTag(amount: 1200),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Actions',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark),
            ),
            const SizedBox(height: 12),
            SoftButton(
              title: _rider != null ? 'Reassign Rider' : 'Assign Rider',
              variant: SoftButtonVariant.primary,
              icon: const Icon(Icons.delivery_dining, size: 20, color: AppColors.brandDark),
              onPressed: () => setState(() => _riderModalVisible = true),
            ),
            const SizedBox(height: 12),
            SoftButton(
              title: 'Issue Refund',
              variant: SoftButtonVariant.outline,
              icon: const Icon(Icons.money_off, size: 20, color: AppColors.error),
              onPressed: _handleRefund,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.brandMuted),
        const SizedBox(width: 12),
        Text(text, style: const TextStyle(color: AppColors.brandSecondary, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _AvailableRider {
  final int id;
  final String name;
  final String status;
  final String distance;

  const _AvailableRider({
    required this.id,
    required this.name,
    required this.status,
    required this.distance,
  });
}
