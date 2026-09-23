import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/cart_item.dart';
import 'package:sell_on_app/providers/cart_provider.dart';
import 'package:sell_on_app/widgets/hosted_map.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  Order? _order;
  bool _loading = true;
  String? _error;

  static const List<String> _flow = [
    'Pending',
    'Confirmed',
    'Processing',
    'Shipped',
    'Out for Delivery',
    'Delivered',
  ];

  static const Map<String, String> _labels = {
    'Pending': 'Order Placed',
    'Confirmed': 'Confirmed',
    'Processing': 'Processing',
    'Shipped': 'Shipped',
    'Out for Delivery': 'Out for Delivery',
    'Delivered': 'Delivered',
  };

  String get _orderId {
    return ModalRoute.of(context)?.settings.arguments as String? ?? '';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var id = _orderId;
    if (id.isEmpty) {
      final cart = context.read<CartProvider>();
      if (cart.orders.isNotEmpty) id = cart.orders.first.id;
    }
    if (id.isEmpty) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No order selected';
        });
      }
      return;
    }
    final order = await context.read<CartProvider>().fetchOrder(id);
    if (!mounted) return;
    setState(() {
      _order = order;
      _loading = false;
    });
  }

  Future<void> _cancelOrder() async {
    final id = _order!.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure? Cancellation fees may apply.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await context.read<CartProvider>().cancelOrder(id);
      if (!mounted) return;
      ToastProvider.of(context).show('Order $id cancelled', ToastType.success);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context)
          .show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      appBar: AppBar(
        title: Text(order != null ? 'Track Order #${order.id}' : 'Track Order'),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.brandPrimary),
            )
          : order == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long,
                            size: 64, color: AppColors.brandMuted),
                        const SizedBox(height: 16),
                        Text(
                          _error ?? 'Order not found',
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.brandMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 100),
                  children: [
                    _buildMapPlaceholder(order),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 24),
                      child: SoftCard(
                        margin: const EdgeInsets.only(bottom: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRiderSection(order),
                            const SizedBox(height: 24),
                            const Divider(height: 1),
                            const SizedBox(height: 24),
                            _buildSteps(order),
                          ],
                        ),
                      ),
                    ),
                    Center(
                      child: SoftButton(
                        title: 'Cancel Order',
                        variant: SoftButtonVariant.ghost,
                        onPressed: order.isCancellable ? _cancelOrder : null,
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildMapPlaceholder(Order order) {
    final latlng = _orderLatLng(order);
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(40),
        bottomRight: Radius.circular(40),
      ),
      child: SizedBox(
        height: 340,
        child: Stack(
          children: [
            Positioned.fill(
              child: HostedMap(
                center: latlng,
                zoom: 13,
                markers: [
                  buildDeliveryMarker(
                    latlng,
                    order.isDelivered
                        ? Icons.check_circle
                        : order.isCancelled
                            ? Icons.cancel
                            : Icons.delivery_dining,
                    order.isDelivered
                        ? AppColors.success
                        : order.isCancelled
                            ? AppColors.error
                            : AppColors.brandPrimary,
                  ),
                ],
              ),
            ),
            Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: order.isDelivered
                              ? AppColors.success
                              : order.isCancelled
                                  ? AppColors.error
                                  : AppColors.warning,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Status: ${order.status}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  LatLng _orderLatLng(Order order) {
    // Delivery destination defaults to central Lusaka; businesses may store
    // coordinates in the address string later. Keeps the map fully usable now.
    return const LatLng(-15.3875, 28.3228);
  }

  Widget _buildRiderSection(Order order) {
    final rawRider = order.riderName;
    final riderName = (rawRider != null && rawRider.trim().isNotEmpty)
        ? rawRider.trim()
        : '';
    final hasRider = riderName.isNotEmpty;
    final initials = hasRider
        ? riderName
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p[0].toUpperCase())
            .join()
        : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.15),
          child: Text(
            initials,
            style: const TextStyle(
              color: AppColors.brandPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasRider ? 'YOUR RIDER' : 'RIDER STATUS',
                style: TextStyle(
                  color: AppColors.brandMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasRider ? riderName : 'Assigning rider...',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                hasRider
                    ? 'Your rider will be delivering this order.'
                    : 'A rider will be assigned shortly.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.brandMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSteps(Order order) {
    final isCancelled = order.isCancelled;
    final steps = [..._flow];
    if (isCancelled) steps.add('Cancelled');
    final currentIndex = _flow.indexOf(order.status);

    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        children: List.generate(steps.length, (index) {
          final status = steps[index];
          final title = status == 'Cancelled' ? 'Cancelled' : _labels[status]!;
          final isActive = isCancelled
              ? status == 'Cancelled'
              : index == currentIndex;
          final isCompleted = isCancelled
              ? false
              : index < currentIndex;
          final isPending = !isCancelled &&
              !isActive &&
              index > currentIndex &&
              currentIndex >= 0;

          final time = index == 0 && order.date.isNotEmpty
              ? order.date
              : status == 'Delivered' && order.deliveredAt != null
                  ? order.deliveredAt!
                  : '';

          return Padding(
            padding: const EdgeInsets.only(bottom: 32),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.brandPrimary
                            : isCompleted
                                ? AppColors.success
                                : Colors.grey.shade200,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    if (index < steps.length - 1)
                      Container(
                        width: 2,
                        height: 40,
                        color: isCompleted
                            ? AppColors.success.withValues(alpha: 0.4)
                            : Colors.grey.shade100,
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Opacity(
                    opacity: isPending ? 0.5 : 1.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isActive
                                      ? AppColors.brandPrimary
                                      : isCompleted
                                          ? AppColors.brandDark
                                          : AppColors.brandMuted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isCancelled && status != 'Cancelled'
                                    ? 'Order was cancelled before reaching this step.'
                                    : status == 'Delivered'
                                        ? 'Your order has been delivered. Enjoy!'
                                        : status == 'Cancelled'
                                            ? 'This order was cancelled.'
                                            : 'Your order is progressing through fulfilment.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.brandMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (time.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              time,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandMuted,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(
                delay: (index * 100).ms,
                duration: 300.ms,
              );
        }),
      ),
    );
  }
}