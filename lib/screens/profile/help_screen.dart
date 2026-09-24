import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/toast.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<_Faq> _faqs = [
    _Faq(
      question: 'How do I track my order?',
      answer: 'Go to Profile > My Orders to see real-time status.',
    ),
    _Faq(
      question: 'What payment methods do you accept?',
      answer: 'We accept MTN Mobile Money, Airtel Money, and Visa/Mastercard.',
    ),
    _Faq(
      question: 'Can I return an item?',
      answer: 'Yes, within 7 days of delivery if the item is unused.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softSurface,
      appBar: AppBar(
        title: const Text('Help & Support'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FAQ',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 24),
            ..._faqs.map((faq) => SoftCard(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(
                          Icons.help_outline,
                          size: 20,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              faq.question,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              faq.answer,
                              style: const TextStyle(
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  const Text(
                    'Still need help?',
                    style: TextStyle(
                      color: AppColors.brandMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pushNamed('/support/chat'),
                    child: SoftCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.chat, size: 24, color: AppColors.brandDark),
                          SizedBox(width: 12),
                          Text(
                            'Start Live Chat',
                            style: TextStyle(
                              color: AppColors.brandDark,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(const ClipboardData(text: 'support@grandelephants.com'));
                      ToastProvider.of(context).show('Support email copied', ToastType.success);
                    },
                    child: Text(
                      'support@grandelephants.com',
                      style: TextStyle(
                        color: AppColors.brandPrimary.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.brandPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Faq {
  final String question;
  final String answer;

  const _Faq({required this.question, required this.answer});
}
