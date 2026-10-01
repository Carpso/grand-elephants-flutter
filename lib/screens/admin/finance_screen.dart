import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/admin_provider.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _baseFeeController = TextEditingController(text: '25.00');
  final _perKmController = TextEditingController(text: '5.00');
  final _vatController = TextEditingController(text: '16');
  final _commissionController = TextEditingController(text: '1');
  final _platformMinController = TextEditingController(text: '3.00');
  final _cardPctController = TextEditingController(text: '2');
  final _cardMinController = TextEditingController(text: '5.00');
  final _payoutPctController = TextEditingController(text: '1');
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
      _loadSettings();
    });
  }

  Future<void> _load() async {
    final admin = context.read<AdminProvider>();
    await Future.wait([
      admin.loadStats(),
      admin.loadRiders(),
      admin.loadLipilaBalance(),
      admin.loadPayouts(),
    ]);
  }

  /// Pre-fills the fee inputs from GET /api/admin/settings (missing keys keep
  /// the defaults above).
  Future<void> _loadSettings() async {
    try {
      final res = await ApiClient.instance.get('/api/admin/settings');
      final map = Map<String, dynamic>.from(res as Map);
      String textOf(String key) {
        final v = map[key];
        return v == null ? '' : v.toString();
      }

      void setText(TextEditingController c, String v) {
        if (v.isNotEmpty) c.text = v;
      }

      void setKwacha(TextEditingController c, String centsRaw) {
        final cents = double.tryParse(centsRaw);
        if (cents != null) c.text = (cents / 100).toStringAsFixed(2);
      }

      setText(_vatController, textOf('vat_pct'));
      setText(_commissionController, textOf('platform_commission_pct'));
      setText(_cardPctController, textOf('platform_card_fee_pct'));
      setText(_payoutPctController, textOf('platform_payout_fee_pct'));
      setKwacha(_baseFeeController, textOf('delivery_base_fee_cents'));
      setKwacha(_perKmController, textOf('delivery_per_km_cents'));
      setKwacha(_platformMinController, textOf('platform_min_fee_cents'));
      setKwacha(_cardMinController, textOf('platform_card_min_fee_cents'));
    } catch (_) {
      // Keep the defaults when settings are unreachable.
    }
  }

  Future<void> _handleProcessPayout(AdminPayout payout) async {
    final messenger = ToastProvider.of(context);
    try {
      final res = await context.read<AdminProvider>().processPayout(payout.id);
      if (!mounted) return;
      final status = '${res['status'] ?? 'processing'}';
      final error = res['error']?.toString();
      if (status == 'successful') {
        messenger.show('Payout ${payout.id} settled successfully.', ToastType.success);
      } else if (status == 'failed') {
        messenger.show(
            (error != null && error.isNotEmpty) ? error : 'Payout ${payout.id} failed at Lipila',
            ToastType.error);
      } else {
        messenger.show('Payout ${payout.id} is still $status — try again later.', ToastType.info);
      }
    } catch (e) {
      if (!mounted) return;
      messenger.show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
    }
  }

  @override
  void dispose() {
    _baseFeeController.dispose();
    _perKmController.dispose();
    _vatController.dispose();
    _commissionController.dispose();
    _platformMinController.dispose();
    _cardPctController.dispose();
    _cardMinController.dispose();
    _payoutPctController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveRates() async {
    final baseFee = double.tryParse(_baseFeeController.text) ?? 0;
    final perKm = double.tryParse(_perKmController.text) ?? 0;
    final platformMin = double.tryParse(_platformMinController.text) ?? 0;
    final cardMin = double.tryParse(_cardMinController.text) ?? 0;
    setState(() => _saving = true);
    try {
      await ApiClient.instance.patch('/api/admin/settings', body: {
        'delivery_base_fee_cents': (baseFee * 100).round(),
        'delivery_per_km_cents': (perKm * 100).round(),
        'vat_pct': _vatController.text,
        'platform_commission_pct': _commissionController.text,
        'platform_min_fee_cents': (platformMin * 100).round(),
        'platform_card_fee_pct': _cardPctController.text,
        'platform_card_min_fee_cents': (cardMin * 100).round(),
        'platform_payout_fee_pct': _payoutPctController.text,
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

  String _formatCents(int cents) =>
      context.read<ConfigProvider>().formatPrice(cents / 100);

  @override
  Widget build(BuildContext context) {
    final admin = context.watch<AdminProvider>();
    final config = context.watch<ConfigProvider>();
    final stats = admin.stats;
    final payouts = admin.payouts;
    final businessPayouts = admin.businessPayouts;
    final lipilaBalance = admin.lipilaBalance ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Finance & Rates')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (admin.error != null) ...[
                SoftCard(
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          '${admin.error}'.replaceFirst('Exception: ', ''),
                          style: const TextStyle(color: AppColors.brandDark, fontSize: 12),
                        ),
                      ),
                      TextButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
                  Expanded(child: _buildStatTile(Icons.percent, _formatCents(stats.platformCommissionCents), 'PLATFORM FEES')),
                  const SizedBox(width: 8),
                  Expanded(child: _buildStatTile(Icons.pending_actions, '${stats.pendingPayouts}', 'PENDING PAYOUTS')),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildStatTile(
                        Icons.savings, config.formatPrice(lipilaBalance), 'LIPILA WALLET'),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatTile(
                        Icons.sync, '${businessPayouts.length}', 'BUSINESS PAYOUTS'),
                  ),
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
                            label: 'Platform Fee (%)',
                            controller: _commissionController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SoftInput(
                            label: 'Platform Min Fee (K)',
                            controller: _platformMinController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SoftInput(
                            label: 'Card Fee (%)',
                            controller: _cardPctController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: SoftInput(
                            label: 'Card Min Fee (K)',
                            controller: _cardMinController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SoftInput(
                            label: 'Payout Fee (%)',
                            controller: _payoutPctController,
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
                'Business Payouts',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
              ),
              const SizedBox(height: 8),
              if (businessPayouts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No business payouts yet.', style: TextStyle(color: AppColors.brandMuted)),
                  ),
                )
              else
                ...businessPayouts.map((p) => Padding(
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
                              child: const Icon(Icons.store, size: 20, color: AppColors.brandPrimary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.businessName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.brandDark,
                                        fontSize: 13),
                                  ),
                                  Text(
                                    '${p.network.toUpperCase()} ${p.phone} · ${p.createdAt}',
                                    style:
                                        const TextStyle(color: AppColors.brandMuted, fontSize: 12),
                                  ),
                                  Text(
                                    p.status.toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: p.status == 'successful'
                                          ? AppColors.success
                                          : p.status == 'failed'
                                              ? AppColors.error
                                              : AppColors.brandMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatCents(p.netCents),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, color: AppColors.brandDark),
                                ),
                                const SizedBox(height: 6),
                                if (p.status != 'successful')
                                  SoftButton(
                                    title: 'Check status',
                                    variant: SoftButtonVariant.primary,
                                    onPressed: () => _handleProcessPayout(p),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
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