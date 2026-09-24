import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/services/export_image.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/toast.dart';

class MarketingScreen extends StatefulWidget {
  const MarketingScreen({super.key});

  @override
  State<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends State<MarketingScreen> {
  final _flyerKey = GlobalKey();
  final _headlineController = TextEditingController(text: 'New Arrivals!');
  final _discountController = TextEditingController(text: '20% OFF');
  bool _exporting = false;

  @override
  void dispose() {
    _headlineController.dispose();
    _discountController.dispose();
    super.dispose();
  }

  Future<void> _downloadFlyer() async {
    final messenger = ToastProvider.of(context);
    final renderObject = _flyerKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      messenger.show('Flyer preview is not ready yet', ToastType.error);
      return;
    }
    setState(() => _exporting = true);
    try {
      final image = await renderObject.toImage(pixelRatio: 3);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) throw Exception('Could not render the flyer');
      final name =
          'grand-elephants-flyer-${DateTime.now().millisecondsSinceEpoch}.png';
      final saved = await exportImage(byteData.buffer.asUint8List(), name);
      if (!mounted) return;
      messenger.show('Flyer saved to $saved', ToastType.success);
    } catch (e) {
      if (!mounted) return;
      messenger.show('$e'.replaceFirst('Exception: ', ''), ToastType.error);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appName = context.watch<ConfigProvider>().appName;

    return Scaffold(
      appBar: AppBar(title: const Text('Marketing Suite')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Preview',
                style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.brandDark)),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 4 / 5,
              child: RepaintBoundary(
                key: _flyerKey,
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
                                  style: const TextStyle(
                                      color: AppColors.brandPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 32),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  appName,
                                  style:
                                      const TextStyle(color: AppColors.white, fontSize: 18),
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
                                      style: const TextStyle(
                                          color: AppColors.brandDark,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    const Text(
                                      'LIMITED TIME OFFER',
                                      style: TextStyle(
                                          color: AppColors.brandMuted,
                                          fontSize: 10,
                                          letterSpacing: 2),
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
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Discount / Promo',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _discountController,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SoftButton(
              title: _exporting ? 'Exporting...' : 'Download Flyer (PNG)',
              variant: SoftButtonVariant.primary,
              isLoading: _exporting,
              onPressed: _exporting ? null : _downloadFlyer,
            ),
          ],
        ),
      ),
    );
  }
}
