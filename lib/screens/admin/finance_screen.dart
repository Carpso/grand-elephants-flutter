import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/admin_provider.dart';
import 'package:sell_on_app/services/api_client.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/soft_input.dart';
import 'package:sell_on_app/widgets/toast.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _baseFeeController = TextEditingController(text: '25.00');
  final _perKmController = TextEditingController(text: '5.00');
  final _vatController = TextEditingController(text: '16');
  final _commissionController = TextEditingController(text: '15');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final admin = context.read<AdminProvider>();
      admin.loadStats();
      admin.loadRiders();
    });
  }

  @override
  void dispose() {
    _baseFeeController.dispose();
    _perKmController.dispose();
    _vatController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveRates() async {
    final baseFee = double.tryParse(_baseFeeController.text) ?? 0;
    final perKm = double.tryParse(_perKmController.text) ?? 0;
    setState(() => _saving = true);
    try {
      await ApiClient.instance.patch('/api/admin/settings', body: {
        'delivery_base_fee_cents': (baseFee * 100).round(),
        'delivery_per_km_cents': (perKm * 100).round(),
        'vat_pct': _vatController.text,
        'platform_commission_pct': _commissionController.text,
      });
      if (mounted) {
        ToastProvider.of(context).show('New financial configurations have been applied globally.', ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatCents(int cents) {
    final amount = cents / 100;
    final parts = amount.toStringAsFixed(2).split('.');
    final buf = StringBuffer();
    for (var i = 0; i < parts[0].length; i++) {
      if (i > 0 && (parts[0].length - i) % 3 == 0) buf.write(',');
      buf.write(parts[0][i]);
    }
    return 'K ${buf.toString()}.${parts[1]}';
  }

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final stats = admin.stats;
    final payouts = admin.payouts;

    return Scaffold(
      appBar: AppBar(title: const Text('Finance & Rates')),
      body: RefreshIndicator(
        onRefresh: () async {
          await admin.loadStats();
          await admin.loadRiders();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildStatTile(Icons.trending_up, _formatCents(stats.gmvCents), 'GMV')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatTile(Icons.account_balance_wallet, _formatCents(stats.businessWalletCents), 'BUSINESS WALLET')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildStatTile(Icons.percent, _formatCents(stats.platformCommissionCents), 'PLATFORM COMMISSION')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatTile(Icons.pending_actions, '${stats.pendingPayouts}', 'PENDING PAYOUTS')),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                'Configuration',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
              ),
              const SizedBox(height: 16),
              SoftCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SoftInput(
                            label: 'Base Delivery Fee (K)',
                            controller: _baseFeeController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SoftInput(
                            label: 'Delivery per Km (K)',
                            controller: _perKmController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SoftInput(
                            label: 'VAT (%)',
                            controller: _vatController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SoftInput(
                            label: 'Platform Commission (%)',
                            controller: _commissionController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SoftButton(
                      title: _saving ? 'Updating...' : 'Update Rates',
                      variant: SoftButtonVariant.primary,
                      isLoading: _saving,
                      icon: const Icon(Icons.save, size: 20, color: AppColors.brandDark),
                      onPressed: _saving ? null : _handleSaveRates,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Rider Payouts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
              ),
              const SizedBox(height: 8),
              if (payouts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No payouts yet.', style: TextStyle(color: AppColors.brandMuted)),
                  ),
                )
              else
                ...payouts.map((p) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SoftCard(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.orange[100],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.payments, size: 20, color: Color(0xFFF97316)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.riderName.isNotEmpty ? p.riderName : p.businessName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark, fontSize: 13),
                                  ),
                                  Text(
                                    p.createdAt,
                                    style: const TextStyle(color: AppColors.brandMuted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatCents(p.netCents),
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFF97316)),
                                ),
                                Text(
                                  p.status.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: p.status == 'successful' ? AppColors.success : AppColors.brandMuted,
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

  Widget _buildStatTile(IconData icon, String value, String label) {
    return SoftCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.brandPrimary),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.brandDark)),
          Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ],
      ),
    );
  }
}