import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/services/api_client.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/soft_input.dart';
import 'package:sell_on_app/widgets/toast.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _sloganController;
  late TextEditingController _descriptionController;
  late TextEditingController _logoController;
  late TextEditingController _taxController;
  late TextEditingController _openingController;
  late TextEditingController _closingController;
  late TextEditingController _supportController;

  @override
  void initState() {
    super.initState();
    final config = context.read<ConfigProvider>();
    _nameController = TextEditingController(text: config.appName);
    _sloganController = TextEditingController(text: config.appSlogan);
    _descriptionController = TextEditingController(text: config.appDescription);
    _logoController = TextEditingController(text: config.appLogo);
    _taxController = TextEditingController(text: config.taxRate.toString());
    _openingController = TextEditingController(text: '08:00');
    _closingController = TextEditingController(text: '20:00');
    _supportController = TextEditingController(text: 'support@${config.appName.toLowerCase().replaceAll(' ', '')}.com');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sloganController.dispose();
    _descriptionController.dispose();
    _logoController.dispose();
    _taxController.dispose();
    _openingController.dispose();
    _closingController.dispose();
    _supportController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    try {
      final config = context.read<ConfigProvider>();
      await config.updateAppIdentity(
        _nameController.text,
        _sloganController.text,
        _descriptionController.text,
        _logoController.text,
      );
      await ApiClient.instance.patch('/api/admin/settings', body: {
        'vat_pct': _taxController.text,
      });
      config.setTaxRate(double.tryParse(_taxController.text) ?? config.taxRate);
      if (mounted) {
        ToastProvider.of(context).show('Configuration Saved Successfully', ToastType.success);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('Failed to save configuration', ToastType.error);
      }
    }
  }

  Future<void> _toggleMaintenance() async {
    final config = context.read<ConfigProvider>();
    final next = !config.maintenanceMode;
    config.toggleMaintenanceMode();
    try {
      await ApiClient.instance.patch('/api/admin/settings', body: {
        'maintenance_mode': next ? '1' : '0',
      });
      if (mounted) {
        ToastProvider.of(context).show(next ? 'Maintenance mode enabled.' : 'Maintenance mode disabled.', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    }
  }

  void _handleBackup() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Run System Backup'),
        content: const Text(
          'There is no server-side backup endpoint exposed to this app. Contact the superadmin to schedule a backup from the backend.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ToastProvider.of(context).show('Backup must be scheduled server-side.', ToastType.info);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('App Settings')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Brand Identity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
            ),
            const SizedBox(height: 16),
            SoftCard(
              child: Column(
                children: [
                  SoftInput(label: 'Application Name', controller: _nameController, hint: 'Your App Name'),
                  SoftInput(label: 'Slogan / Tagline', controller: _sloganController, hint: 'Premium Digital Fashion'),
                  SoftInput(label: 'App Logo URL', controller: _logoController, hint: 'https://...'),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Description',
                          style: TextStyle(color: AppColors.brandSecondary, fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.softSurface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _descriptionController,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Describe your app...',
                            hintStyle: TextStyle(color: AppColors.brandMuted),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Store Operations',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
            ),
            const SizedBox(height: 16),
            SoftCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: SoftInput(label: 'Opening Time', controller: _openingController, hint: '08:00')),
                      const SizedBox(width: 12),
                      Expanded(child: SoftInput(label: 'Closing Time', controller: _closingController, hint: '20:00')),
                    ],
                  ),
                  SoftInput(label: 'Support Email', controller: _supportController, hint: 'support@example.com', keyboardType: TextInputType.emailAddress),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.security, size: 20, color: AppColors.error),
                const SizedBox(width: 8),
                const Text(
                  'Danger Zone',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SoftCard(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red[100]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Maintenance Mode',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Immediately lock the app for all non-admin users.',
                                style: TextStyle(color: AppColors.brandMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: config.maintenanceMode,
                          onChanged: (_) => _toggleMaintenance(),
                          activeThumbColor: AppColors.error,
                          activeTrackColor: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SoftInput(
                    label: 'Global Tax Rate (%)',
                    controller: _taxController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _handleBackup,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandDark,
                      side: const BorderSide(color: AppColors.error),
                      backgroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Run System Backup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          const Text(
            'Payment Configuration',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark),
          ),
          const SizedBox(height: 16),
          SoftCard(
            onTap: () =>
                Navigator.pushNamed(context, '/admin/collection-numbers'),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone_android,
                      size: 24, color: AppColors.brandPrimary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Business Collection Numbers',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandDark),
                      ),
                      const Text(
                        'View mobile money collection numbers',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.brandMuted),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.brandMuted),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Contact superadmin to add or modify collection numbers.',
            style: TextStyle(fontSize: 11, color: AppColors.brandMuted),
          ),
          const SizedBox(height: 24),
          SoftButton(
            title: 'Save Changes',
            variant: SoftButtonVariant.primary,
            onPressed: _handleSave,
          ),
          const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
