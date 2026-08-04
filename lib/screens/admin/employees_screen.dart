import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String _activeTab = 'team';
  dynamic _selectedEmp;
  bool _logsVisible = false;

  List<Map<String, dynamic>> _employees = [
    {'id': 1, 'name': 'Alice Smith', 'role': 'Sales Manager', 'salary': 'K 12,500', 'status': 'Active'},
    {'id': 2, 'name': 'Bob Jones', 'role': 'Delivery Lead', 'salary': 'K 8,800', 'status': 'On Leave'},
    {'id': 3, 'name': 'Charlie Day', 'role': 'Inventory Clerk', 'salary': 'K 6,500', 'status': 'Active'},
  ];

  List<Map<String, dynamic>> _requests = [
    {'id': 101, 'name': 'David Banda', 'role': 'Rider Applicant', 'date': 'Today, 10:30 AM', 'bikeModel': 'Honda Ace 125'},
    {'id': 102, 'name': 'Grace Mumba', 'role': 'Rider Applicant', 'date': 'Yesterday', 'bikeModel': 'Boxer 150'},
  ];

  final List<_ActivityLog> _mockLogs = const [
    _ActivityLog(id: 1, action: 'Clock In', time: '07:58 AM', type: 'success'),
    _ActivityLog(id: 2, action: 'Sale #POS-442 Completed', time: '09:12 AM', type: 'info'),
    _ActivityLog(id: 3, action: 'Break Started', time: '12:00 PM', type: 'warning'),
    _ActivityLog(id: 4, action: 'Break Ended', time: '12:30 PM', type: 'success'),
    _ActivityLog(id: 5, action: 'Inventory Update (Shoes)', time: '02:15 PM', type: 'info'),
  ];

  void _openLogs(Map<String, dynamic> emp) {
    setState(() {
      _selectedEmp = emp;
      _logsVisible = true;
    });
  }

  void _handleApprove(Map<String, dynamic> req) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Rider'),
        content: Text('Are you sure you want to approve ${req['name']}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _requests.removeWhere((r) => r['id'] == req['id']);
                _employees.add({
                  'id': req['id'],
                  'name': req['name'],
                  'role': 'Rider',
                  'salary': 'K 5,000',
                  'status': 'Active',
                });
              });
              Navigator.pop(ctx);
              ToastProvider.of(context).show('Rider approved and added to the team.', ToastType.success);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _handleReject(int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() => _requests.removeWhere((r) => r['id'] == id));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Team Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 'team'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _activeTab == 'team' ? AppColors.brandPrimary : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          'Active Team',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _activeTab == 'team' ? AppColors.brandDark : AppColors.brandMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 'requests'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: _activeTab == 'requests' ? AppColors.brandPrimary : AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Requests',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _activeTab == 'requests' ? AppColors.brandDark : AppColors.brandMuted,
                              ),
                            ),
                            if (_requests.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                                child: Center(
                                  child: Text(
                                    '${_requests.length}',
                                    style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _activeTab == 'team' ? _buildTeamView() : _buildRequestsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamView() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _employees.length,
      itemBuilder: (context, index) {
        final emp = _employees[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: SoftCard(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.softSurface,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (emp['name'] as String)[0],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.brandMuted),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(emp['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.brandDark)),
                          const SizedBox(height: 4),
                          Text(
                            emp['role'] as String,
                            style: const TextStyle(color: AppColors.brandMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: emp['status'] == 'Active' ? Colors.green[100] : Colors.orange[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        emp['status'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: emp['status'] == 'Active' ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: emp['salary'] as String,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.brandDark),
                          ),
                          const TextSpan(
                            text: '/mo',
                            style: TextStyle(fontWeight: FontWeight.normal, fontSize: 13, color: AppColors.brandMuted),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        SoftButton(
                          title: 'Logs',
                          variant: SoftButtonVariant.secondary,
                          onPressed: () => _openLogs(emp),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.softSurface,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit, size: 20, color: AppColors.brandSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestsView() {
    if (_requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, size: 64, color: AppColors.brandMuted),
            const SizedBox(height: 16),
            const Text('No pending requests', style: TextStyle(color: AppColors.brandMuted, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _requests.length,
      itemBuilder: (context, index) {
        final req = _requests[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(16),
              border: const Border(left: BorderSide(color: AppColors.brandPrimary, width: 4)),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                      child: const Icon(Icons.person_add, color: Color(0xFF3B82F6), size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(req['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
                        Text(
                          '${req['role']} • ${req['date']}',
                          style: const TextStyle(color: AppColors.brandMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('VEHICLE DETAILS', style: TextStyle(color: AppColors.brandMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                      const SizedBox(height: 4),
                      Text(req['bikeModel'] as String, style: const TextStyle(color: AppColors.brandDark, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _handleReject(req['id'] as int),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red[600],
                          side: const BorderSide(color: AppColors.error),
                          backgroundColor: Colors.red[50],
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _handleApprove(req),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: AppColors.brandDark,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActivityLog {
  final int id;
  final String action;
  final String time;
  final String type;

  const _ActivityLog({
    required this.id,
    required this.action,
    required this.time,
    required this.type,
  });
}
