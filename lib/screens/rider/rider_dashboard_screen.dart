import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/cart_item.dart';
import 'package:sell_on_app/providers/auth_provider.dart';
import 'package:sell_on_app/providers/rider_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (mounted) context.read<RiderProvider>().load();
  }

  Future<void> _completeDelivery(Order order) async {
    try {
      await context.read<RiderProvider>().updateOrderStatus(order.id, 'Delivered');
      if (mounted) {
        ToastProvider.of(context).show('Delivery completed for ${order.id}', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final rider = context.watch<RiderProvider>();
    final active = rider.deliveries
        .where((o) => o.status == 'Shipped' || o.status == 'Out for Delivery')
        .toList();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(auth, rider),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (active.isNotEmpty)
                    ...active.map((o) => _buildActiveDelivery(o))
                  else
                    _buildIdleState(),
                  _buildStats(rider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth, RiderProvider rider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: AppColors.softSurface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: auth.user?.profilePhoto != null &&
                              auth.user!.profilePhoto!.isNotEmpty
                          ? Image.network(
                              auth.user!.profilePhoto!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                color: AppColors.brandMuted,
                              ),
                            )
                          : const Icon(Icons.person, color: AppColors.brandMuted),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'RIDER PARTNER',
                        style: TextStyle(
                          color: AppColors.brandMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        auth.user?.name ?? 'Rider',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.brandSecondary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout, color: AppColors.error),
                    onPressed: () => auth.logout(),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          SoftCard(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.isApproved ? 'APPROVED RIDER' : 'PENDING APPROVAL',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        letterSpacing: 1,
                        color: rider.isApproved ? AppColors.brandAccent : AppColors.brandMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Balance: K ${rider.balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.brandMuted,
                      ),
                    ),
                  ],
                ),
                Icon(
                  rider.isApproved ? Icons.verified : Icons.hourglass_empty,
                  color: rider.isApproved ? AppColors.brandAccent : AppColors.brandMuted,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDelivery(Order order) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SoftCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CURRENT MISSION',
                      style: TextStyle(
                        color: AppColors.brandAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '#${order.id}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${order.businessName?.isNotEmpty == true ? order.businessName! : 'Shop'} • ${order.items.length} items',
                      style: const TextStyle(fontSize: 14, color: AppColors.brandMuted),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.navigation,
                    size: 24,
                    color: AppColors.brandAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SoftButton(
              title: 'Complete Delivery',
              variant: SoftButtonVariant.primary,
              onPressed: () => _completeDelivery(order),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdleState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.two_wheeler,
                size: 48,
                color: AppColors.brandMuted,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No active deliveries',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandMuted,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Assigned orders will appear here.',
              style: TextStyle(fontSize: 13, color: AppColors.brandMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(RiderProvider rider) {
    final delivered = rider.deliveries.where((o) => o.status == 'Delivered').length;
    final pending = rider.payouts.length;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              'Performance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.attach_money,
                  iconBgColor: AppColors.brandAccent.withValues(alpha: 0.1),
                  iconColor: AppColors.brandAccent,
                  label: 'BALANCE',
                  value: 'K ${rider.balance.toStringAsFixed(2)}',
                  valueColor: AppColors.brandAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.delivery_dining,
                  iconBgColor: Colors.orange.shade50,
                  iconColor: AppColors.warning,
                  label: 'DELIVERED',
                  value: '$delivered',
                  valueColor: AppColors.brandDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.payments,
                  iconBgColor: Colors.yellow.shade50,
                  iconColor: Colors.amber,
                  label: 'PAYOUTS',
                  value: '$pending',
                  valueColor: AppColors.brandDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: AppColors.brandMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}