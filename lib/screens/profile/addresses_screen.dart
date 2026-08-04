import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class _Address {
  final String id;
  String title;
  String details;
  bool isDefault;

  _Address({
    required this.id,
    required this.title,
    required this.details,
    this.isDefault = false,
  });
}

class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  List<_Address> _addresses = [
    _Address(id: '1', title: 'Home', details: 'Plot 44, Kabulonga, Lusaka', isDefault: true),
    _Address(id: '2', title: 'Office', details: 'Carousel Shopping Mall, Shop 4', isDefault: false),
  ];

  bool _isEditMode = false;
  _Address _currentAddress = _Address(id: '', title: '', details: '');

  void _handleDelete(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _addresses.removeWhere((a) => a.id == id));
              Navigator.of(ctx).pop();
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openAddModal() {
    setState(() {
      _isEditMode = false;
      _currentAddress = _Address(id: '', title: '', details: '');
    });
    _showModal();
  }

  void _openEditModal(_Address addr) {
    setState(() {
      _isEditMode = true;
      _currentAddress = _Address(id: addr.id, title: addr.title, details: addr.details, isDefault: addr.isDefault);
    });
    _showModal();
  }

  void _showModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressModal(
        isEditMode: _isEditMode,
        address: _currentAddress,
        onSave: (addr) {
          setState(() {
            if (_isEditMode) {
              final idx = _addresses.indexWhere((a) => a.id == addr.id);
              if (idx >= 0) {
                _addresses[idx] = addr;
              }
            } else {
              final newAddr = _Address(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: addr.title,
                details: addr.details,
                isDefault: addr.isDefault,
              );
              _addresses.add(newAddr);
            }

            if (addr.isDefault) {
              for (var i = 0; i < _addresses.length; i++) {
                _addresses[i].isDefault = _addresses[i].id == addr.id;
              }
            }
          });
          Navigator.of(context).pop();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softSurface,
      appBar: AppBar(
        title: const Text('Address Book'),
      ),
      body: SingleChildScrollView(
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
            ..._addresses.map((addr) => SoftCard(
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
                                  addr.title == 'Home' ? Icons.home : Icons.work,
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
                                onTap: () => _handleDelete(addr.id),
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
  final _Address address;
  final ValueChanged<_Address> onSave;
  final VoidCallback onCancel;

  const _AddressModal({
    required this.isEditMode,
    required this.address,
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
    _titleController = TextEditingController(text: widget.address.title);
    _detailsController = TextEditingController(text: widget.address.details);
    _isDefault = widget.address.isDefault;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _save() {
    if (_titleController.text.isEmpty || _detailsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    widget.onSave(_Address(
      id: widget.address.id,
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
