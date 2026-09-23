import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/cart_item.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/services/api_client.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  bool _loading = true;
  Map<String, dynamic> _business = const {};
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/api/businesses/me'),
        ApiClient.instance.get('/api/businesses/me/orders'),
      ]);
      final data = results[0] as Map<String, dynamic>;
      _business =
          (data['business'] as Map<String, dynamic>?) ?? data;
      _orders = (results[1] as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Business home load failed: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  double get _revenue => _orders.fold(0.0, (sum, o) => sum + o.total);
  double get _balance => ((_business['balanceCents'] as num?)?.toInt() ?? 0) / 100;
  double get _held => ((_business['heldCents'] as num?)?.toInt() ?? 0) / 100;
  int get _staffCount => (_business['staff'] as List?)?.length ?? 0;
  int get _riderCount => (_business['riders'] as List?)?.length ?? 0;

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final name = (_business['name'] as String?) ?? 'Your Business';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Suite'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Finance Overview',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.brandMuted,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SoftCard(
                  child: Column(
                    children: [
                      const Text(
                        'Total Sales',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brandMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loading ? '...' : config.formatPrice(_revenue),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SoftCard(
                  child: Column(
                    children: [
                      const Text(
                        'Orders',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brandMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loading ? '...' : '${_orders.length}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wallet Balance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _loading ? '...' : config.formatPrice(_balance),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'On hold: ${_loading ? '...' : config.formatPrice(_held)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.brandMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: SoftCard(
                  child: Column(
                    children: [
                      const Text(
                        'Staff',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brandMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loading ? '...' : '$_staffCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SoftCard(
                  child: Column(
                    children: [
                      const Text(
                        'Riders',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brandMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _loading ? '...' : '$_riderCount',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'Recent Orders',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                  color: AppColors.brandPrimary,
                ),
              ),
            )
          else if (_orders.isEmpty)
            const Text(
              'No orders yet.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.brandMuted,
              ),
            )
          else
            ..._orders.take(5).map((order) => SoftCard(
                  margin: const EdgeInsets.only(bottom: 12),
                  onTap: () => Navigator.of(context)
                      .pushNamed('/orders/${order.id}', arguments: order.id),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order.status} • ${order.date}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.brandMuted,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        config.formatPrice(order.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                )),
        ],
      ),
    );
  }
}