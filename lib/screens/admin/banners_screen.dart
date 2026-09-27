import 'package:flutter/material.dart';
import 'package:grand_elephants/constants/app_theme.dart';
import 'package:grand_elephants/providers/catalog_provider.dart';
import 'package:grand_elephants/providers/config_provider.dart';
import 'package:grand_elephants/services/api_client.dart';
import 'package:grand_elephants/services/image_util.dart';
import 'package:grand_elephants/services/upload_service.dart';
import 'package:grand_elephants/widgets/product_image.dart';
import 'package:grand_elephants/widgets/soft_button.dart';
import 'package:grand_elephants/widgets/soft_card.dart';
import 'package:grand_elephants/widgets/soft_input.dart';
import 'package:grand_elephants/widgets/toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class BannersScreen extends StatefulWidget {
  const BannersScreen({super.key});

  @override
  State<BannersScreen> createState() => _BannersScreenState();
}

class _BannersScreenState extends State<BannersScreen> {
  List<Map<String, dynamic>> _banners = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  String _idOf(Map<String, dynamic> banner) {
    final id = banner['id'];
    if (id == null) return '';
    final value = id.toString().trim();
    return value == 'null' ? '' : value;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ApiClient.instance.get('/api/admin/banners');
      if (!mounted) return;
      setState(() {
        _banners = (res as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _banners = [];
        _error = '$e'
            .replaceFirst('Exception: ', '')
            .replaceFirst('ApiException: ', '');
        _loading = false;
      });
    }
  }

  /// Refetches the storefront caches so the home carousel reflects the
  /// banner that was just written.
  Future<void> _refreshConsumers() async {
    final config = context.read<ConfigProvider>();
    final catalog = context.read<CatalogProvider>();
    await config.reload();
    await catalog.load();
  }

  /// Add (null) or edit (banner prefilled) form in a bottom sheet; the list
  /// reloads from the server once the sheet reports a successful save.
  Future<void> _openEditor([Map<String, dynamic>? banner]) async {
    if (_saving) return;
    if (banner != null && _idOf(banner).isEmpty) {
      ToastProvider.of(context)
          .show('That banner has no id on the server yet', ToastType.error);
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BannerEditorSheet(banner: banner),
    );
    if (saved != true || !mounted) return;
    await _load();
    if (mounted) await _refreshConsumers();
  }

  Future<void> _confirmDelete(Map<String, dynamic> banner) async {
    if (_saving) return;
    final id = _idOf(banner);
    if (id.isEmpty) {
      ToastProvider.of(context)
          .show('That banner has no id on the server yet', ToastType.error);
      return;
    }
    final title = '${banner['title'] ?? ''}';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Banner'),
        content: Text(
          title.isEmpty
              ? 'Remove this banner from the storefront?'
              : 'Remove "$title" from the storefront?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await ApiClient.instance.delete('/api/admin/banners/$id');
      if (!mounted) return;
      ToastProvider.of(context).show('Banner deleted', ToastType.success);
      await _load();
      if (mounted) await _refreshConsumers();
    } catch (e) {
      if (mounted) {
        ToastProvider.of(context).show(
          '$e'.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''),
          ToastType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.brandDark,
        tooltip: 'Add banner',
        onPressed: _saving ? null : () => _openEditor(),
        child: const Icon(Icons.add),
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
                    'Served to every shopper from the storefront carousel. Tap a banner to edit it.',
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
                            onTap: () => _openEditor(banner),
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
                                      const SizedBox(height: 6),
                                      _StatusChip(
                                        active: banner['active'] is bool
                                            ? banner['active'] as bool
                                            : true,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          size: 20, color: AppColors.brandSecondary),
                                      tooltip: 'Edit banner',
                                      onPressed: _saving
                                          ? null
                                          : () => _openEditor(banner),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20, color: AppColors.error),
                                      tooltip: 'Delete banner',
                                      onPressed: _saving
                                          ? null
                                          : () => _confirmDelete(banner),
                                    ),
                                  ],
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

class _StatusChip extends StatelessWidget {
  final bool active;

  const _StatusChip({required this.active});

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.brandMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'LIVE' : 'PAUSED',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

/// Add/edit form used for both creating a banner (`POST /api/admin/banners`)
/// and updating one (`PUT /api/admin/banners/:id`). Pops with `true` after a
/// successful save so the caller can refetch the list.
class _BannerEditorSheet extends StatefulWidget {
  final Map<String, dynamic>? banner;

  const _BannerEditorSheet({this.banner});

  @override
  State<_BannerEditorSheet> createState() => _BannerEditorSheetState();
}

class _BannerEditorSheetState extends State<_BannerEditorSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _subtitleCtrl;
  late final TextEditingController _linkCtrl;
  late bool _active;
  String? _image;
  bool _picking = false;
  bool _saving = false;

  bool get _isEdit => widget.banner != null;

  @override
  void initState() {
    super.initState();
    final banner = widget.banner;
    _titleCtrl = TextEditingController(text: '${banner?['title'] ?? ''}');
    _subtitleCtrl = TextEditingController(text: '${banner?['subtitle'] ?? ''}');
    _linkCtrl = TextEditingController(text: '${banner?['link'] ?? ''}');
    final active = banner?['active'];
    _active = active is bool ? active : true;
    final image = '${banner?['image'] ?? ''}';
    _image = image.isEmpty ? null : image;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _linkCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 75,
      );
      if (picked == null) return;
      final dataUri = await imageToDataUri(picked, maxDimension: 1200, quality: 75);
      if (dataUri == null) {
        if (!mounted) return;
        ToastProvider.of(context)
            .show('Could not read that image, pick another one', ToastType.error);
        return;
      }
      final image = await UploadService.uploadOrFallback(
        dataUri,
        folder: UploadFolder.banners,
      );
      if (!mounted) return;
      setState(() => _image = image);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      ToastProvider.of(context).show('A banner title is required', ToastType.error);
      return;
    }
    if ((_image ?? '').isEmpty) {
      ToastProvider.of(context).show('Pick a banner image first', ToastType.error);
      return;
    }

    setState(() => _saving = true);
    final body = <String, dynamic>{
      'title': title,
      'subtitle': _subtitleCtrl.text.trim(),
      'link': _linkCtrl.text.trim(),
      'active': _active,
      'image': _image,
    };
    try {
      if (_isEdit) {
        final id = '${widget.banner?['id'] ?? ''}';
        if (id.isEmpty || id == 'null') {
          throw const ApiException('This banner has no id on the server');
        }
        await ApiClient.instance.put('/api/admin/banners/$id', body: body);
      } else {
        await ApiClient.instance.post('/api/admin/banners', body: body);
      }
      if (!mounted) return;
      ToastProvider.of(context).show(
        _isEdit ? 'Banner updated' : 'Banner created',
        ToastType.success,
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ToastProvider.of(context).show(
        '$e'.replaceFirst('Exception: ', '').replaceFirst('ApiException: ', ''),
        ToastType.error,
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: 24 + viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.brandMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _isEdit ? 'Edit Banner' : 'New Banner',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.brandDark,
              ),
            ),
            const SizedBox(height: 16),
            SoftInput(
              label: 'Title',
              hint: 'e.g. New Season Drop',
              controller: _titleCtrl,
            ),
            SoftInput(
              label: 'Subtitle',
              hint: 'Small supporting line',
              controller: _subtitleCtrl,
            ),
            SoftInput(
              label: 'Link',
              hint: 'e.g. /explore',
              controller: _linkCtrl,
            ),
            _buildImagePicker(),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Active',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandDark,
                ),
              ),
              subtitle: const Text(
                'Shown on the home carousel',
                style: TextStyle(fontSize: 12, color: AppColors.brandMuted),
              ),
              value: _active,
              onChanged: (value) => setState(() => _active = value),
            ),
            SizedBox(
              width: double.infinity,
              child: SoftButton(
                title: _saving
                    ? 'Saving...'
                    : (_isEdit ? 'Save Changes' : 'Create Banner'),
                variant: SoftButtonVariant.primary,
                isLoading: _saving,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'Image',
              style: TextStyle(
                color: AppColors.brandSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          GestureDetector(
            onTap: _picking ? null : _pickImage,
            child: Container(
              height: 150,
              width: double.infinity,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.softSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
              ),
              child: _picking
                  ? const Center(child: CircularProgressIndicator())
                  : _image != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            ProductImage(src: _image!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt,
                                    size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_a_photo,
                                  size: 28, color: AppColors.brandPrimary),
                              SizedBox(height: 8),
                              Text(
                                'Tap to choose an image',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.brandMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}
