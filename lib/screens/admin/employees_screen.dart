import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/admin_provider.dart';
import 'package:sell_on_app/services/api_client.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({super.key});

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  String _activeTab = 'team';
  bool _loadingLogs = false;
  List<Map<String, dynamic>> _auditLogs = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadStats();
      admin.loadRiders();
      _loadAuditLogs();
    });
  }

  Future<void> _loadAuditLogs() async {
    setState(() => _loadingLogs = true);
    try {
      final res = await ApiClient.instance.get('/api/admin/actions');
      if (mounted) {
        setState(() {
          _auditLogs = (res as List)
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        });
      }
    } catch (e) {
      if (mounted) setState(() => _auditLogs = []);
    } finally {
      if (mounted) setState(() => _loadingLogs = false);
    }
  }

  Future<void> _approveRider(Map<String, dynamic> app) async {
    final name = app['name'] ?? 'Rider';
    final admin = context.read<AdminProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve Rider'),
        content: Text('Are you sure you want to approve $name?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    try {
      await admin.approveRiderApplication('${app['id']}');
      if (mounted) {
        ToastProvider.of(context).show('$name approved and added to the team.', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    }
  }

  Future<void> _rejectRider(Map<String, dynamic> app) async {
    final name = app['name'] ?? 'Rider';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Application'),
        content: Text('Reject $name? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final admin = context.read<AdminProvider>();
    try {
      await ApiClient.instance.patch('/api/admin/users/${app['id']}',
          body: {'riderStatus': 'rejected'});
      await admin.loadRiders();
      if (mounted) {
        ToastProvider.of(context).show('$name rejected.', ToastType.info);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final requests = admin.riderApplications;

    return Scaffold(
      appBar: AppBar(title: const Text('Team Management')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab('team', 'Active Team'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTab('requests', 'Requests', badge: requests.length),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildTab('logs', 'Audit Log'),
                ),
              ],
            ),
          ),
          Expanded(
            child: _activeTab == 'team'
                ? _buildTeamView(admin)
                : _activeTab == 'requests'
                    ? _buildRequestsView(requests)
                    : _buildLogsView(),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String tab, String label, {int badge = 0}) {
    final active = _activeTab == tab;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = tab),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: active ? AppColors.brandPrimary : AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: active ? AppColors.brandDark : AppColors.brandMuted,
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(width: 6),
                Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(color: AppColors.error, shape: BoxShape.circle),
                  child: Center(
                    child: Text(
                      '$badge',
                      style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamView(AdminProvider admin) {
    final stats = admin.stats;
    final riders = admin.riders.where((r) => r.status == 'approved').toList();

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(child: _buildStatTile(Icons.people, '${stats.users}', 'USERS')),
            const SizedBox(width: 8),
            Expanded(child: _buildStatTile(Icons.storefront, '${stats.businesses}', 'BUSINESSES')),
            const SizedBox(width: 8),
            Expanded(child: _buildStatTile(Icons.receipt_long, '${stats.orders}', 'ORDERS')),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Approved Riders (${riders.length})',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark),
        ),
        const SizedBox(height: 12),
        if (riders.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text('No approved riders yet.', style: TextStyle(color: AppColors.brandMuted)),
            ),
          )
        else
          ...riders.map((rider) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SoftCard(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(color: AppColors.softSurface, shape: BoxShape.circle),
                        child: Center(
                          child: Text(
                            rider.name.isNotEmpty ? rider.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.brandMuted),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(rider.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
                            const SizedBox(height: 4),
                            Text(
                              rider.vehicle.isNotEmpty ? rider.vehicle : rider.phone,
                              style: const TextStyle(color: AppColors.brandMuted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green[100],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Active',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  Widget _buildStatTile(IconData icon, String value, String label) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.brandPrimary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.brandDark)),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildRequestsView(List<Map<String, dynamic>> requests) {
    if (requests.isEmpty) {
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
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final name = '${req['name'] ?? ''}';
        final phone = '${req['phone'] ?? ''}';
        final vehicle = '${req['vehicle'] ?? ''}';
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
                          if (phone.isNotEmpty)
                            Text(phone, style: const TextStyle(color: AppColors.brandMuted, fontSize: 12)),
                        ],
                      ),
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
                      Text(
                        vehicle.isEmpty ? 'Not provided' : vehicle,
                        style: const TextStyle(color: AppColors.brandDark, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _rejectRider(req),
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
                        onPressed: () => _approveRider(req),
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

  Widget _buildLogsView() {
    if (_loadingLogs) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_auditLogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.receipt_long, size: 64, color: AppColors.brandMuted),
            const SizedBox(height: 16),
            const Text('No admin actions recorded', style: TextStyle(color: AppColors.brandMuted, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: _auditLogs.length,
      itemBuilder: (context, index) {
        final log = _auditLogs[index];
        final title = log['action'] ?? log['type'] ?? log['description'] ?? 'Admin action';
        final subtitle = log['time'] ?? log['createdAt'] ?? log['email'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: SoftCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.history, size: 18, color: AppColors.brandPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark)),
                      if (subtitle.isNotEmpty)
                        Text(subtitle, style: const TextStyle(color: AppColors.brandMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}