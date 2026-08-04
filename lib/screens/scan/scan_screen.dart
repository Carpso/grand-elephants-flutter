import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_card.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _scanned = false;
  bool _permissionGranted = false;
  bool _permissionUnknown = true;

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    // Simulate camera permission request
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    // In a real app, use permission_handler package
    // For now, simulate granted
    setState(() {
      _permissionUnknown = false;
      _permissionGranted = true;
    });
  }

  void _handleBarCodeScanned(Map<String, dynamic> result) {
    if (_scanned) return;
    setState(() => _scanned = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Bar code with type ${result['type']} and data ${result['data']} has been scanned!',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _scanned = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_permissionUnknown) {
      return const Scaffold(
        backgroundColor: AppColors.brandDark,
        body: Center(),
      );
    }

    if (!_permissionGranted) {
      return Scaffold(
        backgroundColor: AppColors.brandDark,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'We need your permission to show the camera',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 24),
                SoftCard(
                  onTap: _requestPermission,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    child: const Text(
                      'Grant Permission',
                      style: TextStyle(
                        color: AppColors.brandDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Product'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          // Simulated camera view
          Container(
            color: Colors.black,
            child: Center(
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: const Color(0xFF1A1A1A),
                child: Stack(
                  children: [
                    // Scan area overlay
                    Center(
                      child: Container(
                        width: 256,
                        height: 256,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          color: Colors.black.withValues(alpha: 0.1),
                        ),
                        child: GestureDetector(
                          onTap: () => _handleBarCodeScanned({
                            'type': 'qr',
                            'data': 'product_12345',
                          }),
                          child: const Center(
                            child: Text(
                              'Align Code Here',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 100,
            child: SoftCard(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'Scan a tag to order or view details',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF374151),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
