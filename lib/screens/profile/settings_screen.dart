import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/providers/notification_provider.dart';
import 'package:sell_on_app/services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  void _handleThemeToggle(ConfigProvider config) {
    config.toggleTheme();
    StorageService.save('theme', config.theme);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final settings = notifProvider.settings;

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'PREFERENCES',
              style: TextStyle(
                color: AppColors.brandMuted,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _SettingItem(
              title: 'Push Notifications',
              icon: Icons.notifications_active,
              value: settings.orderUpdates,
              onToggle: (v) => notifProvider.updateSettings(orderUpdates: v),
            ),
            _SettingItem(
              title: 'Email Newsletter',
              icon: Icons.mail,
              value: settings.promotions,
              onToggle: (v) => notifProvider.updateSettings(promotions: v),
            ),
            _SettingItem(
              title: 'Dark Mode (${config.theme})',
              icon: Icons.dark_mode,
              value: config.theme == 'dark',
              onToggle: (_) => _handleThemeToggle(config),
            ),
            _SettingItem(
              title: 'Currency (${config.currency})',
              icon: Icons.attach_money,
              value: config.currency == 'USD',
              onToggle: (_) => config.toggleCurrency(),
            ),
            const SizedBox(height: 24),
            const Text(
              'LEGAL',
              style: TextStyle(
                color: AppColors.brandMuted,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _LegalItem(
              title: 'Privacy Policy',
              onTap: () => showDialog(
                context: context,
                builder: (_) => const AlertDialog(
                  title: Text('Privacy Policy'),
                  content: SingleChildScrollView(
                    child: Text(
                      'Your privacy matters to us.\n\n'
                      'We collect only the information needed to process your orders, '
                      'including your name, phone number, delivery address, and order history. '
                      'This data is used solely to fulfil orders, provide customer support, '
                      'and improve our service.\n\n'
                      'We do not sell your personal information to third parties. '
                      'Payment details are processed securely by our payment providers.\n\n'
                      'You may request access to, correction of, or deletion of your personal '
                      'data at any time by contacting our support team.',
                    ),
                  ),
                ),
              ),
            ),
            _LegalItem(
              title: 'Terms of Service',
              onTap: () => showDialog(
                context: context,
                builder: (_) => const AlertDialog(
                  title: Text('Terms of Service'),
                  content: SingleChildScrollView(
                    child: Text(
                      'By using this app you agree to the following terms:\n\n'
                      '1. Orders are confirmed once payment is received successfully.\n'
                      '2. Delivery times are estimates and may vary based on location and availability.\n'
                      '3. Returns are accepted within 7 days of delivery for unused items in original condition.\n'
                      '4. We are not liable for misuse of your account or unauthorised access due to shared credentials.\n'
                      '5. We reserve the right to update these terms at any time.',
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Text(
                'Version 1.0.0+1',
                style: TextStyle(
                  color: AppColors.brandMuted.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onToggle;

  const _SettingItem({
    required this.title,
    required this.icon,
    required this.value,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF4B5563)),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
            ],
          ),
          Switch(
            value: value,
            onChanged: onToggle,
            activeTrackColor: AppColors.brandPrimary,
            inactiveTrackColor: const Color(0xFF767577),
            thumbColor: WidgetStateProperty.resolveWith((_) => const Color(0xFFF4F3F4)),
          ),
        ],
      ),
    );
  }
}

class _LegalItem extends StatelessWidget {
  final String title;
  final VoidCallback onTap;

  const _LegalItem({required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 24, color: Color(0xFF9CA3AF)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
