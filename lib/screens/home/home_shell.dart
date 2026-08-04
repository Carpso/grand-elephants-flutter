import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../constants/app_theme.dart';
import '../../providers/auth_provider.dart';
import 'home_screen.dart';
import '../explore/explore_screen.dart';
import '../rider/rider_home_screen.dart';
import '../business/business_home_screen.dart';
import '../admin/admin_home_screen.dart';
import '../profile/profile_screen.dart';

class _TabConfig {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final Widget screen;

  const _TabConfig(this.label, this.icon, this.activeIcon, this.screen);
}

const _roleTabs = <String, List<_TabConfig>>{
  'user': [
    _TabConfig('Home', Icons.home_outlined, Icons.home, HomeScreen()),
    _TabConfig('Explore', Icons.explore_outlined, Icons.explore, ExploreScreen()),
    _TabConfig('Profile', Icons.person_outlined, Icons.person, ProfileScreen()),
  ],
  'rider': [
    _TabConfig('Home', Icons.home_outlined, Icons.home, HomeScreen()),
    _TabConfig('Deliveries', Icons.local_shipping_outlined, Icons.local_shipping, RiderHomeScreen()),
    _TabConfig('Profile', Icons.person_outlined, Icons.person, ProfileScreen()),
  ],
  'admin': [
    _TabConfig('Home', Icons.home_outlined, Icons.home, HomeScreen()),
    _TabConfig('Business', Icons.business_center_outlined, Icons.business_center, BusinessHomeScreen()),
    _TabConfig('Admin', Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, AdminHomeScreen()),
    _TabConfig('Profile', Icons.person_outlined, Icons.person, ProfileScreen()),
  ],
  'superadmin': [
    _TabConfig('Home', Icons.home_outlined, Icons.home, HomeScreen()),
    _TabConfig('Business', Icons.business_center_outlined, Icons.business_center, BusinessHomeScreen()),
    _TabConfig('Admin', Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, AdminHomeScreen()),
    _TabConfig('Profile', Icons.person_outlined, Icons.person, ProfileScreen()),
  ],
  'employee': [
    _TabConfig('Home', Icons.home_outlined, Icons.home, HomeScreen()),
    _TabConfig('Business', Icons.business_center_outlined, Icons.business_center, BusinessHomeScreen()),
    _TabConfig('Profile', Icons.person_outlined, Icons.person, ProfileScreen()),
  ],
};

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role;
    final configs = _roleTabs[role] ?? _roleTabs['user']!;

    if (_currentIndex >= configs.length) {
      _currentIndex = 0;
    }

    final tabs = configs
        .map((c) => BottomNavigationBarItem(
              icon: Icon(c.icon),
              activeIcon: Icon(c.activeIcon),
              label: c.label,
            ))
        .toList();

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: configs.map((c) => c.screen).toList()),
      bottomNavigationBar: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 25),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: AppColors.brandPrimary,
            unselectedItemColor: AppColors.brandMuted,
            selectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            unselectedLabelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            items: tabs,
          ),
        ),
      ),
    );
  }
}
