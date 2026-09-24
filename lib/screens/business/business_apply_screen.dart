import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/auth_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';

/// Lets any customer apply to open a shop: POSTs to `/api/businesses/apply`.
class BusinessApplyScreen extends StatefulWidget {
  const BusinessApplyScreen({super.key});

  @override
  State<BusinessApplyScreen> createState() => _BusinessApplyScreenState();
}

class _BusinessApplyScreenState extends State<BusinessApplyScreen> {
  final _nameController = TextEditingController();
  final _sloganController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _tpinController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _sloganController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _tpinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;

    final name = _nameController.text.trim();
    final slogan = _sloganController.text.trim();
    final description = _descriptionController.text.trim();
    final address = _addressController.text.trim();
    final tpin = _tpinController.text.trim();

    if (name.isEmpty || description.isEmpty || address.isEmpty) {
      ToastProvider.of(context)
          .show('Fill in name, description and address', ToastType.error);
      return;
    }

    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    try {
      final res = await ApiClient.instance.post('/api/businesses/apply', body: {
        'name': name,
        'slogan': slogan,
        'description': description,
        'address': address,
        'tpin': tpin.isEmpty ? null : tpin,
      });
      // The server flips the account to `business` on apply; refresh the local
      // session so the profile shows the Business Suite right away.
      if (user != null) {
        await auth.updateProfile(name: user.name, email: user.email);
      }
      if (!mounted) return;
      final message = res is Map && res['businessId'] != null
          ? 'Application submitted — our team will review it shortly'
          : 'Business application submitted for review';
      ToastProvider.of(context).show(message, ToastType.success);
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context)
          .show('$e'.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''), ToastType.error);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softSurface,
      appBar: AppBar(
        title: const Text('Become a Seller'),
        backgroundColor: AppColors.softSurface,
        foregroundColor: AppColors.brandDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Open your shop',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tell us about your business. Our team reviews every application before your storefront goes live.',
            style: TextStyle(color: AppColors.brandMuted, height: 1.5),
          ),
          const SizedBox(height: 24),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SoftInput(
                  label: 'Business Name',
                  hint: 'e.g. Elephant Crafts',
                  controller: _nameController,
                  icon: const Icon(Icons.storefront, size: 20, color: AppColors.brandMuted),
                ),
                SoftInput(
                  label: 'Slogan',
                  hint: 'One line that sells your shop',
                  controller: _sloganController,
                  icon: const Icon(Icons.format_quote, size: 20, color: AppColors.brandMuted),
                ),
                SoftInput(
                  label: 'Description',
                  hint: 'What do you sell?',
                  maxLines: 4,
                  controller: _descriptionController,
                  icon: const Icon(Icons.description, size: 20, color: AppColors.brandMuted),
                ),
                SoftInput(
                  label: 'Address',
                  hint: 'Shop address / area',
                  controller: _addressController,
                  icon: const Icon(Icons.location_on, size: 20, color: AppColors.brandMuted),
                ),
                SoftInput(
                  label: 'TPIN (optional)',
                  hint: 'Tax identification number',
                  keyboardType: TextInputType.number,
                  controller: _tpinController,
                  icon: const Icon(Icons.badge, size: 20, color: AppColors.brandMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftButton(
            title: _submitting ? 'Submitting...' : 'Submit Application',
            variant: SoftButtonVariant.primary,
            isLoading: _submitting,
            onPressed: _submitting ? null : _submit,
          ),
        ],
      ),
    );
  }
}
