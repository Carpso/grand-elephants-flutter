import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class EmployeePortalScreen extends StatelessWidget {
  const EmployeePortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final shifts = [
      {
        'day': 'Today',
        'time': '09:00 AM - 05:00 PM',
        'role': 'Store Manager',
      },
      {
        'day': 'Tomorrow',
        'time': '09:00 AM - 05:00 PM',
        'role': 'Store Manager',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employee Portal'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello,',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                Text(
                  'Alice Smith',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ],
            ),
          ),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Pay Date',
                  style: TextStyle(
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Dec 25, 2025',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: AppColors.white.withValues(alpha: 0.2)),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Est. Net Pay', style: TextStyle(color: AppColors.white)),
                    Text(
                      '\$2,100.00',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Upcoming Shifts',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 16),
          ...shifts.map((shift) => SoftCard(
                margin: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shift['day'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.brandDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          shift['time'] as String,
                          style: const TextStyle(color: AppColors.brandMuted),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.softSurface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        shift['role'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
