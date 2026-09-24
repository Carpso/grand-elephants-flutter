import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/models/cart_item.dart';
import 'package:grand_elephants/providers/auth_provider.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/price_tag.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/toast.dart';

class BusinessDashboardScreen extends StatefulWidget {
  const BusinessDashboardScreen({super.key});

  @override
  State<BusinessDashboardScreen> createState() =>
      _BusinessDashboardScreenState();
}

class _BusinessDashboardScreenState extends State<BusinessDashboardScreen> {
  bool _loading = true;
  Map<String, dynamic> _business = const {};
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait([
        ApiClient.instance.get('/api/businesses/me'),
        ApiClient.instance.get('/api/businesses/me/orders'),
      ]);
      final data = results[0] as Map<String, dynamic>;
      _business = (data['business'] as Map<String, dynamic>?) ?? data;
      _orders = (results[1] as List)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Business dashboard load failed: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  double get _sales => _orders.fold(0.0, (sum, o) => sum + o.total);
  double get _balance => ((_business['balanceCents'] as num?)?.toInt() ?? 0) / 100;
  double get _held => ((_business['heldCents'] as num?)?.toInt() ?? 0) / 100;
  String get _businessName => (_business['name'] as String?) ?? '';
  List<dynamic> get _collectionNumbers =>
      (_business['collectionNumbers'] as List?) ?? const [];

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .toList();
    return parts.isEmpty ? '?' : parts.map((p) => p[0].toUpperCase()).join();
  }

  void _showReport() {
    final config = context.read<ConfigProvider>();
    final summary = StringBuffer()
      ..writeln('BUSINESS REPORT')
      ..writeln('Generated: ${DateTime.now().toLocal()}')
      ..writeln('------------------------------')
      ..writeln('Business: ${_businessName.isEmpty ? 'Your Business' : _businessName}')
      ..writeln('Total Orders: ${_orders.length}')
      ..writeln('Total Sales: ${config.formatPrice(_sales)}')
      ..writeln('Wallet Balance: ${config.formatPrice(_balance)}')
      ..writeln('On Hold: ${config.formatPrice(_held)}')
      ..writeln('Collection Numbers: ${_collectionNumbers.length}');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Shareable Summary'),
        content: SingleChildScrollView(
          child: SelectableText(
            summary.toString(),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Column(
        children: [
          _buildHeader(context, config, auth),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                const SizedBox(height: 32),
                const Text(
                  'Financial Overview',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL SALES',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: AppColors.brandMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.brandPrimary,
                                    ),
                                  )
                                : PriceTag(
                                    amount: _sales,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.brandDark,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SoftCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ON HOLD',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                                color: AppColors.brandMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _loading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.brandPrimary,
                                    ),
                                  )
                                : PriceTag(
                                    amount: _held,
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.brandDark,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SoftCard(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'WALLET BALANCE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.brandPrimary,
                                  ),
                                )
                              : PriceTag(
                                  amount: _balance,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          size: 32,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Weekly Performance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 16),
                _buildChart(),
                const SizedBox(height: 24),
                SoftButton(
                  title: 'Generate Full Report',
                  variant: SoftButtonVariant.outline,
                  onPressed: _loading ? null : _showReport,
                ),
                const SizedBox(height: 8),
                SoftButton(
                  title: 'Refresh',
                  variant: SoftButtonVariant.secondary,
                  onPressed: () async {
                    setState(() => _loading = true);
                    await _load();
                    if (!context.mounted) return;
                    ToastProvider.of(context)
                        .show('Dashboard refreshed', ToastType.success);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, ConfigProvider config, AuthProvider auth) {
    final name = auth.user?.name ?? 'Partner';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1F2937), Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 48, 24, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BUSINESS SUITE',
                      style: TextStyle(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Hello, $name',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'Manage your empire.',
                      style: TextStyle(
                        color: AppColors.brandMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _initials(name),
                    style: const TextStyle(
                      color: AppColors.brandDark,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: SoftCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.trending_up,
                          size: 24,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'EXCHANGE RATE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                              color: AppColors.brandMuted,
                            ),
                          ),
                          Text(
                            '1 USD = ${(1 / config.exchangeRate).toStringAsFixed(2)} ZMW',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'FIXED',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    final counts = List<double>.filled(7, 0);
    var parsed = 0;
    for (final order in _orders) {
      final dt = DateTime.tryParse(order.date);
      if (dt == null) continue;
      parsed++;
      final weekday = dt.weekday - 1;
      if (weekday >= 0 && weekday < 7) counts[weekday] += 1;
    }

    if (parsed == 0) {
      return SoftCard(
        child: SizedBox(
          height: 180,
          child: Center(
            child: Text(
              _loading ? 'Loading chart...' : 'No order data to chart yet.',
              style: const TextStyle(color: AppColors.brandMuted),
            ),
          ),
        ),
      );
    }

    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final maxCount = counts.fold<double>(1, (m, v) => v > m ? v : m);

    return SoftCard(
      child: SizedBox(
        height: 180,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(counts.length, (i) {
            final height = counts[i] / maxCount * 140;
            return SizedBox(
              width: 32,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    height: height < 6 && counts[i] > 0 ? 6 : height,
                    decoration: BoxDecoration(
                      color: AppColors.brandSecondary.withValues(alpha: 0.3),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    labels[i],
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandMuted,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}