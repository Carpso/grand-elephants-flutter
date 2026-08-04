import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/cart_item.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/services/storage_service.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  List<Order> _orders = [];
  String _activeTab = 'incoming';

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    try {
      final data = await StorageService.get<List<dynamic>>('global_orders');
      if (data != null) {
        setState(() {
          _orders = data
              .map((e) => Order.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    final updatedOrders = _orders.map((o) {
      if (o.id == orderId) {
        return Order(
          id: o.id,
          items: o.items,
          total: o.total,
          date: o.date,
          status: newStatus,
        );
      }
      return o;
    }).toList();
    setState(() => _orders = updatedOrders);
    await StorageService.save(
        'global_orders', updatedOrders.map((e) => e.toJson()).toList());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order updated to $newStatus')),
      );
    }
  }

  List<Order> _getOrdersByTab() {
    return _orders.where((order) {
      final s = order.status;
      if (_activeTab == 'incoming') return s == 'Pending';
      if (_activeTab == 'active') return s == 'On the Way';
      if (_activeTab == 'history') return s == 'Delivered' || s == 'Cancelled';
      return false;
    }).toList();
  }

  Future<void> _onRefresh() async {
    await _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final currentOrders = _getOrdersByTab();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rider Dashboard'),
      ),
      body: Column(
        children: [
          _buildTabs(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_activeTab == 'incoming') _buildStats(config),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Text(
                      '${_activeTab[0].toUpperCase()}${_activeTab.substring(1)} Orders (${currentOrders.length})',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brandDark,
                      ),
                    ),
                  ),
                  if (currentOrders.isEmpty)
                    _buildEmptyState()
                  else
                    ...currentOrders.map((order) => _buildOrderCard(order)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: ['incoming', 'active', 'history'].map((tab) {
          final isActive = _activeTab == tab;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: SoftButton(
                title: tab[0].toUpperCase() + tab.substring(1),
                variant: isActive
                    ? SoftButtonVariant.primary
                    : SoftButtonVariant.secondary,
                onPressed: () => setState(() => _activeTab = tab),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStats(ConfigProvider config) {
    final pendingCount = _orders.where((o) => o.status == 'Pending').length;
    final deliveredCount = _orders.where((o) => o.status == 'Delivered').length;
    final earnings = deliveredCount * 25;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'AVAILABLE',
                    style: TextStyle(
                      color: AppColors.brandMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$pendingCount',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'EARNINGS',
                    style: TextStyle(
                      color: AppColors.brandMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'K $earnings',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.local_shipping, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No orders found.',
            style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = order.status == 'Pending'
        ? Colors.amber.shade100
        : order.status == 'Delivered'
            ? Colors.green.shade100
            : Colors.blue.shade100;
    final statusTextColor = order.status == 'Pending'
        ? Colors.amber.shade700
        : order.status == 'Delivered'
            ? Colors.green.shade700
            : Colors.blue.shade700;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '#${order.id}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.brandDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(order.date),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.brandMuted,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  order.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusTextColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRouteInfo(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.items.length} Items',
                style: const TextStyle(fontSize: 12, color: AppColors.brandMuted),
              ),
              Text(
                'K ${order.total.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_activeTab == 'incoming')
            SoftButton(
              title: 'Accept Delivery',
              variant: SoftButtonVariant.primary,
              onPressed: () => _updateOrderStatus(order.id, 'On the Way'),
            ),
          if (_activeTab == 'active')
            SoftButton(
              title: 'Mark Delivered',
              variant: SoftButtonVariant.secondary,
              onPressed: () => _updateOrderStatus(order.id, 'Delivered'),
            ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.store, size: 16, color: AppColors.brandSecondary),
            const SizedBox(width: 8),
            Text(
              '${context.read<ConfigProvider>().appName} HQ',
              style: const TextStyle(fontSize: 14, color: AppColors.brandSecondary),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            width: 1,
            height: 16,
            decoration: const BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: AppColors.brandMuted,
                  style: BorderStyle.solid,
                ),
              ),
            ),
          ),
        ),
        Row(
          children: [
            const Icon(Icons.person, size: 16, color: AppColors.brandSecondary),
            const SizedBox(width: 8),
            const Text(
              'Customer (Plot 44)',
              style: TextStyle(fontSize: 14, color: AppColors.brandSecondary),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(String date) {
    try {
      final dt = DateTime.parse(date);
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return date;
    }
  }
}
