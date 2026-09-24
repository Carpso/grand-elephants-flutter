import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/admin_provider.dart';
import 'package:grand_elephants/providers/auth_provider.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/system_health_modal.dart';
import 'package:grand_elephants/widgets/toast.dart';

class SuperadminDashboardScreen extends StatefulWidget {
  const SuperadminDashboardScreen({super.key});

  @override
  State<SuperadminDashboardScreen> createState() =>
      _SuperadminDashboardScreenState();
}

class _SuperadminDashboardScreenState extends State<SuperadminDashboardScreen> {
  bool _healthVisible = false;
  bool _maintenance = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadStats();
      _loadMaintenanceFlag();
    });
  }

  Future<void> _loadMaintenanceFlag() async {
    try {
      final res = await ApiClient.instance.get('/api/admin/settings');
      final data = Map<String, dynamic>.from(res as Map);
      if (!mounted) return;
      setState(() => _maintenance = '${data['maintenance_mode'] ?? '0'}' == '1');
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context)
          .show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
    }
  }

  String _formatCents(int cents) {
    final amount = cents / 100;
    final parts = amount.toStringAsFixed(2).split('.');
    final buf = StringBuffer();
    for (var i = 0; i < parts[0].length; i++) {
      if (i > 0 && (parts[0].length - i) % 3 == 0) buf.write(',');
      buf.write(parts[0][i]);
    }
    return 'K ${buf.toString()}.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final auth = context.watch<AuthProvider>();
    final stats = context.watch<AdminProvider>().stats;

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, config, auth),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildPerformanceCard(stats),
                const SizedBox(height: 24),
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text(
                    'QUICK ACTIONS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: AppColors.brandMuted,
                    ),
                  ),
                ),
                _buildMenuGrid(),
              ],
            ),
          ),
          SystemHealthModal(
            visible: _healthVisible,
            onClose: () => setState(() => _healthVisible = false),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ConfigProvider config, AuthProvider auth) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFD4AF37), Color(0xFFB4941F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'SUPERADMIN CONSOLE',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Command Center',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      onPressed: () => auth.logout(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _maintenance
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                    ),
                  ),
                  child: Text(
                    _maintenance
                        ? 'MAINTENANCE MODE'
                        : 'SYSTEM ONLINE',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _maintenance
                          ? Colors.red.shade100
                          : Colors.green.shade100,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Text(
                    'Tax: ${config.taxRate.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard(AdminStats stats) {
    final raw = <double>[
      stats.users.toDouble(),
      stats.businesses.toDouble(),
      stats.orders.toDouble(),
      stats.products.toDouble(),
      stats.pendingBusinesses.toDouble(),
      stats.pendingPayouts.toDouble(),
    ];
    final maxValue = raw.fold<double>(1, (a, b) => a > b ? a : b);
    final data = raw.map((v) => v / maxValue * 100).toList();

    return SoftCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LIVE PERFORMANCE',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: AppColors.brandMuted,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(data.length, (i) {
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: data[i] / 100 * 100,
                          decoration: BoxDecoration(
                            color: AppColors.brandPrimary.withValues(alpha: 0.2),
                            borderRadius:
                                const BorderRadius.vertical(top: Radius.circular(4)),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Container(
                              height: data[i] * 0.6 / 100 * 100,
                              decoration: BoxDecoration(
                                color: AppColors.brandPrimary,
                                borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Revenue',
                    style: TextStyle(fontSize: 12, color: AppColors.brandMuted),
                  ),
                  Text(
                    _formatCents(stats.gmvCents),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandDark,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Orders Placed',
                    style: TextStyle(fontSize: 12, color: AppColors.brandMuted),
                  ),
                  Text(
                    '${stats.orders}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid() {
    final menuItems = [
      {
        'title': 'Global Settings',
        'icon': Icons.settings,
        'desc': 'Tax, Maintenance, Backup',
      },
      {
        'title': 'Social Planner',
        'icon': Icons.schedule,
        'desc': 'Auto-post to FB/Insta',
      },
      {
        'title': 'System Health',
        'icon': Icons.monitor_heart,
        'desc': 'Real-time Metrics',
      },
      {
        'title': 'Access Control',
        'icon': Icons.security,
        'desc': 'Manage Roles & Permissions',
      },
      {
        'title': 'Collection Numbers',
        'icon': Icons.phone_android,
        'desc': 'Manage Mobile Money Numbers',
      },
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: menuItems.map((item) {
        return SizedBox(
          width: (MediaQuery.of(context).size.width - 24 * 2 - 16) / 2,
          child: InkWell(
            onTap: () {
              switch (item['title']) {
                case 'System Health':
                  setState(() => _healthVisible = true);
                case 'Collection Numbers':
                  Navigator.pushNamed(context, '/superadmin/collection-numbers');
                case 'Global Settings':
                  Navigator.pushNamed(context, '/admin/settings');
                case 'Access Control':
                  Navigator.pushNamed(context, '/admin/users');
                case 'Social Planner':
                  Navigator.pushNamed(context, '/admin/marketing');
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: SoftCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.softSurface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      size: 24,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item['title'] as String,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: AppColors.brandDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['desc'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.brandMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}