import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';

/// Team members of the caller's business (from GET /api/businesses/me).
class BusinessStaffScreen extends StatefulWidget {
  const BusinessStaffScreen({super.key});

  @override
  State<BusinessStaffScreen> createState() => _BusinessStaffScreenState();
}

class _BusinessStaffScreenState extends State<BusinessStaffScreen> {
  List<Map<String, dynamic>> _staff = [];
  String? _error;
  bool _loading = true;

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
      final res = await ApiClient.instance.get('/api/businesses/me');
      final business = (res as Map)['business'] as Map<String, dynamic>?;
      if (mounted) {
        setState(() {
          _staff = ((business?['staff'] as List?) ?? [])
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e'.replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  Future<void> _addStaff() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final messenger = ToastProvider.of(context);
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Staff Member'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'They get access with their phone number — new numbers are invited automatically.',
              style: TextStyle(fontSize: 12, color: AppColors.brandMuted),
            ),
            const SizedBox(height: 12),
            SoftInput(label: 'Name', controller: nameController),
            const SizedBox(height: 8),
            SoftInput(
              label: 'Phone number',
              controller: phoneController,
              keyboardType: TextInputType.phone,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (added != true || !mounted) return;
    final phone = phoneController.text.trim();
    if (phone.isEmpty) {
      messenger.show('Phone number is required', ToastType.error);
      return;
    }
    try {
      await ApiClient.instance.post('/api/businesses/me/staff', body: {
        'name': nameController.text.trim(),
        'phone': phone,
      });
      if (mounted) {
        messenger.show('${nameController.text.trim().isEmpty ? phone : nameController.text.trim()} added to the team.', ToastType.success);
      }
      await _load();
    } catch (e) {
      if (mounted) {
        messenger.show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Team Members'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.softSurface,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.person_add, color: AppColors.brandPrimary, size: 22),
                onPressed: _addStaff,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.brandPrimary),
              )
            : _error != null
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      const SizedBox(height: 120),
                      const Icon(Icons.cloud_off, size: 56, color: AppColors.brandMuted),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.brandMuted),
                        ),
                      ),
                      TextButton(onPressed: _load, child: const Text('Retry')),
                    ],
                  )
                : _staff.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 120),
                          const Icon(Icons.group, size: 56, color: AppColors.brandMuted),
                          const SizedBox(height: 12),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              'No team members yet. Add staff with the + button.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.brandMuted),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: SoftButton(
                              title: 'Add Staff Member',
                              variant: SoftButtonVariant.primary,
                              onPressed: _addStaff,
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _staff.length,
                        itemBuilder: (context, index) {
                          final member = _staff[index];
                          final name = '${member['name'] ?? ''}'.isEmpty
                              ? 'Team member'
                              : '${member['name']}';
                          final phone = '${member['phone'] ?? ''}';
                          final role = '${member['role_in_business'] ?? 'staff'}';
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SoftCard(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: const BoxDecoration(
                                      color: AppColors.softSurface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person, size: 20, color: AppColors.brandPrimary),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.brandDark,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          phone,
                                          style: const TextStyle(
                                            color: AppColors.brandMuted,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.softSurface,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      role.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.brandSecondary,
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
