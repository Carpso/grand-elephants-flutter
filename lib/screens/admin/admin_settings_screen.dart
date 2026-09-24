import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';

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
  bool _maintenance = false;

  @override
  void initState() {
    super.initState();
    final config = context.read<ConfigProvider>();
    _nameController = TextEditingController(text: config.appName);
    _sloganController = TextEditingController(text: config.appSlogan);
    _descriptionController = TextEditingController(text: config.appDescription);
    _logoController = TextEditingController(text: config.appLogo);
    _taxController = TextEditingController(text: config.taxRate.toString());
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSettings());
  }

  Future<void> _loadSettings() async {
    try {
      final res = await ApiClient.instance.get('/api/admin/settings');
      final data = Map<String, dynamic>.from(res as Map);
      if (!mounted) return;
      setState(() {
        _maintenance = '${data['maintenance_mode'] ?? '0'}' == '1';
        if (data['vat_pct'] != null && '${data['vat_pct']}'.isNotEmpty) {
          _taxController.text = '${data['vat_pct']}';
        }
      });
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context)
            .show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sloganController.dispose();
    _descriptionController.dispose();
    _logoController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final messenger = ToastProvider.of(context);
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
      final saved = await ApiClient.instance.get('/api/config', withAuth: false);
      final cfg = Map<String, dynamic>.from(saved as Map);
      if (!mounted) return;
      final persisted = cfg['appName'] == _nameController.text &&
          cfg['appSlogan'] == _sloganController.text &&
          '${cfg['appLogo'] ?? ''}' == _logoController.text;
      if (persisted) {
        messenger.show('Configuration Saved Successfully', ToastType.success);
        Navigator.pop(context);
      } else {
        messenger.show(
            'Settings were not persisted on the server, please try again',
            ToastType.error);
      }
    } catch (e) {
      if (!mounted) return;
      messenger
          .show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
    }
  }

  Future<void> _toggleMaintenance(bool next) async {
    final messenger = ToastProvider.of(context);
    final previous = _maintenance;
    setState(() => _maintenance = next);
    try {
      await ApiClient.instance.patch('/api/admin/settings', body: {
        'maintenance_mode': next ? '1' : '0',
      });
      if (mounted) {
        messenger.show(next
            ? 'Maintenance flag enabled and stored.'
            : 'Maintenance flag disabled.', ToastType.success);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _maintenance = previous);
      messenger.show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  SoftInput(label: 'Slogan / Tagline', controller: _sloganController, hint: 'e.g. Move With Conviction'),
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
                                'Stored flag for the platform — the superadmin console reads it live from the settings API.',
                                style: TextStyle(color: AppColors.brandMuted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _maintenance,
                          onChanged: _toggleMaintenance,
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
