import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/admin_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class RidersScreen extends StatefulWidget {
  const RidersScreen({super.key});

  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().loadRiders();
    });
  }

  Future<void> _handlePayout(AdminRider rider) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payout'),
        content: Text('Pay K ${rider.balance.toStringAsFixed(2)} to ${rider.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await context.read<AdminProvider>().payRider(rider.id);
                if (mounted) {
                  ToastProvider.of(context).show('Payout to ${rider.name} processed.', ToastType.success);
                }
              } catch (e) {
                if (mounted) {
                  ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
                }
              }
            },
            child: const Text('Confirm Pay'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(AdminRider rider) async {
    final newStatus = rider.status == 'approved' ? 'suspended' : 'approved';
    try {
      await context.read<AdminProvider>().setRiderStatus(rider.id, newStatus);
      if (mounted) {
        ToastProvider.of(context).show('${rider.name} is now $newStatus', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    }
  }

  Future<void> _approveApplication(Map<String, dynamic> app) async {
    try {
      await context.read<AdminProvider>().approveRiderApplication('${app['id']}');
      if (mounted) {
        ToastProvider.of(context).show('${app['name']} approved as rider', ToastType.success);
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Management'),
      ),
      body: RefreshIndicator(
        onRefresh: () => admin.loadRiders(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.people,
                      label: 'FLEET',
                      value: '${admin.riders.length}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.pending_actions,
                      label: 'APPLICATIONS',
                      value: '${admin.riderApplications.length}',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.payments,
                      label: 'PENDING PAYOUTS',
                      value: '${admin.payouts.where((p) => p.status == 'processing').length}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  _buildTab('Riders', 0),
                  const SizedBox(width: 8),
                  _buildTab('Applications', 1),
                  const SizedBox(width: 8),
                  _buildTab('Payouts', 2),
                ],
              ),
              const SizedBox(height: 16),
              if (_tab == 0) ..._buildRiderList(admin),
              if (_tab == 1) ..._buildApplications(admin),
              if (_tab == 2) ..._buildPayouts(admin),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final active = _tab == index;
    return Expanded(
      child: SoftButton(
        title: label,
        variant: active ? SoftButtonVariant.primary : SoftButtonVariant.secondary,
        onPressed: () => setState(() => _tab = index),
      ),
    );
  }

  List<Widget> _buildRiderList(AdminProvider admin) {
    if (admin.riders.isEmpty) {
      return [
        const Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
            child: Text('No riders yet. Approve applications to grow your fleet.', style: TextStyle(color: AppColors.brandMuted)),
          ),
        ),
      ];
    }
    return admin.riders.map((rider) {
      final isApproved = rider.status == 'approved';
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
                      rider.name.isNotEmpty ? rider.name[0] : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.brandMuted),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(rider.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
                        if (rider.vehicle.isNotEmpty) Text(rider.vehicle, style: const TextStyle(fontSize: 12, color: AppColors.brandMuted)),
                        Text('${rider.phone} • ${rider.businessName}', style: const TextStyle(fontSize: 12, color: AppColors.brandMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isApproved ? Colors.green[100] : Colors.orange[100],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rider.status.toUpperCase(),
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isApproved ? Colors.green : Colors.orange),
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
                    const Text('Wallet Balance', style: TextStyle(color: AppColors.brandMuted, fontWeight: FontWeight.w500, fontSize: 13)),
                    Text('K ${rider.balance.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.brandDark)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: SoftButton(
                      title: 'Payout',
                      variant: SoftButtonVariant.primary,
                      onPressed: rider.balance <= 0 ? null : () => _handlePayout(rider),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SoftButton(
                      title: isApproved ? 'Suspend' : 'Approve',
                      variant: SoftButtonVariant.outline,
                      onPressed: () => _toggleStatus(rider),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildApplications(AdminProvider admin) {
    if (admin.riderApplications.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
            child: Text('No pending rider applications.', style: TextStyle(color: AppColors.brandMuted)),
          ),
        ),
      ];
    }
    return admin.riderApplications.map((app) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: SoftCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_pin, color: AppColors.brandPrimary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${app['name'] ?? ''}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
                        Text('${app['phone'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.brandMuted)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SoftButton(
                title: 'Approve',
                variant: SoftButtonVariant.primary,
                onPressed: () => _approveApplication(app),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildPayouts(AdminProvider admin) {
    if (admin.payouts.isEmpty) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 40),
          child: Center(
            child: Text('No rider payouts yet.', style: TextStyle(color: AppColors.brandMuted)),
          ),
        ),
      ];
    }
    return admin.payouts.map((p) {
      final isSuccess = p.status == 'successful';
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SoftCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.riderName, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark)),
                    Text('K ${p.netCents / 100} net • ${p.createdAt}', style: const TextStyle(fontSize: 12, color: AppColors.brandMuted)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isSuccess ? Colors.green[100] : Colors.orange[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  p.status.toUpperCase(),
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isSuccess ? Colors.green : Colors.orange),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: AppColors.brandPrimary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.brandDark)),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
}