import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/providers/config_provider.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_card.dart';
import 'package:sell_on_app/widgets/toast.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();
  final _imageController = TextEditingController(text: 'https://placehold.co/600x400/F59E0B/FFFFFF?text=New+Banner');

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _imageController.dispose();
    super.dispose();
  }

  void _handleCreate() {
    if (_titleController.text.isEmpty || _subtitleController.text.isEmpty) {
      ToastProvider.of(context).show('Please fill in Title and Subtitle', ToastType.error);
      return;
    }
    context.read<ConfigProvider>().addBanner({
      'title': _titleController.text,
      'subtitle': _subtitleController.text,
      'image': _imageController.text,
      'link': '/product/1',
    });
    _titleController.clear();
    _subtitleController.clear();
    ToastProvider.of(context).show('Banner added to Home Screen', ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigProvider>();
    final banners = config.homeBanners;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Banner Management'),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: AppColors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Home Screen Banners',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brandDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage the rotating carousel on the main page.',
              style: TextStyle(color: AppColors.brandMuted),
            ),
            const SizedBox(height: 24),
            SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add New Banner',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandPrimary),
                  ),
                  const SizedBox(height: 16),
                  const Text('Title', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brandSecondary)),
                  const SizedBox(height: 8),
                  _buildInputField(_titleController, 'e.g. Winter Sale'),
                  const SizedBox(height: 12),
                  const Text('Subtitle', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brandSecondary)),
                  const SizedBox(height: 8),
                  _buildInputField(_subtitleController, 'e.g. 50% Off Everything'),
                  const SizedBox(height: 12),
                  const Text('Image URL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.brandSecondary)),
                  const SizedBox(height: 8),
                  _buildInputField(_imageController, 'https://...'),
                  const SizedBox(height: 16),
                  const Text('PREVIEW', style: TextStyle(color: AppColors.brandMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
                      child: Stack(
                        children: [
                          Image.network(_imageController.text, width: double.infinity, height: 160, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200])),
                          Container(
                            color: Colors.black.withValues(alpha: 0.3),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _titleController.text.isEmpty ? 'Title' : _titleController.text,
                                    style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    _subtitleController.text.isEmpty ? 'Subtitle' : _subtitleController.text,
                                    style: const TextStyle(color: AppColors.white, fontSize: 16),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SoftButton(title: 'Add Banner', variant: SoftButtonVariant.primary, onPressed: _handleCreate),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Active Banners (${banners.length})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark),
            ),
            const SizedBox(height: 12),
            ...banners.map((banner) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: SoftCard(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            banner['image'] as String? ?? '',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 64, height: 64, color: Colors.grey[200]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(banner['title'] as String? ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark)),
                              Text(banner['subtitle'] as String? ?? '', style: const TextStyle(color: AppColors.brandMuted, fontSize: 13)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error, size: 20),
                          onPressed: () => config.removeBanner(banner['id'] as String),
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

  Widget _buildInputField(TextEditingController controller, String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: const TextStyle(color: AppColors.brandMuted)),
      ),
    );
  }
}
