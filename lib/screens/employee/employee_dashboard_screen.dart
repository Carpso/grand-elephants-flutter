import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/cart_item.dart';
import 'package:sell_on_app/providers/auth_provider.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/services/api_client.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class EmployeeDashboardScreen extends StatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  State<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends State<EmployeeDashboardScreen> {
  DateTime? _clockIn;
  bool _loading = true;
  int _orderCount = 0;
  double _total = 0;
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _clockIn = DateTime.now();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final auth = context.read<AuthProvider>();
    _isAdmin = auth.role == 'admin' || auth.user?.role == 'admin';
    try {
      if (_isAdmin) {
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

  void _handleNewSale(AuthProvider auth) {
    if (_isAdmin) {
      Navigator.of(context).pushNamed('/admin/sales');
    } else {
      ToastProvider.of(context)
          .show('POS available for admins', ToastType.info);
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
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildSearchSection(auth),
                const SizedBox(height: 24),
                const Text(
                  'My Shift',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SoftCard(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Icon(Icons.timer, size: 32, color: Colors.green),
                            const SizedBox(height: 8),
                            const Text(
                              'Clocked In',
                              style: TextStyle(color: AppColors.brandMuted),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _clockIn != null ? _formatTime(_clockIn!) : '--:--',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: Colors.green,
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
                          children: [
                            const Icon(Icons.shopping_bag, size: 32, color: Colors.orange),
                            const SizedBox(height: 8),
                            const Text(
                              'Sales Today',
                              style: TextStyle(color: AppColors.brandMuted),
                            ),
                            const SizedBox(height: 4),
                            _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.brandPrimary,
                                    ),
                                  )
                                : Text(
                                    '$_orderCount',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                      color: Colors.orange,
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
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Sales',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                      Text(
                        _loading ? '...' : config.formatPrice(_total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
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

  Widget _buildSearchSection(AuthProvider auth) {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.brandMuted),
                const SizedBox(width: 8),
                const Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Scan Barcode or Search Product...',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: AppColors.brandMuted),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const Icon(Icons.qr_code_scanner, color: AppColors.brandPrimary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _handleNewSale(auth),
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
      ),
    );
  }

  Widget _buildQuickTasks() {
    final tasks = [
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
            onTap: () => Navigator.of(context).pushNamed(task['route'] as String),
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