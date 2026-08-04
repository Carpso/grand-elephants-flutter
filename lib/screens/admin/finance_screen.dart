import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/soft_input.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  final _baseFeeController = TextEditingController(text: '25.00');
  final _commissionController = TextEditingController(text: '15');
  final _minOrderController = TextEditingController(text: '100.00');

  @override
  void dispose() {
    _baseFeeController.dispose();
    _commissionController.dispose();
    _minOrderController.dispose();
    super.dispose();
  }

  void _handleSaveRates() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('New financial configurations have been applied globally.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    const transactions = [
      _FinanceTrx(id: 'TRX-9921', user: 'Alice', amount: 'K 1,200', type: 'Order', status: 'Completed', date: '10:30 AM'),
      _FinanceTrx(id: 'TRX-9922', user: 'Bob', amount: 'K 850', type: 'Order', status: 'Completed', date: '09:15 AM'),
      _FinanceTrx(id: 'TRX-9923', user: 'Rider Pay', amount: '-K 4,200', type: 'Payout', status: 'Processed', date: 'Yesterday'),
      _FinanceTrx(id: 'TRX-9924', user: 'Charlie', amount: 'K 3,100', type: 'Order', status: 'Refunded', date: 'Yesterday'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Finance & Rates')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                          label: 'Rider Commission (%)',
                          controller: _commissionController,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  SoftInput(
                    label: 'Min. Order Amount (K)',
                    controller: _minOrderController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  SoftButton(
                    title: 'Update Rates',
                    variant: SoftButtonVariant.primary,
                    icon: const Icon(Icons.save, size: 20, color: AppColors.brandDark),
                    onPressed: _handleSaveRates,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Transaction Log',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('View All', style: TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...transactions.map((trx) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SoftCard(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: trx.type == 'Payout' ? Colors.orange[100] : Colors.green[100],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                trx.type == 'Payout' ? Icons.payments : Icons.attach_money,
                                size: 20,
                                color: trx.type == 'Payout' ? const Color(0xFFF97316) : const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(trx.id, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark, fontSize: 13)),
                                Text('${trx.user} • ${trx.date}', style: const TextStyle(color: AppColors.brandMuted, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              trx.amount,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: trx.type == 'Payout' ? const Color(0xFFF97316) : AppColors.brandDark,
                              ),
                            ),
                            Text(
                              trx.status,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: trx.status == 'Refunded' ? AppColors.error : AppColors.brandMuted,
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
    );
  }
}

class _FinanceTrx {
  final String id;
  final String user;
  final String amount;
  final String type;
  final String status;
  final String date;

  const _FinanceTrx({
    required this.id,
    required this.user,
    required this.amount,
    required this.type,
    required this.status,
    required this.date,
  });
}
