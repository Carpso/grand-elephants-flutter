import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class BusinessHomeScreen extends StatelessWidget {
  const BusinessHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Suite'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Finance Overview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SoftCard(
                  child: Column(
                    children: [
                      const Text(
                        'Total Sales',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brandMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'K 45,200',
                        style: TextStyle(
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
                    children: [
                      const Text(
                        'Orders',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.brandMuted,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '128',
                        style: TextStyle(
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Payouts',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Today at 10:30 AM - K 1,200 (Completed)',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.brandMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
