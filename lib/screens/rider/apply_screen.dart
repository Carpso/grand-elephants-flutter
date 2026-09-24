import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/auth_provider.dart';
import 'package:grand_elephants/services/image_util.dart';
import 'package:grand_elephants/widgets/product_image.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';

class ApplyScreen extends StatefulWidget {
  const ApplyScreen({super.key});

  @override
  State<ApplyScreen> createState() => _ApplyScreenState();
}

class _ApplyScreenState extends State<ApplyScreen> {
  final _vehicleTypeCtrl = TextEditingController();
  final _plateNumberCtrl = TextEditingController();
  final _licenseNumberCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String? _bikePhoto;

  @override
  void dispose() {
    _vehicleTypeCtrl.dispose();
    _plateNumberCtrl.dispose();
    _licenseNumberCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 900,
      imageQuality: 70,
    );
    if (file == null) return;
    final dataUri = await imageToDataUri(file, maxDimension: 900, quality: 70);
    if (dataUri == null) {
      if (!mounted) return;
      ToastProvider.of(context)
          .show('Could not read that image, pick another one', ToastType.error);
      return;
    }
    setState(() => _bikePhoto = dataUri);
  }

  Future<void> _handleSubmit() async {
    if (_vehicleTypeCtrl.text.isEmpty ||
        _plateNumberCtrl.text.isEmpty ||
        _licenseNumberCtrl.text.isEmpty ||
        _bikePhoto == null) {
      ToastProvider.of(context).show('Please fill in ALL details including Plate Number and Bike Photo', ToastType.error);
      return;
    }
    try {
      await context.read<AuthProvider>().requestRiderAccess({
        'vehicleType': _vehicleTypeCtrl.text,
        'plateNumber': _plateNumberCtrl.text,
        'licenseNumber': _licenseNumberCtrl.text,
        'phone': _phoneCtrl.text,
        'bikePhoto': _bikePhoto,
      });
      if (!mounted) return;
      ToastProvider.of(context)
          .show('Rider application submitted', ToastType.success);
      Navigator.of(context).maybePop();
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show(
        '$e'.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''),
        ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.riderStatus == 'pending') {
      return Scaffold(
        backgroundColor: AppColors.softSurface,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: SoftCard(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade50,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '⏳',
                        style: TextStyle(fontSize: 36),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Application Pending',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.brandDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your application is being reviewed by our Admin team. You will be notified once approved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.brandMuted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SoftButton(
                    title: 'Back to Profile',
                    variant: SoftButtonVariant.outline,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.softSurface,
      appBar: AppBar(
        title: const Text('Become a Rider'),
        backgroundColor: AppColors.softSurface,
        foregroundColor: AppColors.brandDark,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.brandMuted,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Join the Fleet',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brandDark,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Earn money by delivering premium fashion to our customers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.brandMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          SoftCard(
            child: Column(
              children: [
                SoftInput(
                  label: 'Vehicle Type',
                  hint: 'e.g. Yamaha Motorbike',
                  controller: _vehicleTypeCtrl,
                ),
                SoftInput(
                  label: 'Plate Number',
                  hint: 'ABC 1234',
                  controller: _plateNumberCtrl,
                ),
                SoftInput(
                  label: "Driver's License",
                  hint: 'DL-12345678',
                  controller: _licenseNumberCtrl,
                ),
                SoftInput(
                  label: 'Phone Number',
                  hint: '+260 9...',
                  keyboardType: TextInputType.phone,
                  controller: _phoneCtrl,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Vehicle Photo',
              style: TextStyle(
                color: AppColors.brandSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              height: 192,
              decoration: BoxDecoration(
                color: AppColors.softSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.brandMuted.withValues(alpha: 0.3),
                  width: 2,
                  style: BorderStyle.solid,
                ),
              ),
              child: _bikePhoto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: ProductImage(
                        src: _bikePhoto!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.add_a_photo,
                            color: AppColors.brandMuted,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap to upload photo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandMuted,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 32),
          SoftButton(
            title: 'Submit Application',
            variant: SoftButtonVariant.primary,
            onPressed: _handleSubmit,
          ),
        ],
      ),
    );
  }
}
