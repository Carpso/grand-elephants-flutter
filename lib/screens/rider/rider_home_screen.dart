import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/cart_item.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/providers/rider_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class RiderHomeScreen extends StatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  State<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends State<RiderHomeScreen> {
  String _activeTab = 'incoming';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RiderProvider>().load();
    });
  }

  List<Order> _getOrdersByTab(List<Order> orders) {
    return orders.where((order) {
      final s = order.status;
      if (_activeTab == 'incoming') return s == 'Confirmed' || s == 'Processing' || s == 'Pending';
      if (_activeTab == 'active') return s == 'Shipped' || s == 'Out for Delivery';
      if (_activeTab == 'history') return s == 'Delivered' || s == 'Cancelled' || s == 'Refunded';
      return false;
    }).toList();
  }

  Future<void> _onRefresh() async {
    await context.read<RiderProvider>().load();
  }

  Future<void> _updateOrderStatus(Order order, String newStatus) async {
    try {
      await context.read<RiderProvider>().updateOrderStatus(order.id, newStatus);
      if (mounted) {
        ToastProvider.of(context).show('Order ${order.id} is now $newStatus', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final rider = context.watch<RiderProvider>();
    final currentOrders = _getOrdersByTab(rider.deliveries);

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
                  if (_activeTab == 'incoming') _buildStats(config, rider),
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
                    _buildEmptyState(rider)
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

  Widget _buildStats(ConfigProvider config, RiderProvider rider) {
    final available = rider.deliveries
        .where((o) => o.status == 'Confirmed' || o.status == 'Processing' || o.status == 'Pending')
        .length;
    final balance = rider.balance;

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
                    '$available',
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
                    config.formatPrice(balance),
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

  Widget _buildEmptyState(RiderProvider rider) {
    final message = rider.loading
        ? 'Loading your deliveries...'
        : rider.error != null
            ? 'Could not load deliveries. Pull to refresh.'
            : 'No orders found.';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.local_shipping, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
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
          _buildRouteInfo(order),
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
              onPressed: () => _updateOrderStatus(order, 'Shipped'),
            ),
          if (_activeTab == 'active')
            SoftButton(
              title: 'Mark Delivered',
              variant: SoftButtonVariant.secondary,
              onPressed: () => _updateOrderStatus(order, 'Delivered'),
            ),
        ],
      ),
    );
  }

  Widget _buildRouteInfo(Order order) {
    final businessName = order.businessName?.isNotEmpty == true
        ? order.businessName!
        : context.read<ConfigProvider>().appName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.store, size: 16, color: AppColors.brandSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                businessName,
                style: const TextStyle(fontSize: 14, color: AppColors.brandSecondary),
              ),
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
            Expanded(
              child: Text(
                order.deliveryAddress.isEmpty
                    ? 'Customer address on delivery'
                    : order.deliveryAddress,
                style: const TextStyle(fontSize: 14, color: AppColors.brandSecondary),
              ),
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