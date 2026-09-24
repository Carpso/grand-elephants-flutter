import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/product.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/product_image.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/toast.dart';

/// Read-only stock list for employees, backed by
/// `GET /api/businesses/me/products`.
class EmployeeStockScreen extends StatefulWidget {
  const EmployeeStockScreen({super.key});

  @override
  State<EmployeeStockScreen> createState() => _EmployeeStockScreenState();
}

class _EmployeeStockScreenState extends State<EmployeeStockScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('/api/businesses/me/products');
      if (!mounted) return;
      setState(() {
        _products = (res as List)
            .map((e) => Product.fromJson(e as Map<String, dynamic>))
            .toList();
      });
    } catch (e) {
      if (!mounted) return;
      setState(
          () => _error = '$e'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _retry() async {
    await _load();
    if (!mounted) return;
    if (_error != null) {
      ToastProvider.of(context).show(_error!, ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Business Stock')),
      body: RefreshIndicator(
        onRefresh: _retry,
        child: _loading
            ? ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),
                  Center(
                    child:
                        CircularProgressIndicator(color: AppColors.brandPrimary),
                  ),
                ],
              )
            : _error != null && _products.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 100),
                      const Icon(Icons.error_outline,
                          size: 56, color: AppColors.brandMuted),
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.brandMuted),
                      ),
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: _retry,
                          child: const Text('Retry'),
                        ),
                      ),
                    ],
                  )
                : _products.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 120),
                          Icon(Icons.inventory_2,
                              size: 56, color: AppColors.brandMuted),
                          SizedBox(height: 12),
                          Text(
                            'No stock listed for your business yet',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.brandMuted),
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(20),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SoftCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 56,
                                      height: 56,
                                      child: ProductImage(src: product.image),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          product.name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.brandDark,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          product.category,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: AppColors.brandMuted,
                                          ),
                                        ),
                                        Text(
                                          'K ${product.price.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.brandPrimary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: product.stock > 0
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'Stock ${product.stock}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: product.stock > 0
                                            ? Colors.green.shade700
                                            : AppColors.error,
                                      ),
                                    ),
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
