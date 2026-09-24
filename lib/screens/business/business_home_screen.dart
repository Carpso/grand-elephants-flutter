import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/cart_item.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';

/// Shop-owner work screen: finance snapshot, quick actions (products,
/// collection numbers, payout, staff) and order fulfilment straight from the
/// server (`/api/businesses/me*`).
class BusinessHomeScreen extends StatefulWidget {
  const BusinessHomeScreen({super.key});

  @override
  State<BusinessHomeScreen> createState() => _BusinessHomeScreenState();
}

class _BusinessHomeScreenState extends State<BusinessHomeScreen> {
  static const List<String> _statusFlow = [
    'Pending',
    'Confirmed',
    'Processing',
    'Shipped',
    'Out for Delivery',
    'Delivered',
  ];

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _business = const {};
  List<Order> _orders = [];
  String? _busyOrderId;

  @override
  void initState() {
    super.initState();
    _load(showErrors: true);
  }

  Future<void> _load({bool showErrors = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
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
      final message =
          '$e'.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
      if (mounted) _error = message;
      if (showErrors && mounted) {
        ToastProvider.of(context).show(message, ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _revenue => _orders.fold(0.0, (sum, o) => sum + o.total);
  double get _balance => ((_business['balanceCents'] as num?)?.toInt() ?? 0) / 100;
  double get _held => ((_business['heldCents'] as num?)?.toInt() ?? 0) / 100;
  int get _staffCount => (_business['staff'] as List?)?.length ?? 0;
  int get _riderCount => (_business['riders'] as List?)?.length ?? 0;

  String? _nextStatus(String status) {
    final index = _statusFlow.indexOf(status);
    if (index < 0 || index >= _statusFlow.length - 1) return null;
    return _statusFlow[index + 1];
  }

  Future<void> _advanceStatus(Order order) async {
    final next = _nextStatus(order.status);
    if (next == null) return;
    setState(() => _busyOrderId = order.id);
    try {
      await ApiClient.instance
          .post('/api/businesses/me/orders/${order.id}/status', body: {'status': next});
      if (!mounted) return;
      ToastProvider.of(context)
          .show('Order ${order.id} is now $next', ToastType.success);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show(
        '$e'.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''),
        ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Future<void> _requestPayout() async {
    final config = context.read<ConfigProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request Payout'),
        content: Text(
          'Pay out your full wallet balance of ${config.formatPrice(_balance)} '
          'to your default collection number?\n\nMinimum payout is K50 and a '
          'disbursement fee applies.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Request Payout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      final res =
          await ApiClient.instance.post('/api/businesses/me/payout', body: {});
      if (!mounted) return;
      final netCents = res is Map ? (res['netCents'] as num?)?.toInt() : null;
      ToastProvider.of(context).show(
        netCents != null
            ? 'Payout requested — ${config.formatPrice(netCents / 100)} on the way'
            : 'Payout requested',
        ToastType.success,
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show(
        '$e'.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''),
        ToastType.error,
      );
    }
  }

  Future<void> _addStaff() async {
    final phoneController = TextEditingController();
    final nameController = TextEditingController();
    final entry = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Staff Member',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'They get access with their phone number — new numbers are '
                'invited automatically.',
                style: TextStyle(fontSize: 13, color: AppColors.brandMuted),
              ),
              const SizedBox(height: 24),
              SoftInput(
                label: 'Phone Number',
                hint: '0977123456',
                keyboardType: TextInputType.phone,
                controller: phoneController,
              ),
              const SizedBox(height: 12),
              SoftInput(
                label: 'Name (optional)',
                hint: 'e.g. Mary',
                controller: nameController,
              ),
              const SizedBox(height: 24),
              SoftButton(
                title: 'Add to Team',
                variant: SoftButtonVariant.primary,
                onPressed: () => Navigator.pop(ctx, {
                  'phone': phoneController.text.trim(),
                  'name': nameController.text.trim(),
                }),
              ),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      phoneController.dispose();
      nameController.dispose();
    });

    if (entry == null || !mounted) return;
    final phone = entry['phone'] ?? '';
    if (phone.isEmpty) {
      ToastProvider.of(context).show('Phone number is required', ToastType.error);
      return;
    }
    try {
      await ApiClient.instance.post('/api/businesses/me/staff', body: {
        'phone': phone,
        if ((entry['name'] ?? '').isNotEmpty) 'name': entry['name'],
      });
      if (!mounted) return;
      ToastProvider.of(context).show('Team member added', ToastType.success);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show(
        '$e'.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''),
        ToastType.error,
      );
    }
  }

  Future<void> _retry() async {
    await _load();
    if (!mounted || _error == null) return;
    ToastProvider.of(context).show(_error!, ToastType.error);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final name = (_business['name'] as String?) ?? 'Your Business';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Suite'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(showErrors: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _retry,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            if (_error != null && _business.isEmpty) ...[
              SizedBox(height: MediaQuery.of(context).size.height * 0.15),
              const Icon(Icons.cloud_off, size: 56, color: AppColors.brandMuted),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.brandMuted),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _retry,
                  child: const Text('Retry',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
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
                    const SizedBox(height: 12),
                    SoftButton(
                      title: 'Request Payout',
                      variant: SoftButtonVariant.primary,
                      onPressed: _loading || _balance < 50
                          ? null
                          : _requestPayout,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.add_box,
                      label: 'Add Product',
                      onTap: () => Navigator.of(context)
                          .pushNamed('/business/products/add'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.phone_android,
                      label: 'Collection Numbers',
                      onTap: () => Navigator.of(context)
                          .pushNamed('/business/collection-numbers'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.person_add,
                      label: 'Add Staff',
                      onTap: _addStaff,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.receipt_long,
                      label: 'All Orders',
                      onTap: () => Navigator.of(context).pushNamed('/orders'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.account_balance,
                      label: 'Taxes',
                      onTap: () =>
                          Navigator.of(context).pushNamed('/business/tax'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
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
                ..._orders.take(5).map(_buildOrderCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final config = context.read<ConfigProvider>();
    final next = _nextStatus(order.status);
    final busy = _busyOrderId == order.id;

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => Navigator.of(context)
          .pushNamed('/orders/${order.id}', arguments: order.id),
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
          if (next != null) ...[
            const SizedBox(height: 12),
            SoftButton(
              title: busy ? 'Working...' : 'Mark $next',
              variant: SoftButtonVariant.secondary,
              isLoading: busy,
              onPressed: busy ? null : () => _advanceStatus(order),
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      child: Column(
        children: [
          Icon(icon, size: 28, color: AppColors.brandPrimary),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
        ],
      ),
    );
  }
}
