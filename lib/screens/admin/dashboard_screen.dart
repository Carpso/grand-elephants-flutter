import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/admin_provider.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/widgets/soft_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const List<_MenuItem> _menuItems = [
    _MenuItem('Inventory', Icons.inventory, Color(0xFF3B82F6), '/admin/inventory'),
    _MenuItem('Businesses', Icons.storefront, Color(0xFFF97316), '/admin/businesses'),
    _MenuItem('Sales', Icons.attach_money, Color(0xFF10B981), '/admin/sales'),
    _MenuItem('Finance', Icons.account_balance, Color(0xFFF59E0B), '/admin/finance'),
    _MenuItem('Users', Icons.group, Color(0xFFEC4899), '/admin/users'),
    _MenuItem('Team', Icons.people, Color(0xFF8B5CF6), '/admin/employees'),
    _MenuItem('Riders', Icons.sports_motorsports, Color(0xFF14B8A6), '/admin/riders'),
    _MenuItem('Marketing', Icons.campaign, Color(0xFFA855F7), '/admin/marketing'),
    _MenuItem('Banners', Icons.view_carousel, Color(0xFF6366F1), '/admin/banners'),
    _MenuItem('Categories', Icons.category, Color(0xFFEC4899), '/admin/categories'),
    _MenuItem('Alerts', Icons.notifications, Color(0xFFEF4444), '/admin/notifications'),
    _MenuItem('Settings', Icons.settings, Color(0xFF6B7280), '/admin/settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final config = context.watch<ConfigProvider>();
    final stats = admin.stats;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: () => admin.loadStats(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Live marketplace metrics',
                style: TextStyle(color: AppColors.brandMuted),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.attach_money,
                      label: 'TOTAL SALES',
                      value: config.formatPrice(stats.gmvCents / 100),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.shopping_bag,
                      label: 'ORDERS',
                      value: '${stats.orders}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.group,
                      label: 'USERS',
                      value: '${stats.users}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.inventory_2,
                      label: 'PRODUCTS',
                      value: '${stats.products}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.account_balance_wallet,
                      label: 'BUSINESS WALLETS',
                      value: config.formatPrice(stats.businessWalletCents / 100),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.pending_actions,
                      label: 'PENDING PAYOUTS',
                      value: '${stats.pendingPayouts}',
                    ),
                  ),
                ],
              ),
              if (stats.pendingBusinesses > 0) ...[
                const SizedBox(height: 16),
                SoftCard(
                  padding: const EdgeInsets.all(16),
                  onTap: () => Navigator.of(context).pushNamed('/admin/businesses'),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.storefront, color: Colors.amber),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${stats.pendingBusinesses} business application(s) awaiting approval',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.brandDark,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 1.3,
                ),
                itemCount: _menuItems.length,
                itemBuilder: (context, index) {
                  final item = _menuItems[index];
                  return _DashboardCard(
                    title: item.title,
                    icon: item.icon,
                    color: item.color,
                    onTap: () => Navigator.of(context).pushNamed(item.route),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.brandPrimary, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.brandMuted,
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final String route;

  const _MenuItem(this.title, this.icon, this.color, this.route);
}

class _DashboardCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.white),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.softSurface,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brandSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}