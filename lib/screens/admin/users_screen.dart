import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/user.dart';
import 'package:sell_on_app/providers/admin_provider.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadUsers();
    });
  }

  Future<void> _changeRole(User user) async {
    final roles = ['user', 'rider', 'business', 'employee', 'admin'];
    final admin = context.read<AdminProvider>();
    final role = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text('Set role for ${user.name}'),
        children: roles
            .map((r) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, r),
                  child: Text(r.toUpperCase()),
                ))
            .toList(),
      ),
    );
    if (role == null || role == user.role) return;
    try {
      await admin.updateUser(user.uid, role: role);
      if (mounted) ToastProvider.of(context).show('Role updated to $role', ToastType.success);
    } catch (e) {
      if (mounted) ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final users = _query.isEmpty
        ? admin.users
        : admin.users
            .where((u) =>
                u.name.toLowerCase().contains(_query.toLowerCase()) ||
                u.phone.contains(_query) ||
                u.email.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search by name, phone or email',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AppColors.softSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => admin.loadUsers(),
              child: users.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Icon(Icons.people_outline, size: 56, color: AppColors.brandMuted),
                        SizedBox(height: 12),
                        Text(
                          'No users found',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.brandMuted),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SoftCard(
                            onTap: () => _changeRole(user),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.grey[100],
                                  child: Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandMuted),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.brandDark)),
                                      Text(user.phone, style: const TextStyle(color: AppColors.brandMuted, fontSize: 12)),
                                      Text(user.email, style: const TextStyle(color: AppColors.brandMuted, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    user.role.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandSecondary),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}