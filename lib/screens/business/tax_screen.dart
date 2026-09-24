import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';

enum _Period { thisMonth, lastMonth, custom }

/// Shop VAT/tax centre backed by the real business tax endpoints:
/// `GET /api/businesses/me/tax` and `/tax/payments`.
class TaxScreen extends StatefulWidget {
  const TaxScreen({super.key});

  @override
  State<TaxScreen> createState() => _TaxScreenState();
}

class _TaxScreenState extends State<TaxScreen> {
  bool _loading = true;
  bool _loadingPayments = true;
  String? _error;
  String? _paymentsError;

  Map<String, dynamic> _summary = const {};
  List<Map<String, dynamic>> _bySale = const [];
  List<Map<String, dynamic>> _payments = const [];

  _Period _period = _Period.thisMonth;
  DateTime? _customFrom;
  DateTime? _customTo;

  static String _iso(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  ({DateTime from, DateTime to}) get _range {
    final now = DateTime.now();
    switch (_period) {
      case _Period.lastMonth:
        final first = DateTime(now.year, now.month - 1, 1);
        final last = DateTime(now.year, now.month, 0);
        return (from: first, to: last);
      case _Period.custom:
        if (_customFrom != null && _customTo != null) {
          return (from: _customFrom!, to: _customTo!);
        }
        return (from: DateTime(now.year, now.month, 1), to: now);
      case _Period.thisMonth:
        return (from: DateTime(now.year, now.month, 1), to: now);
    }
  }

  @override
  void initState() {
    super.initState();
    _load(showErrors: true);
  }

  Future<void> _load({bool showErrors = false}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final range = _range;
    try {
      final res = await ApiClient.instance
          .get('/api/businesses/me/tax?from=${_iso(range.from)}&to=${_iso(range.to)}');
      final data = Map<String, dynamic>.from(res as Map);
      _summary = data;
      _bySale = (data['vatBySale'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      final message =
          '$e'.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
      _error = message;
      if (showErrors && mounted) {
        ToastProvider.of(context).show(message, ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    await _loadPayments(showErrors: showErrors);
  }

  Future<void> _loadPayments({bool showErrors = false}) async {
    setState(() {
      _loadingPayments = true;
      _paymentsError = null;
    });
    try {
      final res = await ApiClient.instance.get('/api/businesses/me/tax/payments');
      _payments = (res as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      final message =
          '$e'.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', '');
      _paymentsError = message;
      if (showErrors && mounted) {
        ToastProvider.of(context).show(message, ToastType.error);
      }
    } finally {
      if (mounted) setState(() => _loadingPayments = false);
    }
  }

  /// Cents → kwacha, tolerant of the payload delivering a string.
  double _cents(Object? value) {
    if (value is num) return value.toDouble() / 100;
    final parsed = double.tryParse(
        '${value ?? ''}'.replaceAll(RegExp(r'[^0-9.-]'), ''));
    return (parsed ?? 0) / 100;
  }

  int _count(Object? value) {
    if (value is num) return value.round();
    return int.tryParse('${value ?? ''}'.trim()) ?? 0;
  }

  /// Payments may report either cents or an already-formatted amount.
  double _paymentAmount(Map<String, dynamic> payment) {
    final cents = payment['amountCents'];
    if (cents is num && cents > 0) return cents / 100;
    final raw = payment['amount'];
    if (raw is num) return raw.toDouble();
    final parsed = double.tryParse(
        '${raw ?? ''}'.replaceAll(RegExp(r'[^0-9.]'), ''));
    return parsed ?? 0;
  }

  String _shortDate(String raw) {
    if (raw.isEmpty) return '—';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${parsed.day} ${months[parsed.month - 1]} ${parsed.year}';
  }

  String _errorText(Object e) => '$e'
      .replaceFirst('Exception: ', '')
      .replaceFirst('ApiException: ', '');

  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final first = await showDatePicker(
      context: context,
      initialDate: _customFrom ?? DateTime(now.year, now.month, 1),
      firstDate: DateTime(now.year - 3),
      lastDate: now,
    );
    if (first == null || !mounted) return;
    final last = await showDatePicker(
      context: context,
      initialDate: _customTo ?? now,
      firstDate: first,
      lastDate: now,
    );
    if (last == null || !mounted) return;
    setState(() {
      _customFrom = first;
      _customTo = last;
      _period = _Period.custom;
    });
    await _load(showErrors: true);
  }

  Future<void> _selectPeriod(_Period period) async {
    if (period == _Period.custom) {
      await _pickCustomRange();
      return;
    }
    if (_period == period) return;
    setState(() => _period = period);
    await _load(showErrors: true);
  }

  /// Dialog to record a VAT payment against ZRA.
  Future<void> _recordPayment() async {
    final config = context.read<ConfigProvider>();
    final amountController = TextEditingController();
    final referenceController = TextEditingController();
    DateTime? periodStart;
    DateTime? periodEnd;
    String? method;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final range = _range;
          periodStart ??= range.from;
          periodEnd ??= range.to;
          return AlertDialog(
            title: const Text(
              'Record Tax Payment',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SoftInput(
                    label: 'Amount (K)',
                    hint: 'e.g. 1500.00',
                    controller: amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                  ),
                  Text(
                    'Period start',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: periodStart!,
                        firstDate: DateTime(DateTime.now().year - 3),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => periodStart = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.softSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Text(
                        _iso(periodStart!),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Period end',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: ctx,
                        initialDate: periodEnd!,
                        firstDate: periodStart!,
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setDialogState(() => periodEnd = picked);
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 14),
                      decoration: BoxDecoration(
                        color: AppColors.softSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white),
                      ),
                      child: Text(
                        _iso(periodEnd!),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandDark,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Method',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final option in const [
                        ('mobile_money', 'Mobile Money'),
                        ('bank', 'Bank Transfer'),
                        ('cash', 'Cash'),
                        ('card', 'Card'),
                      ])
                        GestureDetector(
                          onTap: () =>
                              setDialogState(() => method = option.$1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: method == option.$1
                                  ? AppColors.brandPrimary
                                  : AppColors.softSurface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: method == option.$1
                                    ? AppColors.brandPrimary
                                    : Colors.white,
                              ),
                            ),
                            child: Text(
                              option.$2,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: method == option.$1
                                    ? AppColors.brandDark
                                    : AppColors.brandSecondary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SoftInput(
                    label: 'Reference (optional)',
                    hint: 'e.g. ZRA-2026-000123',
                    controller: referenceController,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Record Payment'),
              ),
            ],
          );
        },
      ),
    );

    if (submitted != true || !mounted) {
      amountController.dispose();
      referenceController.dispose();
      return;
    }

    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      amountController.dispose();
      referenceController.dispose();
      ToastProvider.of(context).show('Enter a valid amount', ToastType.error);
      return;
    }
    if (periodStart == null || periodEnd == null) {
      amountController.dispose();
      referenceController.dispose();
      ToastProvider.of(context)
          .show('Pick the tax period', ToastType.error);
      return;
    }

    try {
      await ApiClient.instance.post('/api/businesses/me/tax/payments', body: {
        'amountCents': (amount * 100).round(),
        'periodStart': _iso(periodStart!),
        'periodEnd': _iso(periodEnd!),
        if (referenceController.text.trim().isNotEmpty)
          'reference': referenceController.text.trim(),
        if (method != null) 'method': method,
      });
      if (!mounted) return;
      ToastProvider.of(context).show(
        'Tax payment of ${config.formatPrice(amount)} recorded',
        ToastType.success,
      );
      await _loadPayments(showErrors: true);
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show(_errorText(e), ToastType.error);
    } finally {
      amountController.dispose();
      referenceController.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final rawVatPct = _summary['vatPct'];
    final vatPct = rawVatPct is num
        ? rawVatPct.toDouble()
        : (double.tryParse('${rawVatPct ?? ''}') ?? config.taxRate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Taxes'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => _load(showErrors: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(showErrors: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            if (_loading)
              const Padding(
                padding: EdgeInsets.only(top: 64),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppColors.brandPrimary,
                  ),
                ),
              )
            else if (_error != null) ...[
              SoftCard(
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off,
                        size: 48, color: AppColors.brandMuted),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.brandMuted),
                    ),
                    const SizedBox(height: 12),
                    SoftButton(
                      title: 'Retry',
                      variant: SoftButtonVariant.secondary,
                      onPressed: () => _load(showErrors: true),
                    ),
                  ],
                ),
              ),
            ] else ...[
              _buildPeriodSelector(),
              const SizedBox(height: 20),
              _buildSummary(config, vatPct),
              const SizedBox(height: 24),
              _buildBySale(config),
              const SizedBox(height: 24),
              _buildPayments(config),
              const SizedBox(height: 16),
              Text(
                'Calculated automatically from your paid orders. '
                'ZRA Smart Invoice submission coming soon.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    Widget pill(String label, _Period period) {
      final selected = _period == period;
      return GestureDetector(
        onTap: () => _selectPeriod(period),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? AppColors.brandPrimary : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? AppColors.brandPrimary
                  : Colors.white.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color:
                  selected ? AppColors.brandDark : AppColors.brandSecondary,
            ),
          ),
        ),
      );
    }

    final range = _range;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'REPORTING PERIOD',
          style: TextStyle(
            color: AppColors.brandMuted,
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            pill('This Month', _Period.thisMonth),
            pill('Last Month', _Period.lastMonth),
            pill('Custom', _Period.custom),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${_iso(range.from)} → ${_iso(range.to)}',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.brandSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSummary(ConfigProvider config, double vatPct) {
    Widget stat(String label, String value, {Color? color}) => Expanded(
          child: SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                    color: AppColors.brandMuted,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color ?? AppColors.brandDark,
                  ),
                ),
              ],
            ),
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VAT Summary',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.brandDark,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            stat('VAT COLLECTED',
                config.formatPrice(_cents(_summary['vatCollectedCents'])),
                color: AppColors.brandPrimary),
            const SizedBox(width: 16),
            stat('TAXABLE SALES',
                config.formatPrice(_cents(_summary['taxableSalesCents']))),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            stat('SALES COUNT', '${_count(_summary['salesCount'])}'),
            const SizedBox(width: 16),
            stat('VAT RATE', '${vatPct.toStringAsFixed(0)}%'),
          ],
        ),
      ],
    );
  }

  Widget _buildBySale(ConfigProvider config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'VAT By Sale',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.brandDark,
          ),
        ),
        const SizedBox(height: 12),
        if (_bySale.isEmpty)
          SoftCard(
            child: Column(
              children: [
                const Icon(Icons.receipt_long,
                    size: 40, color: AppColors.brandMuted),
                const SizedBox(height: 8),
                Text(
                  'No taxable sales in this period.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          )
        else
          ..._bySale.map(
            (sale) => SoftCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${sale['invoiceNo'] ?? '—'}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _shortDate('${sale['date'] ?? ''}'),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.brandMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total ${config.formatPrice(_cents(sale['totalCents']))}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandSecondary,
                        ),
                      ),
                      Text(
                        'VAT ${config.formatPrice(_cents(sale['vatCents']))}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Buyer TPIN: ${('${sale['tpin'] ?? ''}'.trim()).isEmpty ? '—' : sale['tpin']}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.brandMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPayments(ConfigProvider config) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Payments',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            SoftButton(
              title: 'Record Tax Payment',
              variant: SoftButtonVariant.primary,
              onPressed: _recordPayment,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_loadingPayments)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(color: AppColors.brandPrimary),
            ),
          )
        else if (_paymentsError != null)
          SoftCard(
            child: Column(
              children: [
                Text(
                  _paymentsError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.brandMuted),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => _loadPayments(showErrors: true),
                  child: const Text('Retry',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          )
        else if (_payments.isEmpty)
          SoftCard(
            child: Text(
              'No tax payments recorded yet.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          )
        else
          ..._payments.map(
            (payment) => SoftCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        config.formatPrice(_paymentAmount(payment)),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.brandDark,
                        ),
                      ),
                      Text(
                        '${payment['method'] ?? '—'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.brandMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Period ${_shortDate('${payment['periodStart'] ?? ''}')} → '
                    '${_shortDate('${payment['periodEnd'] ?? ''}')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.brandSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Ref: ${('${payment['reference'] ?? ''}'.trim()).isEmpty ? '—' : payment['reference']}'
                    ' · Recorded ${_shortDate('${payment['createdAt'] ?? ''}')}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.brandMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
