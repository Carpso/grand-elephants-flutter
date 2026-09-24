import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/toast.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _saving = false;

  Future<void> _handleAdd() async {
    final nameController = TextEditingController();
    final iconController = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name', hintText: 'e.g. Bags'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(labelText: 'Icon', hintText: 'e.g. \u{1F45C}'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (created != true || !mounted) return;

    final name = nameController.text.trim();
    final icon = iconController.text.trim();
    if (name.isEmpty || icon.isEmpty) {
      ToastProvider.of(context).show('Name and Icon are required', ToastType.error);
      return;
    }

    setState(() => _saving = true);
    try {
      await ApiClient.instance.post('/api/admin/categories', body: {'name': name, 'icon': icon});
      if (!mounted) return;
      context.read<ConfigProvider>().addCategory(name, icon);
      ToastProvider.of(context).show('Category "$name" added.', ToastType.success);
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
            onPressed: _saving ? null : _handleAdd,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Categories live on the storefront. Use the + button to add a new one.',
              style: TextStyle(color: AppColors.brandMuted),
            ),
            const SizedBox(height: 16),
            ...categories.map((cat) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SoftCard(
                    child: Row(
                      children: [
                        Text(cat.icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ),
                        const Icon(Icons.check_circle,
                            size: 20, color: AppColors.success),
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