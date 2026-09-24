import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/business_collection_number.dart';
import 'package:grand_elephants/providers/auth_provider.dart';
import 'package:grand_elephants/providers/collection_number_provider.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';

/// Collection numbers for the signed-in scope: staff/superadmin see every
/// field (including the business name/id they are editing for), a plain
/// business only sees its own mobile money details.
class CollectionNumbersScreen extends StatefulWidget {
  const CollectionNumbersScreen({super.key});

  @override
  State<CollectionNumbersScreen> createState() =>
      _CollectionNumbersScreenState();
}

class _CollectionNumbersScreenState extends State<CollectionNumbersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<CollectionNumberProvider>().load();
    });
  }

  bool get _managesBusinessFields =>
      context.read<AuthProvider>().role != 'business';

  Future<void> _guard(Future<bool> action) async {
    final ok = await action;
    if (!mounted || ok) return;
    final provider = context.read<CollectionNumberProvider>();
    ToastProvider.of(context).show(
      provider.error ?? 'Could not save collection number',
      ToastType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Numbers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<CollectionNumberProvider>().load(),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context),
          ),
        ],
      ),
      body: Consumer<CollectionNumberProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading && provider.numbers.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.numbers.isEmpty) {
            final message = provider.error ??
                'No collection numbers configured';
            return RefreshIndicator(
              onRefresh: () => provider.load(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  const Icon(Icons.phone_android,
                      size: 64, color: AppColors.brandMuted),
                  const SizedBox(height: 16),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style:
                        const TextStyle(fontSize: 18, color: AppColors.brandMuted),
                  ),
                  if (provider.error != null) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => provider.load(),
                        child: const Text('Retry',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Add a mobile money collection number\nto start accepting payments',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.brandMuted),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () => _showAddDialog(context),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Collection Number'),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => provider.load(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                ...provider.numbers.map((number) =>
                    _buildNumberCard(context, provider, number)),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brandPrimary,
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add, color: AppColors.brandDark),
      ),
    );
  }

  Widget _buildNumberCard(BuildContext context,
      CollectionNumberProvider provider, BusinessCollectionNumber number) {
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _networkColor(number.network).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.phone_android,
                  color: _networkColor(number.network),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number.businessName.isEmpty
                          ? number.phoneNumber
                          : number.businessName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.brandDark,
                      ),
                    ),
                    Text(
                      '${number.network.displayName} • ${number.phoneNumber}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.brandMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (number.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              GestureDetector(
                onTap: () => _guard(provider.toggleActive(number.id)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: number.isActive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    number.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: number.isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ),
              if (!number.isDefault) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _guard(provider.setDefault(number.id)),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandSecondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Set Default',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandSecondary,
                      ),
                    ),
                  ),
                ),
              ],
              const Spacer(),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    _showEditDialog(context, provider, number);
                  } else if (value == 'delete') {
                    _confirmDelete(context, provider, number);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _networkColor(MobileMoneyNetwork network) {
    switch (network) {
      case MobileMoneyNetwork.mtn:
        return const Color(0xFFFFCC00);
      case MobileMoneyNetwork.airtel:
        return const Color(0xFFE30613);
      case MobileMoneyNetwork.zamtel:
        return const Color(0xFF00A651);
    }
  }

  void _showAddDialog(BuildContext context) {
    _showFormDialog(context, isEdit: false);
  }

  void _showEditDialog(BuildContext context,
      CollectionNumberProvider provider, BusinessCollectionNumber number) {
    _showFormDialog(context, isEdit: true, existing: number);
  }

  void _showFormDialog(BuildContext context,
      {bool isEdit = false, BusinessCollectionNumber? existing}) {
    final manageFields = _managesBusinessFields;
    final nameController =
        TextEditingController(text: existing?.businessName ?? '');
    final phoneController =
        TextEditingController(text: existing?.phoneNumber ?? '');
    final tillController =
        TextEditingController(text: existing?.tillNumber ?? '');
    final businessIdController =
        TextEditingController(text: existing?.businessId ?? '');
    MobileMoneyNetwork selectedNetwork =
        existing?.network ?? MobileMoneyNetwork.mtn;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEdit
                          ? 'Edit Collection Number'
                          : 'Add Collection Number',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.brandDark,
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (manageFields) ...[
                      SoftInput(
                        label: 'Business Name',
                        controller: nameController,
                        hint: 'e.g. Grand Elephants Boutique',
                      ),
                      const SizedBox(height: 12),
                      SoftInput(
                        label: 'Business ID',
                        controller: businessIdController,
                        hint: 'e.g. BE-001',
                      ),
                      const SizedBox(height: 12),
                    ],
                    const Text(
                      'Mobile Money Network',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<MobileMoneyNetwork>(
                      initialValue: selectedNetwork,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.softSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: MobileMoneyNetwork.values.map((network) {
                        return DropdownMenuItem(
                          value: network,
                          child: Text(network.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedNetwork = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SoftInput(
                      label: 'Phone Number',
                      controller: phoneController,
                      hint: '0977123456',
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    SoftInput(
                      label: 'Till Number (optional)',
                      controller: tillController,
                      hint: '*488*{till}*{amount}#',
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () async {
                        if (phoneController.text.isEmpty ||
                            (manageFields && nameController.text.isEmpty)) {
                          ToastProvider.of(ctx).show(
                              manageFields
                                  ? 'Business name and phone are required'
                                  : 'Phone number is required',
                              ToastType.error);
                          return;
                        }

                        final now = DateTime.now();
                        final number = BusinessCollectionNumber(
                          id: existing?.id ??
                              'col_${now.millisecondsSinceEpoch}',
                          businessName: nameController.text,
                          businessId: businessIdController.text,
                          network: selectedNetwork,
                          phoneNumber: phoneController.text,
                          tillNumber: tillController.text,
                          isActive: existing?.isActive ?? true,
                          isDefault: existing?.isDefault ?? false,
                          createdAt: existing?.createdAt ?? now,
                          updatedAt: now,
                          addedBy: existing?.addedBy ?? 'superadmin',
                        );

                        final prov = ctx.read<CollectionNumberProvider>();
                        final ok = isEdit
                            ? await prov.updateNumber(number.id, number)
                            : await prov.addNumber(number);

                        if (!ctx.mounted) return;
                        if (!ok) {
                          ToastProvider.of(ctx).show(
                            prov.error ?? 'Could not save collection number',
                            ToastType.error,
                          );
                          return;
                        }
                        ToastProvider.of(ctx).show(
                          isEdit ? 'Collection number updated' : 'Collection number added',
                          ToastType.success,
                        );
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: AppColors.brandDark,
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isEdit ? 'Update Number' : 'Add Number',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      phoneController.dispose();
      tillController.dispose();
      businessIdController.dispose();
    });
  }

  void _confirmDelete(BuildContext context, CollectionNumberProvider provider,
      BusinessCollectionNumber number) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Collection Number'),
        content: Text(
            'Remove ${number.businessName.isEmpty ? number.phoneNumber : number.businessName} (${number.network.displayName})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _removeNumber(provider, number);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _removeNumber(CollectionNumberProvider provider,
      BusinessCollectionNumber number) async {
    final ok = await provider.removeNumber(number.id);
    if (!mounted || ok) return;
    ToastProvider.of(context).show(
      provider.error ?? 'Could not delete collection number',
      ToastType.error,
    );
  }
}
