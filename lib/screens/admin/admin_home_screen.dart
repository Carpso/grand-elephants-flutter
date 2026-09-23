import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/widgets/back_button.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/soft_input.dart';
import 'package:sell_on_app/widgets/toast.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  late TextEditingController _nameController;
  late TextEditingController _sloganController;
  late TextEditingController _logoController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final config = context.read<ConfigProvider>();
    _nameController = TextEditingController(text: config.appName);
    _sloganController = TextEditingController(text: config.appSlogan);
    _logoController = TextEditingController(text: config.appLogo);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sloganController.dispose();
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveBranding() async {
    setState(() => _isSaving = true);
    try {
      final config = context.read<ConfigProvider>();
      await config.updateAppIdentity(
        _nameController.text,
        _sloganController.text,
        'Premium Marketplace',
        _logoController.text,
      );
      if (mounted) {
        ToastProvider.of(context).show('Branding updated successfully!', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('Failed to update branding', ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      appBar: AppBar(title: const Text('System Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppBackButton(),
                const SizedBox(width: 12),
                const Text(
                  'System Management',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.brush, color: AppColors.brandPrimary, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        'App Branding',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SoftInput(
                    label: 'App Name',
                    controller: _nameController,
                    hint: 'e.g. Sell On App',
                  ),
                  SoftInput(
                    label: 'App Slogan',
                    controller: _sloganController,
                    hint: 'Premium Marketplace',
                  ),
                  if (_logoController.text.isNotEmpty) ...[
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(_logoController.text),
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => _logoController.clear(),
                            child: const Text(
                              'Remove Custom Logo',
                              style: TextStyle(color: AppColors.error, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SoftInput(
                    label: 'App Logo URL',
                    controller: _logoController,
                    hint: 'https://example.com/logo.png',
                  ),
                  const SizedBox(height: 16),
                  SoftButton(
                    title: _isSaving ? 'Saving...' : 'Save Branding Changes',
                    variant: SoftButtonVariant.primary,
                    onPressed: _isSaving ? null : _handleSaveBranding,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (isTablet)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 3,
                children: [
                  _buildMenuCard(Icons.people, 'Manage Users', () => Navigator.pushNamed(context, '/admin/users')),
                  _buildMenuCard(Icons.settings, 'App Settings', () => Navigator.pushNamed(context, '/admin/settings')),
                  _buildMenuCard(Icons.security, 'Security Logs', () => Navigator.pushNamed(context, '/admin/notifications')),
                ],
              )
            else ...[
              _buildMenuCard(Icons.people, 'Manage Users', () => Navigator.pushNamed(context, '/admin/users')),
              const SizedBox(height: 12),
              _buildMenuCard(Icons.settings, 'App Settings', () => Navigator.pushNamed(context, '/admin/settings')),
              const SizedBox(height: 12),
              _buildMenuCard(Icons.security, 'Security Logs', () => Navigator.pushNamed(context, '/admin/notifications')),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, VoidCallback onTap) {
    return SoftCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.brandPrimary, size: 24),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
