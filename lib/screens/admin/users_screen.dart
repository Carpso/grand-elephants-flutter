import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/user.dart';
import 'package:grand_elephants/providers/admin_provider.dart';
import 'package:grand_elephants/providers/auth_provider.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  String _query = '';
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AdminProvider>().loadUsers();
      if (mounted) setState(() => _initialLoading = false);
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
    final actions = <String, Future<void> Function()>{
      'Change role…': () async {
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
        await admin.updateUser(user.uid, role: role);
        if (mounted) ToastProvider.of(context).show('Role updated to $role', ToastType.success);
      },
      if (user.riderStatus == 'pending') ...{
        'Approve rider': () async {
          await admin.updateUser(user.uid, riderStatus: 'approved');
          if (mounted) ToastProvider.of(context).show('${user.name} approved as rider', ToastType.success);
        },
        'Reject rider': () async {
          await admin.updateUser(user.uid, riderStatus: 'rejected');
          if (mounted) ToastProvider.of(context).show('${user.name} rider access rejected', ToastType.info);
        },
      } else if (user.role == 'rider' || user.riderStatus == 'approved') ...{
        'Suspend rider': () async {
          await admin.updateUser(user.uid, riderStatus: 'rejected');
          if (mounted) ToastProvider.of(context).show('${user.name} suspended from riding', ToastType.info);
        },
      },
    };
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(user.name),
        children: actions.keys
            .map((label) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(ctx, label),
                  child: Text(label),
                ))
            .toList(),
      ),
    );
    if (chosen == null) return;
    try {
      await actions[chosen]!();
    } catch (e) {
      if (mounted) ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
    }
  }

  /// Superadmin invite: creates an admin (or superadmin) account by phone —
  /// the server validates permissions and the new code gets an SMS.
  Future<void> _inviteUser() async {
    final auth = context.read<AuthProvider>();
    final messenger = ToastProvider.of(context);
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final roles = ['admin', if (auth.role == 'superadmin') 'superadmin'];
    var role = roles.first;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Add Staff Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'They sign in with their phone number — an invite SMS is sent automatically.',
                style: TextStyle(fontSize: 12, color: AppColors.brandMuted),
              ),
              const SizedBox(height: 12),
              SoftInput(label: 'Phone Number', hint: '0977123456', keyboardType: TextInputType.phone, controller: phoneController),
              const SizedBox(height: 8),
              SoftInput(label: 'Name', hint: 'e.g. Mary', controller: nameController),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: roles
                    .map((r) => DropdownMenuItem(value: r, child: Text(r.toUpperCase())))
                    .toList(),
                onChanged: (v) => setState(() => role = v ?? roles.first),
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
      ),
    );
    final phone = phoneController.text.trim();
    final name = nameController.text.trim();
    nameController.dispose();
    phoneController.dispose();
    if (confirmed != true || !mounted) return;

    if (phone.isEmpty) {
      messenger.show('Phone number is required', ToastType.error);
      return;
    }
    try {
      await context.read<AdminProvider>().createUser(
            phone: phone,
            name: name,
            role: role,
          );
      if (mounted) {
        messenger.show(
          '${name.isEmpty ? phone : name} added as $role',
          ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
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
      appBar: AppBar(
        title: const Text('User Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              icon: const Icon(Icons.person_add, size: 22),
              tooltip: 'Add staff account',
              onPressed: _inviteUser,
            ),
          ),
        ],
      ),
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
              onRefresh: () async => context.read<AdminProvider>().loadUsers(),
              child: _initialLoading
                  ? const Center(child: CircularProgressIndicator())
                  : users.isEmpty
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
                                      if (user.email.isNotEmpty)
                                        Text(user.email, style: const TextStyle(color: AppColors.brandMuted, fontSize: 11)),
                                    ],
                                  ),
                                ),
                                if (user.riderStatus != 'none')
                                  Container(
                                    margin: const EdgeInsets.only(right: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: user.riderStatus == 'approved'
                                          ? Colors.green[50]
                                          : user.riderStatus == 'rejected'
                                              ? Colors.red[50]
                                              : Colors.orange[50],
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'RIDER: ${user.riderStatus.toUpperCase()}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: user.riderStatus == 'approved'
                                            ? Colors.green
                                            : user.riderStatus == 'rejected'
                                                ? Colors.red
                                                : Colors.orange[800],
                                      ),
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