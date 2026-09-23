import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/app_data_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppDataProvider>().loadAddresses();
    });
  }

  Future<void> _handleDelete(Address addr) async {
    final provider = context.read<AppDataProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await provider.removeAddress(addr.id);
      if (mounted) {
        ToastProvider.of(context).show('Address deleted', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('Could not delete address', ToastType.error);
      }
    }
  }

  void _showModal({bool isEditMode = false, Address? address}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddressModal(
        isEditMode: isEditMode,
        address: address,
        onSave: (addr) async {
          final provider = context.read<AppDataProvider>();
          try {
            if (isEditMode) {
              await provider.updateAddress(
                addr.id,
                title: addr.title,
                details: addr.details,
                isDefault: addr.isDefault,
              );
            } else {
              await provider.addAddress(
                title: addr.title,
                details: addr.details,
                isDefault: addr.isDefault,
              );
            }
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (mounted) {
              ToastProvider.of(context).show(
                isEditMode ? 'Address updated' : 'Address added',
                ToastType.success,
              );
            }
          } catch (e) {
            if (ctx.mounted) Navigator.of(ctx).pop();
            if (mounted) {
              ToastProvider.of(context).show('Could not save address', ToastType.error);
            }
          }
        },
        onCancel: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _openAddModal() {
    _showModal(isEditMode: false);
  }

  void _openEditModal(Address addr) {
    _showModal(isEditMode: true, address: addr);
  }

  Future<void> _setDefault(Address addr) async {
    try {
      await context.read<AppDataProvider>().updateAddress(addr.id, isDefault: true);
      if (mounted) {
        ToastProvider.of(context).show('Default address updated', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('Could not update default address', ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppDataProvider>();
    final addresses = provider.addresses;

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      appBar: AppBar(
        title: const Text('Address Book'),
      ),
      body: provider.loading && addresses.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandPrimary))
          : addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_off, size: 64, color: AppColors.brandMuted),
                      const SizedBox(height: 16),
                      const Text(
                        'No addresses saved',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.brandDark),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a delivery address to get started.',
                        style: TextStyle(color: AppColors.brandMuted),
                      ),
                      const SizedBox(height: 24),
                      SoftButton(
                        title: 'Add Address',
                        variant: SoftButtonVariant.primary,
                        onPressed: _openAddModal,
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manage your delivery locations.',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...addresses.map((addr) => SoftCard(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Icon(
                                            addr.title.toLowerCase().contains('home')
                                                ? Icons.home
                                                : Icons.work,
                                            size: 20,
                                            color: AppColors.brandPrimary,
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              addr.title,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.brandDark,
                                              ),
                                            ),
                                          ),
                                          if (addr.isDefault) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.brandPrimary.withValues(alpha: 0.2),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text(
                                                'Default',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.brandPrimary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        GestureDetector(
                                          onTap: () => _openEditModal(addr),
                                          child: const Icon(Icons.edit, size: 24, color: Color(0xFF4B5563)),
                                        ),
                                        const SizedBox(width: 16),
                                        GestureDetector(
                                          onTap: () => _handleDelete(addr),
                                          child: const Icon(Icons.delete_outline, size: 24, color: AppColors.error),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Padding(
                                  padding: const EdgeInsets.only(left: 28),
                                  child: Text(
                                    addr.details,
                                    style: const TextStyle(
                                      color: Color(0xFF4B5563),
                                    ),
                                  ),
                                ),
                                if (!addr.isDefault) ...[
                                  const SizedBox(height: 12),
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: GestureDetector(
                                      onTap: () => _setDefault(addr),
                                      child: const Text(
                                        'Set as Default',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.brandPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                      SoftButton(
                        title: 'Add New Address',
                        variant: SoftButtonVariant.outline,
                        onPressed: _openAddModal,
                      ),
                    ],
                  ),
                ),
    );
  }
}

class _AddressModal extends StatefulWidget {
  final bool isEditMode;
  final Address? address;
  final ValueChanged<Address> onSave;
  final VoidCallback onCancel;

  const _AddressModal({
    required this.isEditMode,
    this.address,
    required this.onSave,
    required this.onCancel,
  });

  @override
  State<_AddressModal> createState() => _AddressModalState();
}

class _AddressModalState extends State<_AddressModal> {
  late TextEditingController _titleController;
  late TextEditingController _detailsController;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.address?.title ?? '');
    _detailsController = TextEditingController(text: widget.address?.details ?? '');
    _isDefault = widget.address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.isEmpty || _detailsController.text.isEmpty) {
      ToastProvider.of(context).show('Please fill all fields', ToastType.error);
      return;
    }
    widget.onSave(Address(
      id: widget.address?.id ?? '',
      title: _titleController.text,
      details: _detailsController.text,
      isDefault: _isDefault,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isEditMode ? 'Edit Address' : 'New Address',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Label (e.g. Home, Office)',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Home',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Address Details',
              style: TextStyle(
                color: Color(0xFF4B5563),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Street, City, Province...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Set as Default Address',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF374151),
                  ),
                ),
                Switch(
                  value: _isDefault,
                  onChanged: (v) => setState(() => _isDefault = v),
                  activeTrackColor: AppColors.brandPrimary,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SoftButton(
                    title: 'Cancel',
                    variant: SoftButtonVariant.outline,
                    onPressed: widget.onCancel,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SoftButton(
                    title: 'Save Address',
                    variant: SoftButtonVariant.primary,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).viewInsets.bottom > 0 ? 0 : 32),
          ],
        ),
      ),
    );
  }
}