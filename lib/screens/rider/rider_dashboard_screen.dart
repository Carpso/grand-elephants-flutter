import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/auth_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/incoming_order_modal.dart';

class RiderDashboardScreen extends StatefulWidget {
  const RiderDashboardScreen({super.key});

  @override
  State<RiderDashboardScreen> createState() => _RiderDashboardScreenState();
}

class _RiderDashboardScreenState extends State<RiderDashboardScreen> {
  bool _isOnline = false;
  bool _hasActiveOrder = false;
  bool _requestVisible = false;
  Timer? _timer;

  @override
  void didUpdateWidget(covariant RiderDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _onOnlineChanged(bool value) {
    setState(() {
      _isOnline = value;
      _hasActiveOrder = false;
      _requestVisible = false;
    });
    _timer?.cancel();
    if (value) {
      _timer = Timer(const Duration(seconds: 3), () {
        if (mounted && _isOnline && !_hasActiveOrder) {
          setState(() => _requestVisible = true);
        }
      });
    }
  }

  void _handleAccept() {
    setState(() {
      _requestVisible = false;
      _hasActiveOrder = true;
    });
  }

  void _handleDecline() {
    setState(() {
      _requestVisible = false;
      _isOnline = false;
    });
    _timer?.cancel();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request Declined - You are now Offline')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(auth),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (_isOnline && _hasActiveOrder)
                    _buildActiveDelivery()
                  else
                    _buildIdleState(),
                  _buildStats(),
                ],
              ),
            ),
            IncomingOrderModal(
              visible: _requestVisible,
              onAccept: _handleAccept,
              onDecline: _handleDecline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AuthProvider auth) {
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
                      child: Image.network(
                        'https://i.pravatar.cc/150?img=12',
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.person,
                          color: AppColors.brandMuted,
                        ),
                      ),
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
                        auth.user?.name ?? 'Alex Rider',
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
                Text(
                  _isOnline ? 'YOU ARE ONLINE' : 'YOU ARE OFFLINE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                    color: _isOnline ? AppColors.brandAccent : AppColors.brandMuted,
                  ),
                ),
                Switch(
                  value: _isOnline,
                  onChanged: _onOnlineChanged,
                  activeThumbColor: AppColors.brandAccent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveDelivery() {
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
                    const Text(
                      'Order #8821',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Pick up: Central Mall • 2.5km',
                      style: TextStyle(fontSize: 14, color: AppColors.brandMuted),
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
              onPressed: () {
                setState(() => _hasActiveOrder = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Great Job! Delivery Completed. +K 45.00')),
                );
              },
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
                color: _isOnline
                    ? AppColors.brandAccent.withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.two_wheeler,
                size: 48,
                color: _isOnline ? AppColors.brandAccent : AppColors.brandMuted,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _isOnline ? 'Searching for jobs...' : 'Go Online to start',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 16),
            child: Text(
              "Today's Performance",
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
                  label: 'EARNINGS',
                  value: 'K 450',
                  valueColor: AppColors.brandAccent,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.delivery_dining,
                  iconBgColor: Colors.orange.shade50,
                  iconColor: AppColors.warning,
                  label: 'TRIPS',
                  value: '8',
                  valueColor: AppColors.brandDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star,
                  iconBgColor: Colors.yellow.shade50,
                  iconColor: Colors.amber,
                  label: 'RATING',
                  value: '4.9',
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
