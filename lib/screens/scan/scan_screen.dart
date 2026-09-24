import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/toast.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  CameraController? _controller;
  bool _initializing = true;
  bool _cameraReady = false;
  bool _navigating = false;
  final TextEditingController _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    _manualController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      controller.resumePreview();
    } else if (state == AppLifecycleState.paused) {
      controller.pausePreview();
    }
  }

  Future<void> _initCamera() async {
    if (mounted) {
      setState(() {
        _initializing = true;
        _cameraReady = false;
      });
    }
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) setState(() => _initializing = false);
        return;
      }
      final controller = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() {
        _initializing = false;
        _cameraReady = true;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _initializing = false;
          _cameraReady = false;
        });
      }
    }
  }

  void _handleScan() {
    final raw = _manualController.text.trim();
    final match = RegExp(r'\d+').firstMatch(raw);
    final id = match?.group(0);
    if (id == null || id.isEmpty) {
      ToastProvider.of(context)
          .show('Enter or scan a product ID containing digits', ToastType.error);
      return;
    }
    if (_navigating) return;
    _navigating = true;
    ToastProvider.of(context).show('Product $id found', ToastType.success);
    Navigator.of(context).pushNamed('/product/$id');
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _navigating = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Product'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _buildCameraArea()),
          _buildScanFrame(),
          Positioned(
            left: 24,
            right: 24,
            bottom: 32,
            child: _buildManualEntry(),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: GestureDetector(
              onTap: _initCamera,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.refresh, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraArea() {
    if (_initializing) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      );
    }
    if (_cameraReady && _controller != null) {
      return Center(child: CameraPreview(_controller!));
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.no_photography_outlined,
            size: 64,
            color: Colors.white.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Camera unavailable on this device',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Use manual entry below to find a product.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildScanFrame() {
    return Center(
      child: Container(
        width: 256,
        height: 256,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
          borderRadius: BorderRadius.circular(24),
          color: Colors.black.withValues(alpha: 0.1),
        ),
        child: const Center(
          child: Text(
            'Align Code Here',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  Widget _buildManualEntry() {
    return SoftCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ENTER PRODUCT ID',
            style: TextStyle(
              color: AppColors.brandPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.softSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2, color: AppColors.brandSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _manualController,
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _handleScan(),
                    decoration: const InputDecoration(
                      hintText: 'e.g. 12345',
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SoftButton(
              title: 'Find Product',
              variant: SoftButtonVariant.primary,
              icon: const Icon(Icons.search, size: 20, color: Colors.black),
              onPressed: _handleScan,
            ),
          ),
        ],
      ),
    );
  }
}
