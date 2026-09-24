import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/widgets/product_image.dart';
import 'package:grand_elephants/widgets/soft_card.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  List<Map<String, dynamic>> _banners = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('/api/config', withAuth: false);
      if (!mounted) return;
      setState(() {
        _banners = ((res as Map<String, dynamic>)['banners'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _banners = [];
        _error = '$e'.replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Banners'),
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: AppColors.white,
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading && _banners.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const Text(
                    'Live Home Banners',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.brandDark),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Served to every shopper from the storefront carousel.',
                    style: TextStyle(color: AppColors.brandMuted),
                  ),
                  const SizedBox(height: 24),
                  if (_error != null) ...[
                    SoftCard(
                      child: Row(
                        children: [
                          const Icon(Icons.cloud_off, color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(color: AppColors.brandDark, fontSize: 13),
                            ),
                          ),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  ] else if (_banners.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No banners on the storefront right now',
                          style: TextStyle(color: AppColors.brandMuted),
                        ),
                      ),
                    )
                  else
                    ..._banners.map((banner) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SoftCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: SizedBox(
                                    width: 72,
                                    height: 72,
                                    child: ProductImage(
                                      src: '${banner['image'] ?? ''}',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${banner['title'] ?? ''}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, color: AppColors.brandDark),
                                      ),
                                      Text(
                                        '${banner['subtitle'] ?? ''}',
                                        style: const TextStyle(
                                            color: AppColors.brandMuted, fontSize: 13),
                                      ),
                                      if ('${banner['link'] ?? ''}'.isNotEmpty)
                                        Text(
                                          '${banner['link']}',
                                          style: const TextStyle(
                                              color: AppColors.brandPrimary, fontSize: 12),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
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
}
