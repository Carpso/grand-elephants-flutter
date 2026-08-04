import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class SalesScreen extends StatelessWidget {
  const SalesScreen({super.key});

  static const List<_Transaction> _transactions = [
    _Transaction(id: '1', item: 'Royal Elephant Tote', amount: 'K 1,200', date: 'Today, 10:23 AM'),
    _Transaction(id: '2', item: 'Travel Duffle', amount: 'K 2,500', date: 'Yesterday, 4:15 PM'),
    _Transaction(id: '3', item: 'Leather Belt', amount: 'K 450', date: 'Yesterday, 2:30 PM'),
    _Transaction(id: '4', item: 'Canvas Messenger', amount: 'K 850', date: 'Yesterday, 11:15 AM'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sales Report')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1F2937), Color(0xFF111827)]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8)),
                ],
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'TOTAL REVENUE (DEC)',
                    style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w500, fontSize: 10, letterSpacing: 1),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'K 45,250.00',
                    style: TextStyle(color: AppColors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          '\u25B2 12.5%',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'vs last month',
                        style: TextStyle(color: AppColors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Recent Transactions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.brandDark),
            ),
            const SizedBox(height: 16),
            ..._transactions.map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SoftCard(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t.item, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark)),
                              const SizedBox(height: 4),
                              Text(t.date, style: const TextStyle(color: AppColors.brandMuted, fontSize: 12, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                        Text(t.amount, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandPrimary)),
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

class _Transaction {
  final String id;
  final String item;
  final String amount;
  final String date;

  const _Transaction({
    required this.id,
    required this.item,
    required this.amount,
    required this.date,
  });
}
