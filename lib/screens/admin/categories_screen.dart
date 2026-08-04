import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _modalVisible = false;
  final _nameController = TextEditingController();
  final _iconController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    if (_nameController.text.isEmpty || _iconController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and Icon are required')));
      return;
    }
    context.read<ConfigProvider>().addCategory(_nameController.text, _iconController.text);
    setState(() => _modalVisible = false);
    _nameController.clear();
    _iconController.clear();
  }

  void _deleteCategory(String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              final config = context.read<ConfigProvider>();
              config.setCategories(config.categories.where((c) => c.id != id).toList());
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final categories = config.categories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.brandPrimary, size: 28),
            onPressed: () => setState(() => _modalVisible = true),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manage product categories. Use the + button to add new ones.',
              style: TextStyle(color: AppColors.brandMuted),
            ),
            const SizedBox(height: 16),
            ...categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SoftCard(
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(cat.icon, style: const TextStyle(fontSize: 24)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                cat.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: cat.enabled ? AppColors.brandDark : AppColors.brandMuted,
                                ),
                              ),
                            ),
                            Switch(
                              value: cat.enabled,
                              onChanged: (_) {
                                config.setCategories(categories.map((c) {
                                  if (c.id == cat.id) {
                                    return Category(id: c.id, name: c.name, icon: c.icon, enabled: !c.enabled);
                                  }
                                  return c;
                                }).toList());
                              },
                              activeThumbColor: AppColors.brandPrimary,
                              activeTrackColor: AppColors.brandPrimary,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextButton(
                                onPressed: () => _deleteCategory(cat.id),
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.red[50],
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
