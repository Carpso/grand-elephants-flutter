import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/services/tracking_service.dart';

class TrackingDetailScreen extends StatefulWidget {
  final String orderId;

  const TrackingDetailScreen({super.key, required this.orderId});

  @override
  State<TrackingDetailScreen> createState() => _TrackingDetailScreenState();
}

class _TrackingDetailScreenState extends State<TrackingDetailScreen> {
  List<TrackingStep> _history = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTracking();
  }

  Future<void> _loadTracking() async {
    final data = await TrackingService.getTrackingHistory(widget.orderId);
    if (!mounted) return;
    setState(() {
      _history = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order #${widget.orderId}'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Delivery Status',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.brandDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Estimated Delivery: Today, 2:00 PM',
            style: TextStyle(color: AppColors.brandMuted),
          ),
          const SizedBox(height: 32),
          if (_loading)
            const Center(
              child: CircularProgressIndicator(
                color: AppColors.brandPrimary,
              ),
            )
          else
            ...List.generate(_history.length, (index) {
              final step = _history[index];
              final isCompleted = step.completed;
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isCompleted ? AppColors.brandPrimary : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            step.status == 'Delivered' ? Icons.check : Icons.local_shipping,
                            size: 16,
                            color: isCompleted ? Colors.white : AppColors.brandMuted,
                          ),
                        ),
                        if (index < _history.length - 1)
                          Container(
                            width: 2,
                            height: 60,
                            color: isCompleted ? AppColors.brandPrimary : Colors.grey.shade200,
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              step.label,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isCompleted ? AppColors.brandDark : AppColors.brandMuted,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              step.description,
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.brandMuted,
                              ),
                            ),
                            if (step.location != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Current Location: ${step.location}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.brandPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                            const SizedBox(height: 4),
                            Text(
                              step.timestamp,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.brandMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
