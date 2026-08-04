import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/models/business_collection_number.dart';
import 'package:sell_on_app/providers/collection_number_provider.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class AdminCollectionNumbersScreen extends StatefulWidget {
  const AdminCollectionNumbersScreen({super.key});

  @override
  State<AdminCollectionNumbersScreen> createState() =>
      _AdminCollectionNumbersScreenState();
}

class _AdminCollectionNumbersScreenState
    extends State<AdminCollectionNumbersScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Collection Numbers'),
      ),
      body: Consumer<CollectionNumberProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.numbers.isEmpty) {
            return const Center(
              child: Text(
                'No collection numbers configured by superadmin',
                style: TextStyle(color: AppColors.brandMuted),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Text(
                  'Business Collection Numbers',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
              ),
              ...provider.numbers.map((number) =>
                  _buildNumberCard(context, provider, number)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildNumberCard(BuildContext context,
      CollectionNumberProvider provider, BusinessCollectionNumber number) {
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _networkColor(number.network).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.phone_android,
                  color: _networkColor(number.network),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      number.businessName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.brandDark,
                      ),
                    ),
                    Text(
                      '${number.network.displayName} • ${number.phoneNumber}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.brandMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (number.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.brandPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: number.isActive
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              number.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: number.isActive ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _networkColor(MobileMoneyNetwork network) {
    switch (network) {
      case MobileMoneyNetwork.mtn:
        return const Color(0xFFFFCC00);
      case MobileMoneyNetwork.airtel:
        return const Color(0xFFE30613);
      case MobileMoneyNetwork.zamtel:
        return const Color(0xFF00A651);
    }
  }
}