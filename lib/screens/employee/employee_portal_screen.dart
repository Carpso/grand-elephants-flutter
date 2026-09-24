import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/cart_item.dart';
import 'package:grand_elephants/providers/auth_provider.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_card.dart';

class EmployeePortalScreen extends StatefulWidget {
  const EmployeePortalScreen({super.key});

  @override
  State<EmployeePortalScreen> createState() => _EmployeePortalScreenState();
}

class _EmployeePortalScreenState extends State<EmployeePortalScreen> {
  DateTime? _clockIn;
  bool _loading = true;
  int _orderCount = 0;
  double _total = 0;

  @override
  void initState() {
    super.initState();
    _clockIn = DateTime.now();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.role == 'admin' || auth.user?.role == 'admin';
    try {
      if (isAdmin) {
        final res = await ApiClient.instance.get('/api/admin/stats');
        final data = res as Map<String, dynamic>;
        _orderCount = (data['orders'] as num?)?.toInt() ?? 0;
        _total = ((data['gmvCents'] as num?)?.toInt() ?? 0) / 100;
      } else {
        final res = await ApiClient.instance.get('/api/orders');
        final orders = (res as List)
            .map((e) => Order.fromJson(e as Map<String, dynamic>))
            .toList();
        _orderCount = orders.length;
        _total = orders.fold(0.0, (sum, o) => sum + o.total);
      }
    } catch (e) {
      debugPrint('Employee stats load failed: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final suffix = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final config = context.watch<ConfigProvider>();
    final name = auth.user?.name ?? 'Employee';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Portal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ],
            ),
          ),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clocked In',
                  style: TextStyle(color: AppColors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  _clockIn != null ? _formatTime(_clockIn!) : '--:--',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: AppColors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                if (_loading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Sales',
                          style: TextStyle(color: AppColors.white)),
                      Text(
                        config.formatPrice(_total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Orders',
                          style: TextStyle(color: AppColors.white)),
                      Text(
                        '$_orderCount',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 16),
          SoftCard(
            margin: const EdgeInsets.only(bottom: 16),
            onTap: () => Navigator.of(context).pushNamed('/orders'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.softSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.receipt_long,
                          color: AppColors.brandSecondary),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'View Orders',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.brandDark,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right, color: AppColors.brandMuted),
              ],
            ),
          ),
          SoftCard(
            onTap: () => Navigator.of(context).pushNamed('/profile/wishlist'),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.softSurface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.favorite_border,
                          color: AppColors.brandSecondary),
                    ),
                    const SizedBox(width: 16),
                    const Text(
                      'View Wishlist',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.brandDark,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.chevron_right, color: AppColors.brandMuted),
              ],
            ),
          ),
        ],
      ),
    );
  }
}