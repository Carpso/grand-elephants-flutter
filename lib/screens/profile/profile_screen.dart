import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/user.dart';
import 'package:grand_elephants/providers/auth_provider.dart';
import 'package:grand_elephants/providers/cart_provider.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/providers/wishlist_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/toast.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<_MenuItem> _menuItems = [
    _MenuItem(title: 'My Orders', icon: Icons.shopping_bag, route: '/orders'),
    _MenuItem(title: 'Wishlist', icon: Icons.favorite, route: '/profile/wishlist'),
    _MenuItem(title: 'Addresses', icon: Icons.location_on, route: '/profile/addresses'),
    _MenuItem(title: 'Notifications', icon: Icons.notifications, route: '/profile/notifications'),
    _MenuItem(title: 'Settings', icon: Icons.settings, route: '/profile/settings'),
    _MenuItem(title: 'Help & Support', icon: Icons.help, route: '/profile/help'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CartProvider>().loadOrders();
    });
  }

  Future<void> _pickProfileImage() async {
    HapticFeedback.selectionClick();
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    try {
      await ApiClient.instance.patch('/api/me', body: {'profilePhoto': picked.path});
      await auth.updateProfile(name: user.name, email: user.email);
      if (!mounted) return;
      ToastProvider.of(context).show('Profile photo updated', ToastType.success);
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show('Could not update profile photo', ToastType.error);
    }
  }

  void _handleSignOut() {
    HapticFeedback.heavyImpact();
    context.read<AuthProvider>().logout();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final config = context.watch<ConfigProvider>();
    final cart = context.watch<CartProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final user = auth.user;
    final role = auth.role;
    final riderStatus = auth.riderStatus;

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            _buildHeader(user, role, auth, cart.orders.length, wishlist.wishlist.length),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (role == 'user' && riderStatus != 'approved')
                    _buildRiderCard(config, riderStatus),
                  _buildSectionTitle('Management'),
                  _buildBusinessSuiteCard(),
                  if (role == 'admin' || role == 'superadmin')
                    Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: SoftButton(
                        title: 'Admin Dashboard',
                        variant: SoftButtonVariant.primary,
                        icon: const Icon(Icons.dashboard, size: 20, color: Colors.white),
                        onPressed: () => Navigator.of(context).pushNamed('/admin/dashboard'),
                      ),
                    ),
                  _buildSectionTitle('Settings'),
                  _buildMenuList(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: SoftButton(
                      title: 'Sign Out',
                      variant: SoftButtonVariant.ghost,
                      textStyle: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      icon: const Icon(Icons.logout, size: 20, color: AppColors.error),
                      onPressed: _handleSignOut,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(user, String role, AuthProvider auth, int ordersCount, int wishlistCount) {
    return Container(
      padding: const EdgeInsets.only(top: 64, bottom: 24, left: 24, right: 24),
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _pickProfileImage,
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 4),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                    color: AppColors.softSurface,
                  ),
                  child: ClipOval(
                    child: user?.profilePhoto != null && user!.profilePhoto!.isNotEmpty
                        ? Image.network(
                            user.profilePhoto!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _InitialsAvatar(user: user),
                          )
                        : _InitialsAvatar(user: user),
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppColors.brandPrimary,
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(BorderSide(color: AppColors.white, width: 2)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x1A000000),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.edit, size: 14, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Guest User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 4),
          if (user?.email != null)
            Text(
              user!.email,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.brandMuted,
              ),
            ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.verified, size: 12, color: AppColors.brandPrimary),
                const SizedBox(width: 4),
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandPrimary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _buildStatsRow(ordersCount, wishlistCount),
        ],
      ),
    );
  }

  Widget _buildStatsRow(int ordersCount, int wishlistCount) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _StatItem(value: '$ordersCount', label: 'Orders'),
          Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
          _StatItem(value: '$wishlistCount', label: 'Wishlist'),
          Container(width: 1, height: 32, color: const Color(0xFFE5E7EB)),
          _StatItem(value: '—', label: 'Reviews'),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 12, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppColors.brandDark,
        ),
      ),
    );
  }

  Widget _buildRiderCard(ConfigProvider config, String riderStatus) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: SoftCard(
        child: Column(
          children: [
            Text(
              'Earn with ${config.appName}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Join our fleet and start earning money delivering happiness.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
              ),
            ),
            const SizedBox(height: 16),
            SoftButton(
              title: riderStatus == 'pending' ? 'Check Status' : 'Become a Rider',
              variant: SoftButtonVariant.primary,
              onPressed: () => Navigator.of(context).pushNamed('/rider/apply'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBusinessSuiteCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pushNamed('/business/dashboard');
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF111827), Color(0xFF1F2937)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.brandPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.business_center, size: 24, color: Colors.black),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Business Suite',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'FINANCE & ANALYTICS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandPrimary,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, size: 24, color: AppColors.brandPrimary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        children: _menuItems.asMap().entries.map((entry) {
          final item = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pushNamed(item.route);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.softSurface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1A000000),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(item.icon, size: 20, color: AppColors.brandDark),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 24, color: Color(0xFFD1D5DB)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem {
  final String title;
  final IconData icon;
  final String route;

  const _MenuItem({
    required this.title,
    required this.icon,
    required this.route,
  });
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.brandDark,
          ),
        ),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: AppColors.brandMuted,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  final User? user;

  const _InitialsAvatar({this.user});

  String get _initials {
    final name = user == null ? '' : user!.name.trim();
    if (name.isEmpty) return 'U';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.brandPrimary,
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: AppColors.brandDark,
        ),
      ),
    );
  }
}
