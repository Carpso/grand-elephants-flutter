import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const List<_MenuItem> _menuItems = [
    _MenuItem('Inventory', Icons.inventory, Color(0xFF3B82F6), '/admin/inventory'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
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
              'Welcome back, Admin.',
              style: TextStyle(color: AppColors.brandMuted),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SoftCard(
                    child: Column(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.softSurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.attach_money, color: AppColors.brandPrimary, size: 24),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'TOTAL SALES',
                          style: TextStyle(
                            color: AppColors.brandMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'K 12,450',
                          style: TextStyle(
                            fontSize: 22,
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
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.softSurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.shopping_bag, color: AppColors.brandPrimary, size: 24),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'ACTIVE ORDERS',
                          style: TextStyle(
                            color: AppColors.brandMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          '18',
                          style: TextStyle(
                            fontSize: 22,
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
                  onTap: () {},
                );
              },
            ),
          ],
        ),
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
