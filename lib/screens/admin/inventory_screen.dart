import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/product.dart';
import 'package:sell_on_app/screens/admin/add_product_screen.dart';
import 'package:sell_on_app/services/api_client.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await ApiClient.instance.get('/api/businesses/me/products');
      if (mounted) {
        setState(() {
          _products = (res as List)
              .map((e) => Product.fromJson(e as Map<String, dynamic>))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _products = []);
    }
  }

  void _openAdd() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const AddProductScreen()))
        .then((_) => _load());
  }

  Future<void> _handleDelete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to remove ${product.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await ApiClient.instance.delete('/api/businesses/me/products/${product.id}');
      await _load();
      if (mounted) {
        ToastProvider.of(context).show('${product.name} deleted.', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    }
  }

  Future<void> _handleEdit(Product product) async {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price.toStringAsFixed(2));
    final stockController = TextEditingController(text: '${product.stock}');
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Product'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price (K)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Stock'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true || !mounted) return;
    try {
      await ApiClient.instance.put('/api/businesses/me/products/${product.id}', body: {
        'name': nameController.text,
        'price': double.tryParse(priceController.text) ?? product.price,
        'stock': int.tryParse(stockController.text) ?? product.stock,
      });
      await _load();
      if (mounted) {
        ToastProvider.of(context).show('${product.name} updated.', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    }
  }

  Widget _buildImage(String image) {
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return Image.network(
        image,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image, color: AppColors.brandMuted)),
      );
    }
    return Image.asset(
      image,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey[200], child: const Icon(Icons.image, color: AppColors.brandMuted)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.softSurface,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.add, color: AppColors.brandPrimary, size: 22),
                onPressed: _openAdd,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _products.isEmpty
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Icon(Icons.inventory_2, size: 56, color: AppColors.brandMuted),
                  SizedBox(height: 12),
                  Text(
                    'No products in inventory',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.brandMuted),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _products.length,
                itemBuilder: (context, index) {
                  final product = _products[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: SoftCard(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 80,
                              height: 80,
                              child: _buildImage(product.image),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(product.category, style: const TextStyle(color: AppColors.brandMuted, fontSize: 13)),
                                const SizedBox(height: 4),
                                Text(
                                  'K ${product.price} • Stock: ${product.stock}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandPrimary),
                                ),
                              ],
                            ),
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: () => _handleEdit(product),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.softSurface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit, size: 16, color: AppColors.brandSecondary),
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () => _handleDelete(product),
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: AppColors.softSurface,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.delete, size: 16, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}