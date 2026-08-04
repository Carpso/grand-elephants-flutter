import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class _TrackingStep {
  final String title;
  final String time;
  final String description;

  const _TrackingStep({
    required this.title,
    required this.time,
    required this.description,
  });
}

const _steps = [
  _TrackingStep(
    title: 'Order Placed',
    time: '10:23 AM',
    description: 'We have received your order.',
  ),
  _TrackingStep(
    title: 'Confirmed',
    time: '10:25 AM',
    description: 'Restaurant has confirmed your order.',
  ),
  _TrackingStep(
    title: 'Preparing',
    time: '10:30 AM',
    description: 'Your food is being prepared.',
  ),
  _TrackingStep(
    title: 'On the Way',
    time: '10:45 AM',
    description: 'Rider has picked up your order.',
  ),
  _TrackingStep(
    title: 'Delivered',
    time: '11:00 AM',
    description: 'Enjoy your meal!',
  ),
];

class OrderTrackingScreen extends StatefulWidget {
  const OrderTrackingScreen({super.key});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  int _status = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (_status < 4) {
        setState(() => _status++);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Order'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 100),
        children: [
          Container(
            height: 320,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mapWidth = constraints.maxWidth;
                final mapHeight = constraints.maxHeight;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _GridPainter(),
                      ),
                    ),
                    Positioned(
                      top: mapHeight * 0.3 - 64,
                      left: mapWidth * 0.4 - 64,
                      child: Container(
                        width: 128,
                        height: 128,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                      ).animate().scale(
                            begin: const Offset(0, 0),
                            duration: 1200.ms,
                            curve: Curves.easeOut,
                          ),
                    ),
                    Positioned(
                      top: mapHeight * 0.3 - 40,
                      left: mapWidth * 0.4 - 40,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                      ).animate().scale(
                            begin: const Offset(0, 0),
                            delay: 500.ms,
                            duration: 1200.ms,
                            curve: Curves.easeOut,
                          ),
                    ),
                    Center(
                      child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      size: 32,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Arriving in 15 mins',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.brandDark,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
          ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: SoftCard(
              margin: const EdgeInsets.only(bottom: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundImage: const NetworkImage('https://i.pravatar.cc/150?img=12'),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.brandPrimary, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'YOUR RIDER',
                              style: TextStyle(
                                color: AppColors.brandMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Alex Rider',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.brandDark,
                              ),
                            ),
                            Row(
                              children: [
                                const Icon(Icons.star, size: 16, color: Color(0xFFEAB308)),
                                const SizedBox(width: 4),
                                const Text(
                                  '4.9',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.brandDark,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '(124 deliveries)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.brandMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: const Text('Calling...'),
                            content: const Text('Connecting via Phone'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.phone, size: 24, color: Color(0xFF166534)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(height: 1),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Column(
                      children: List.generate(_steps.length, (index) {
                        final step = _steps[index];
                        final isActive = index == _status;
                        final isCompleted = index < _status;
                        final isPending = index > _status;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 32),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isActive
                                          ? AppColors.brandPrimary
                                          : isCompleted
                                              ? AppColors.success
                                              : Colors.grey.shade200,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.08),
                                          blurRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (index < _steps.length - 1)
                                    Container(
                                      width: 2,
                                      height: 40,
                                      color: Colors.grey.shade100,
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Opacity(
                                  opacity: isPending ? 0.5 : 1.0,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              step.title,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: isActive
                                                    ? AppColors.brandPrimary
                                                    : isCompleted
                                                        ? AppColors.brandDark
                                                        : AppColors.brandMuted,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              step.description,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: AppColors.brandMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          step.time,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.brandMuted,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(
                              delay: (index * 100).ms,
                              duration: 300.ms,
                            );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: SoftButton(
              title: 'Cancel Order',
              variant: SoftButtonVariant.ghost,
              onPressed: _status > 2
                  ? null
                  : () => showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Cancel Order'),
                          content: const Text('Are you sure? Cancellation fees may apply.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('No'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.1)
      ..strokeWidth = 1;
    for (var i = 0; i < 10; i++) {
      canvas.drawLine(
        Offset(i * size.width / 10, 0),
        Offset(i * size.width / 10, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(0, i * size.height / 10),
        Offset(size.width, i * size.height / 10),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
