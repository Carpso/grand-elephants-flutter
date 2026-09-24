import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/auth_provider.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/toast.dart';

/// Employee work screen. Stats come from `GET /api/employee/stats`; admins in
/// this screen keep using `GET /api/admin/stats`.
class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  bool _loading = true;
  bool _isAdmin = false;
  bool _hasBusiness = false;
  String? _error;

  int _salesTodayCents = 0;
  int _salesTotalCents = 0;
  int _ordersToday = 0;
  int _ordersTotal = 0;
  int _pendingOrders = 0;

  int _adminOrders = 0;
  int _adminGmvCents = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    _isAdmin = auth.role == 'admin' || auth.role == 'superadmin';
    _hasBusiness = (auth.user?.businessId ?? '').isNotEmpty;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_isAdmin) {
        final res = await ApiClient.instance.get('/api/admin/stats');
        final data = res as Map<String, dynamic>;
        _adminOrders = (data['orders'] as num?)?.toInt() ?? 0;
        _adminGmvCents = (data['gmvCents'] as num?)?.toInt() ?? 0;
      } else {
        final res = await ApiClient.instance.get('/api/employee/stats');
        final data = res as Map<String, dynamic>;
        _salesTodayCents = (data['salesTodayCents'] as num?)?.toInt() ?? 0;
        _salesTotalCents = (data['salesTotalCents'] as num?)?.toInt() ?? 0;
        _ordersToday = (data['ordersToday'] as num?)?.toInt() ?? 0;
        _ordersTotal = (data['ordersTotal'] as num?)?.toInt() ?? 0;
        _pendingOrders = (data['pendingOrders'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = '$e'.replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _retry() async {
    await _load();
    if (!mounted) return;
    if (_error != null) {
      ToastProvider.of(context).show(_error!, ToastType.error);
    } else {
      ToastProvider.of(context).show('Stats refreshed', ToastType.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final config = context.watch<ConfigProvider>();

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, auth),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _retry,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  _buildSearchSection(),
                  const SizedBox(height: 24),
                  const Text(
                    'Performance',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null && _loading == false && _statsEmpty)
                    _buildErrorState()
                  else ...[
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            icon: Icons.shopping_bag,
                            color: Colors.orange,
                            label: _isAdmin ? 'MARKETPLACE SALES' : 'SALES TODAY',
                            value: _loading
                                ? '...'
                                : config.formatPrice(
                                    (_isAdmin ? _adminGmvCents : _salesTodayCents) /
                                        100),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _StatCard(
                            icon: Icons.receipt_long,
                            color: Colors.blue,
                            label: _isAdmin ? 'ORDERS' : 'ORDERS TODAY',
                            value: _loading
                                ? '...'
                                : '${_isAdmin ? _adminOrders : _ordersToday}',
                          ),
                        ),
                      ],
                    ),
                    if (!_isAdmin) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.trending_up,
                              color: Colors.green,
                              label: 'SALES TOTAL',
                              value: _loading
                                  ? '...'
                                  : config.formatPrice(_salesTotalCents / 100),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.list_alt,
                              color: Colors.purple,
                              label: 'ORDERS TOTAL',
                              value: _loading ? '...' : '$_ordersTotal',
                              caption: _pendingOrders > 0
                                  ? '$_pendingOrders pending'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                  const SizedBox(height: 32),
                  const Text(
                    'Quick Tasks',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickTasks(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  bool get _statsEmpty =>
      _salesTodayCents == 0 &&
      _salesTotalCents == 0 &&
      _ordersToday == 0 &&
      _ordersTotal == 0 &&
      _pendingOrders == 0 &&
      _adminOrders == 0 &&
      _adminGmvCents == 0;

  Widget _buildErrorState() {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.cloud_off, size: 40, color: AppColors.brandMuted),
          const SizedBox(height: 8),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.brandMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _retry,
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'EMPLOYEE PORTAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppColors.brandMuted,
                ),
              ),
              Text(
                'Hola, ${auth.user?.name ?? 'Staff'}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
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
    );
  }

  Widget _buildSearchSection() {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pushNamed('/explore'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.softSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: const Row(
                children: [
                  Icon(Icons.search, color: AppColors.brandMuted),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Search the catalogue...',
                      style: TextStyle(color: AppColors.brandMuted),
                    ),
                  ),
                  Icon(Icons.qr_code_scanner, color: AppColors.brandPrimary),
                ],
              ),
            ),
          ),
          if (_isAdmin) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed('/admin/sales'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandPrimary,
                  foregroundColor: AppColors.brandDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'New Sale (POS)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuickTasks() {
    final tasks = <Map<String, dynamic>>[
      {
        'title': 'View Orders',
        'icon': Icons.receipt_long,
        'route': '/orders',
      },
      {
        'title': 'View Wishlist',
        'icon': Icons.favorite_border,
        'route': '/profile/wishlist',
      },
      if (_hasBusiness)
        {
          'title': 'Business Stock',
          'icon': Icons.inventory_2,
          'route': '/employee/stock',
        },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: tasks.map((task) {
          return InkWell(
            onTap: () {
              final route = task['route'] as String;
              if (route == '/employee/stock') {
                Navigator.of(context).pushNamed('/employee/stock');
              } else {
                Navigator.of(context).pushNamed(route);
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.softSurface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      task['icon'] as IconData,
                      size: 20,
                      color: AppColors.brandSecondary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      task['title'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandSecondary,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.brandMuted),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? caption;

  const _StatCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.brandMuted,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: color,
            ),
          ),
          if (caption != null)
            Text(
              caption!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.brandMuted,
              ),
            ),
        ],
      ),
    );
  }
}
