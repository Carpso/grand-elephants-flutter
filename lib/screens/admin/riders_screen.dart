import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/services/storage_service.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/soft_input.dart';
import 'package:sell_on_app/widgets/toast.dart';

class Rider {
  final String id;
  final String name;
  final String phone;
  final String vehicle;
  final String status;
  final double balance;
  final String joined;

  const Rider({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicle,
    required this.status,
    required this.balance,
    required this.joined,
  });

  Rider copyWith({
    String? id,
    String? name,
    String? phone,
    String? vehicle,
    String? status,
    double? balance,
    String? joined,
  }) =>
      Rider(
        id: id ?? this.id,
        name: name ?? this.name,
        phone: phone ?? this.phone,
        vehicle: vehicle ?? this.vehicle,
        status: status ?? this.status,
        balance: balance ?? this.balance,
        joined: joined ?? this.joined,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'phone': phone,
        'vehicle': vehicle,
        'status': status,
        'balance': balance,
        'joined': joined,
      };

  factory Rider.fromJson(Map<String, dynamic> json) => Rider(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        vehicle: json['vehicle'] as String,
        status: json['status'] as String,
        balance: (json['balance'] as num).toDouble(),
        joined: json['joined'] as String,
      );
}

class RidersScreen extends StatefulWidget {
  const RidersScreen({super.key});

  @override
  State<RidersScreen> createState() => _RidersScreenState();
}

class _RidersScreenState extends State<RidersScreen> {
  List<Rider> _riders = [];
  bool _modalVisible = false;
  bool _refreshing = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRiders();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _vehicleController.dispose();
    super.dispose();
  }

  Future<void> _loadRiders() async {
    final stored = await StorageService.get<List<dynamic>>('admin_riders_list');
    if (stored != null) {
      setState(() => _riders = stored.map((e) => Rider.fromJson(e as Map<String, dynamic>)).toList());
    } else {
      const seeds = [
        Rider(id: '1', name: 'Alex Johnson', phone: '0977000001', vehicle: 'Yamaha Bike (Black)', status: 'Active', balance: 450, joined: '2025-01-10'),
        Rider(id: '2', name: 'Peter Banda', phone: '0966000002', vehicle: 'Honda Ace', status: 'Active', balance: 1200, joined: '2025-02-14'),
      ];
      setState(() => _riders = seeds);
      await StorageService.save('admin_riders_list', seeds.map((e) => e.toJson()).toList());
    }
    setState(() => _refreshing = false);
  }

  Future<void> _handleRecruit() async {
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty || _vehicleController.text.isEmpty) {
      ToastProvider.of(context).show('Please fill in all rider details.', ToastType.error);
      return;
    }

    final newRider = Rider(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text,
      phone: _phoneController.text,
      vehicle: _vehicleController.text,
      status: 'Active',
      balance: 0,
      joined: DateTime.now().toIso8601String().split('T')[0],
    );

    final updatedList = [newRider, ..._riders];
    setState(() => _riders = updatedList);
    await StorageService.save('admin_riders_list', updatedList.map((e) => e.toJson()).toList());

    setState(() => _modalVisible = false);
    _nameController.clear();
    _phoneController.clear();
    _vehicleController.clear();
    if (mounted) {
      ToastProvider.of(context).show('Rider recruited successfully!', ToastType.success);
    }
  }

  void _handlePayout(Rider rider) {
    if (rider.balance <= 0) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Payout'),
        content: Text('Pay K ${rider.balance} to ${rider.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final updatedList = _riders.map((r) => r.id == rider.id ? r.copyWith(balance: 0) : r).toList();
              setState(() => _riders = updatedList);
              await StorageService.save('admin_riders_list', updatedList.map((e) => e.toJson()).toList());
              Navigator.pop(ctx);
              if (mounted) {
                ToastProvider.of(context).show('Payout to ${rider.name} processed.', ToastType.success);
              }
            },
            child: const Text('Confirm Pay'),
          ),
        ],
      ),
    );
  }

  void _handleRemove(String riderId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Rider'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              final updatedList = _riders.where((r) => r.id != riderId).toList();
              setState(() => _riders = updatedList);
              await StorageService.save('admin_riders_list', updatedList.map((e) => e.toJson()).toList());
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  double get _totalPayouts => _riders.fold(0.0, (sum, r) => sum + r.balance);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Management'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SoftButton(
              title: 'Add Rider',
              variant: SoftButtonVariant.ghost,
              icon: const Icon(Icons.person_add, size: 20),
              onPressed: () => setState(() => _modalVisible = true),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _refreshing = true);
          await _loadRiders();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.people, size: 20, color: AppColors.brandMuted),
                              const SizedBox(width: 8),
                              Text(
                                'TOTAL FLEET',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${_riders.length}',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SoftCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.payments, size: 20, color: Color(0xFFCA8A04)),
                              const SizedBox(width: 8),
                              Text(
                                'PENDING PAYOUTS',
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'K $_totalPayouts',
                            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.brandPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Text(
                  'Recruited Riders',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
                ),
              ),
              const SizedBox(height: 16),
              if (_riders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Text('No riders recruited yet.', style: TextStyle(color: AppColors.brandMuted, fontStyle: FontStyle.italic)),
                  ),
                ),
              ..._riders.map((rider) => Padding(
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
                                child: Text(rider.name[0], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.brandMuted)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(rider.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
                                    Text(rider.vehicle, style: const TextStyle(fontSize: 12, color: AppColors.brandMuted)),
                                    Text(rider.phone, style: const TextStyle(fontSize: 12, color: AppColors.brandMuted)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.green[100], borderRadius: BorderRadius.circular(6)),
                                child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
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
                                Text('K ${rider.balance}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.brandDark)),
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
                              SizedBox(
                                width: 80,
                                child: SoftButton(
                                  title: 'Remove',
                                  variant: SoftButtonVariant.ghost,
                                  onPressed: () => _handleRemove(rider.id),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
