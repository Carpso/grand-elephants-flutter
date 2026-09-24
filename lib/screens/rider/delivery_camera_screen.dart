import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/providers/rider_provider.dart';
import 'package:grand_elephants/services/image_util.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/toast.dart';

class DeliveryCameraScreen extends StatefulWidget {
  final String? orderId;

  const DeliveryCameraScreen({super.key, this.orderId});

  @override
  State<DeliveryCameraScreen> createState() => _DeliveryCameraScreenState();
}

class _DeliveryCameraScreenState extends State<DeliveryCameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  File? _photo;
  bool _isCameraReady = false;
  bool _hasPermission = false;
  bool _submitting = false;

  String get _orderId {
    if (widget.orderId != null && widget.orderId!.isNotEmpty) {
      return widget.orderId!;
    }
    return ModalRoute.of(context)?.settings.arguments as String? ?? '';
  }

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
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (state == AppLifecycleState.resumed) {
      _controller?.resumePreview();
    } else if (state == AppLifecycleState.paused) {
      _controller?.dispose();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _hasPermission = false);
        return;
      }
      final controller = CameraController(cameras.first, ResolutionPreset.medium);
      _controller = controller;
      try {
        await controller.initialize();
        if (!mounted) return;
        setState(() {
          _isCameraReady = true;
          _hasPermission = true;
        });
      } catch (e) {
        setState(() => _hasPermission = false);
      }
    } catch (_) {
      setState(() => _hasPermission = false);
    }
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final photo = await _controller!.takePicture();
      setState(() => _photo = File(photo.path));
    } catch (_) {}
  }

  Future<void> _confirmDelivery() async {
    if (_submitting) return;
    final orderId = _orderId;
    if (orderId.isEmpty) {
      ToastProvider.of(context)
          .show('No order selected for this delivery', ToastType.error);
      return;
    }
    if (_photo == null) {
      ToastProvider.of(context)
          .show('Take a proof of delivery photo first', ToastType.error);
      return;
    }

    setState(() => _submitting = true);
    final rider = context.read<RiderProvider>();
    try {
      final proof = await imageToDataUri(_photo, maxDimension: 900, quality: 70);
      if (proof == null) {
        if (!mounted) return;
        ToastProvider.of(context)
            .show('Could not read that photo, take it again', ToastType.error);
        return;
      }
      await rider.updateOrderStatus(orderId, 'Delivered', proofPhoto: proof);
      if (!mounted) return;
      ToastProvider.of(context)
          .show('Order $orderId marked as Delivered!', ToastType.success);
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show(
        '$e'.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''),
        ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (_photo != null)
            _buildPhotoPreview()
          else if (!_hasPermission)
            _buildPermissionDenied()
          else if (!_isCameraReady)
            const Center(child: CircularProgressIndicator())
          else
            _buildCameraPreview(),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionDenied() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Camera access needed for Proof of Delivery.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SoftButton(
            title: 'Grant Permission',
            variant: SoftButtonVariant.primary,
            onPressed: _initCamera,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview() {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        ClipRect(
          child: OverflowBox(
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.fitWidth,
              child: SizedBox(
                width: size.width,
                height: size.width * _controller!.value.aspectRatio,
                child: CameraPreview(_controller!),
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                _orderId.isNotEmpty
                    ? 'Capture Proof of Delivery • #$_orderId'
                    : 'Capture Proof of Delivery',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _takePicture,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Container(
                  margin: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoPreview() {
    return Stack(
      children: [
        Image.file(
          _photo!,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 60,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent],
              ),
            ),
            child: Text(
              _orderId.isNotEmpty ? 'Confirm Delivery • #$_orderId' : 'Confirm Delivery',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 48,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () => setState(() => _photo = null),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.refresh, size: 32, color: Colors.white),
                ),
              ),
              GestureDetector(
                onTap: _submitting ? null : _confirmDelivery,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _submitting ? Colors.grey : Colors.green,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: 0.5),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : const Icon(Icons.check, size: 40, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}