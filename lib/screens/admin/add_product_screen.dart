import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/auth_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  String? _image;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null && mounted) {
      setState(() => _image = picked.path);
    }
  }

  Future<void> _handleCreate() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _categoryController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _image == null) {
      ToastProvider.of(context).show('Please fill in all fields and add an image.', ToastType.error);
      return;
    }

    final businessId = context.read<AuthProvider>().user?.businessId;
    if (businessId == null || businessId.isEmpty) {
      ToastProvider.of(context).show('Create a business first', ToastType.error);
      return;
    }

    setState(() => _loading = true);
    try {
      await ApiClient.instance.post('/api/businesses/me/products', body: {
        'name': _nameController.text,
        'price': double.tryParse(_priceController.text) ?? 0,
        'image': _image,
        'description': _descriptionController.text,
        'category': _categoryController.text,
        'stock': int.tryParse(_stockController.text) ?? 0,
      });
      if (!mounted) return;
      ToastProvider.of(context).show('Product added successfully to inventory.', ToastType.success);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.brandSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: SizedBox(
                width: 280,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(color: AppColors.white, width: 4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (_image != null)
                          Image.file(File(_image!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]))
                        else
                          const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 32, color: AppColors.brandPrimary),
                                SizedBox(height: 16),
                                Text('Tap to choose an image', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.brandDark)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Product Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark),
              ),
            ),
            const SizedBox(height: 16),
            SoftInput(
              hint: 'Product Name',
              controller: _nameController,
              icon: const Icon(Icons.label, size: 20, color: AppColors.brandMuted),
            ),
            Row(
              children: [
                Expanded(
                  child: SoftInput(
                    hint: 'Price (K)',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    icon: const Icon(Icons.attach_money, size: 20, color: AppColors.brandMuted),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SoftInput(
                    hint: 'Category',
                    controller: _categoryController,
                    icon: const Icon(Icons.category, size: 20, color: AppColors.brandMuted),
                  ),
                ),
              ],
            ),
            SoftInput(
              hint: 'Stock Quantity',
              controller: _stockController,
              keyboardType: TextInputType.number,
              icon: const Icon(Icons.inventory_2, size: 20, color: AppColors.brandMuted),
            ),
            SoftInput(
              hint: 'Description',
              controller: _descriptionController,
              maxLines: 4,
              icon: const Icon(Icons.description, size: 20, color: AppColors.brandMuted),
            ),
            const SizedBox(height: 16),
            SoftButton(
              title: _loading ? 'Publishing...' : 'Publish Product',
              variant: SoftButtonVariant.primary,
              isLoading: _loading,
              icon: _loading ? null : const Icon(Icons.check, size: 20, color: AppColors.brandDark),
              onPressed: _loading ? null : _handleCreate,
            ),
          ],
        ),
      ),
    );
  }
}