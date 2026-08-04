import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<_UserData> _users = [
    _UserData(id: 1, name: 'John Doe', email: 'john@example.com', role: 'Customer', status: 'Active', joined: 'Oct 2025'),
    _UserData(id: 2, name: 'Sarah Connor', email: 'sarah@example.com', role: 'Customer', status: 'Banned', joined: 'Nov 2025'),
    _UserData(id: 3, name: 'Kyle Reese', email: 'kyle@example.com', role: 'Rider', status: 'Active', joined: 'Sep 2025'),
    _UserData(id: 4, name: 'Jane Austen', email: 'jane@books.com', role: 'Customer', status: 'Active', joined: 'Dec 2025'),
  ];

  void _toggleStatus(int id) {
    setState(() {
      _users = _users.map((u) {
        if (u.id == id) {
          final newStatus = u.status == 'Active' ? 'Banned' : 'Active';
          return _UserData(id: u.id, name: u.name, email: u.email, role: u.role, status: newStatus, joined: u.joined);
        }
        return u;
      }).toList();
    });
  }

  void _handleDelete(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('Are you sure? This action is irreversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _users.removeWhere((u) => u.id == id));
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
    return Scaffold(
      appBar: AppBar(title: const Text('User Management')),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.grey[100],
                        child: Text(
                          user.name[0],
                          style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandMuted),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
                            Text(user.email, style: const TextStyle(color: AppColors.brandMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: user.status == 'Active' ? Colors.green[100] : Colors.red[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          user.status,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: user.status == 'Active' ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('ROLE', style: TextStyle(color: AppColors.brandMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(user.role, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.brandSecondary)),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('JOINED', style: TextStyle(color: AppColors.brandMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                            const SizedBox(height: 4),
                            Text(user.joined, style: const TextStyle(fontWeight: FontWeight.w500, color: AppColors.brandSecondary)),
                          ],
                        ),
                        Switch(
                          value: user.status == 'Active',
                          onChanged: (_) => _toggleStatus(user.id),
                          activeThumbColor: AppColors.brandPrimary,
                          activeTrackColor: AppColors.success,
                          inactiveTrackColor: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Reset Password'),
                              content: Text('Send reset email to ${user.email}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Send')),
                              ],
                            ),
                          );
                        },
                        child: const Text('Reset Password', style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => _handleDelete(user.id),
                        child: const Text('Delete', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UserData {
  final int id;
  final String name;
  final String email;
  final String role;
  final String status;
  final String joined;

  const _UserData({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.joined,
  });
}
