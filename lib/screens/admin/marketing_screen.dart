import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  String _activeTab = 'flyer';
  final _headlineController = TextEditingController(text: 'New Arrivals!');
  final _discountController = TextEditingController(text: '20% OFF');

  @override
  void dispose() {
    _headlineController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appName = context.watch<ConfigProvider>().appName;

    const scheduledPosts = [
      _ScheduledPost(id: 1, date: 'Today, 2:00 PM', platform: 'Instagram', status: 'ready', title: 'Summer Sale Launch'),
      _ScheduledPost(id: 2, date: 'Tomorrow, 10:00 AM', platform: 'Facebook', status: 'draft', title: 'New Shoe Collection'),
      _ScheduledPost(id: 3, date: 'Fri, 12 Oct', platform: 'TikTok', status: 'scheduled', title: 'Viral Video - Behind Scenes'),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Marketing Suite')),
      body: Column(
        children: [
          Container(
            color: AppColors.white,
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 'flyer'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTab == 'flyer' ? AppColors.brandPrimary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Flyer Generator',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _activeTab == 'flyer' ? AppColors.brandDark : AppColors.brandMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 'planner'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _activeTab == 'planner' ? AppColors.brandPrimary : Colors.transparent,
                            width: 2,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Social Planner',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _activeTab == 'planner' ? AppColors.brandDark : AppColors.brandMuted,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _activeTab == 'flyer' ? _buildFlyerView(appName) : _buildPlannerView(scheduledPosts),
          ),
        ],
      ),
    );
  }

  Widget _buildFlyerView(String appName) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Live Preview', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark)),
          const SizedBox(height: 16),
          AspectRatio(
            aspectRatio: 4 / 5,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.brandDark,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.white, width: 4),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _headlineController.text,
                              style: const TextStyle(color: AppColors.brandPrimary, fontWeight: FontWeight.bold, fontSize: 32),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              appName,
                              style: const TextStyle(color: AppColors.white, fontSize: 18),
                            ),
                          ],
                        ),
                        Transform.rotate(
                          angle: -0.035,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  _discountController.text,
                                  style: const TextStyle(color: AppColors.brandDark, fontSize: 28, fontWeight: FontWeight.bold),
                                ),
                                const Text(
                                  'LIMITED TIME OFFER',
                                  style: TextStyle(color: AppColors.brandMuted, fontSize: 10, letterSpacing: 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Headline', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _headlineController,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Discount / Promo', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _discountController,
                    decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SoftButton(
            title: 'Instant Download Flyer',
            variant: SoftButtonVariant.primary,
            icon: const Text('\u2B07', style: TextStyle(color: AppColors.white, fontSize: 20)),
            onPressed: () {
              ToastProvider.of(context).show('Exporting High-Res PDF...', ToastType.info);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlannerView(List<_ScheduledPost> posts) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Content Calendar',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brandDark),
              ),
              FloatingActionButton.small(
                onPressed: () {
                  ToastProvider.of(context).show('Opening Composer...', ToastType.info);
                },
                backgroundColor: AppColors.brandPrimary,
                child: const Icon(Icons.add, color: AppColors.white, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('THIS WEEK', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandMuted, fontSize: 10, letterSpacing: 1)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].asMap().entries.map((entry) {
                    final i = entry.key;
                    final d = entry.value;
                    return Container(
                      width: 32,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: i == 2 ? AppColors.brandPrimary.withValues(alpha: 0.2) : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            d,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: i == 2 ? AppColors.brandDark : AppColors.brandMuted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: i == 2 || i == 4 ? AppColors.brandPrimary : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('SCHEDULED POSTS', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandMuted, fontSize: 10, letterSpacing: 1)),
          const SizedBox(height: 12),
          ...posts.map((post) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SoftCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: post.platform == 'Instagram'
                              ? Colors.pink[100]
                              : post.platform == 'Facebook'
                                  ? Colors.blue[100]
                                  : Colors.black,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          post.platform == 'Instagram'
                              ? Icons.camera_alt
                              : post.platform == 'Facebook'
                                  ? Icons.facebook
                                  : Icons.music_note,
                          size: 24,
                          color: post.platform == 'TikTok'
                              ? AppColors.white
                              : post.platform == 'Instagram'
                                  ? const Color(0xFFC13584)
                                  : const Color(0xFF1877F2),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark)),
                            Text(post.date, style: const TextStyle(color: AppColors.brandMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: post.status == 'ready'
                              ? Colors.green[100]
                              : post.status == 'scheduled'
                                  ? Colors.blue[100]
                                  : Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          post.status,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: post.status == 'ready'
                                ? Colors.green[700]
                                : post.status == 'scheduled'
                                    ? Colors.blue[700]
                                    : AppColors.brandMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _ScheduledPost {
  final int id;
  final String date;
  final String platform;
  final String status;
  final String title;

  const _ScheduledPost({
    required this.id,
    required this.date,
    required this.platform,
    required this.status,
    required this.title,
  });
}
