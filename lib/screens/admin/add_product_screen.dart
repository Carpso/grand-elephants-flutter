import 'package:flutter/material.dart';
import 'package:sell_on_app/constants/app_theme.dart';
import 'package:sell_on_app/widgets/soft_button.dart';
import 'package:sell_on_app/widgets/soft_input.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> with SingleTickerProviderStateMixin {
  String? _image;
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _loading = false;
  bool _isGhostMode = true;
  bool _isProcessing = false;
  String _processingStep = '';
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
    _spinAnimation = Tween<double>(begin: 0, end: 1).animate(_spinController);
  }

  @override
  void dispose() {
    _spinController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _pickImage() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Capture Product'),
        content: const Text('Choose how you want to add the product image.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startGhostProcessing('assets/products/product_placeholder.png');
            },
            child: const Text('Take Photo'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startGhostProcessing('assets/products/product_placeholder.png');
            },
            child: const Text('Choose from Gallery'),
          ),
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        ],
      ),
    );
  }

  void _startGhostProcessing(String uri) {
    if (!_isGhostMode) {
      setState(() => _image = uri);
      return;
    }

    setState(() {
      _isProcessing = true;
      _processingStep = 'Analyzing Image...';
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) setState(() => _processingStep = 'Removing Background...');
    });
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _processingStep = 'Removing Mannequin...');
    });
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _processingStep = 'Reconstructing Internal Fabric...');
    });
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _processingStep = '';
          _image = uri;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ghost Mannequin Applied - The image has been processed.')),
        );
      }
    });
  }

  void _handleCreate() {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _categoryController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields and upload an image.')),
      );
      return;
    }

    setState(() => _loading = true);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product added successfully to inventory.')),
        );
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Product'),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.brandSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Center(
              child: SizedBox(
                width: 280,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 350,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(40),
                          border: Border.all(color: AppColors.white, width: 4),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          children: [
                            if (_image != null)
                              Image.asset(_image!, width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey[200]))
                            else
                              const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo, size: 32, color: AppColors.brandPrimary),
                                    SizedBox(height: 16),
                                    Text('Capture Raw Image', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.brandDark)),
                                    SizedBox(height: 8),
                                    Text('GHOST MANNEQUIN READY', style: TextStyle(color: AppColors.brandMuted, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                                  ],
                                ),
                              ),
                            if (_image != null && _isGhostMode && !_isProcessing)
                              Positioned(
                                top: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.brandPrimary.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.auto_fix_high, size: 14, color: AppColors.brandDark),
                                      SizedBox(width: 4),
                                      Text('GHOST AI', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: AppColors.brandDark, letterSpacing: 1)),
                                    ],
                                  ),
                                ),
                              ),
                            if (_isProcessing)
                              Container(
                                color: Colors.black.withValues(alpha: 0.8),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      RotationTransition(
                                        turns: _spinAnimation,
                                        child: const Icon(Icons.autorenew, size: 48, color: AppColors.brandPrimary),
                                      ),
                                      const SizedBox(height: 16),
                                      Text(_processingStep, style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w900, fontSize: 14)),
                                      const SizedBox(height: 16),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: const LinearProgressIndicator(
                                            backgroundColor: Color(0x33FFFFFF),
                                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.brandPrimary),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_image != null && !_isProcessing)
                      Positioned(
                        top: -8,
                        right: -8,
                        child: GestureDetector(
                          onTap: () => setState(() => _image = null),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 16, color: AppColors.error),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Ghost mannequin toggle
            GestureDetector(
              onTap: () => setState(() => _isGhostMode = !_isGhostMode),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _isGhostMode ? AppColors.brandPrimary.withValues(alpha: 0.1) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isGhostMode ? AppColors.brandPrimary : Colors.grey[200]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isGhostMode ? AppColors.brandPrimary : Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.auto_fix_high,
                        size: 24,
                        color: _isGhostMode ? AppColors.brandDark : AppColors.brandMuted,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ghost Mannequin Mode',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: _isGhostMode ? AppColors.brandDark : AppColors.brandMuted,
                            ),
                          ),
                          Text(
                            _isGhostMode ? 'AI will remove background & mannequin' : 'Disabled - using raw image',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.brandMuted, letterSpacing: 1),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 48,
                      height: 24,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: _isGhostMode ? AppColors.brandPrimary : Colors.grey[300],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedAlign(
                        duration: const Duration(milliseconds: 200),
                        alignment: _isGhostMode ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: const BoxDecoration(
                            color: AppColors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Product Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.brandDark),
              ),
            ),
            const SizedBox(height: 16),
            SoftInput(
              hint: 'Product Name',
              controller: _nameController,
              icon: const Icon(Icons.label, size: 20, color: AppColors.brandMuted),
            ),
            Row(
              children: [
                Expanded(
                  child: SoftInput(
                    hint: 'Price (K)',
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    icon: const Icon(Icons.attach_money, size: 20, color: AppColors.brandMuted),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SoftInput(
                    hint: 'Category',
                    controller: _categoryController,
                    icon: const Icon(Icons.category, size: 20, color: AppColors.brandMuted),
                  ),
                ),
              ],
            ),
            SoftInput(
              hint: 'Description',
              controller: _descriptionController,
              maxLines: 4,
              icon: const Icon(Icons.description, size: 20, color: AppColors.brandMuted),
            ),
            const SizedBox(height: 16),
            SoftButton(
              title: _loading ? 'Publishing...' : 'Publish Product',
              variant: SoftButtonVariant.primary,
              icon: _loading ? null : const Icon(Icons.check, size: 20, color: AppColors.brandDark),
              onPressed: _loading ? null : _handleCreate,
            ),
          ],
        ),
      ),
    );
  }
}
