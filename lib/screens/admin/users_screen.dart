import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/user.dart';
import 'package:grand_elephants/providers/admin_provider.dart';
import 'package:grand_elephants/providers/auth_provider.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/toast.dart';

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
    final auth = context.read<AuthProvider>();
    final admin = context.read<AdminProvider>();
    // The server only lets a superadmin grant the superadmin role.
    final roles = [
      'user',
      'rider',
      'business',
      'employee',
      'admin',
      if (auth.role == 'superadmin') 'superadmin',
    ];
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
                      children: [
                        const SizedBox(height: 120),
                        Icon(
                          admin.error != null ? Icons.cloud_off : Icons.people_outline,
                          size: 56,
                          color: AppColors.brandMuted,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          admin.error != null
                              ? '${admin.error}'.replaceFirst('Exception: ', '')
                              : 'No users found',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.brandMuted),
                        ),
                        if (admin.error != null)
                          TextButton(
                            onPressed: () => admin.loadUsers(),
                            child: const Text('Retry'),
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