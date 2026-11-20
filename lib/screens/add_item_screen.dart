import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../services/swapit_supabase_service.dart';
import '../theme/app_colors.dart';

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  static const List<String> _conditions = <String>[
    'New',
    'Like New',
    'Good',
    'Fair',
  ];

  static const int _maxPhotos = 3;
  static const int _maxPhotoBytes = 5 * 1024 * 1024;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();

  String _kind = 'have';
  String _condition = 'Good';
  final List<_PickedPhoto> _selectedPhotos = <_PickedPhoto>[];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    super.dispose();
  }

  String _cleanError(Object e) {
    final String raw = e.toString();
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : null,
      ),
    );
  }

  Future<void> _pickPhoto() async {
    if (_isSubmitting) return;
    if (_selectedPhotos.length >= _maxPhotos) {
      _showSnack('You can add up to $_maxPhotos photos.');
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();
      if (!mounted) return;

      if (bytes.lengthInBytes > _maxPhotoBytes) {
        _showSnack('Each photo must be 5 MB or smaller.', isError: true);
        return;
      }

      setState(() {
        _selectedPhotos.add(
          _PickedPhoto(
            bytes: bytes,
            fileName: picked.name.isEmpty ? 'photo.jpg' : picked.name,
          ),
        );
      });
    } catch (e) {
      _showSnack('Could not pick photo: ${_cleanError(e)}', isError: true);
    }
  }

  void _removePhoto(int index) {
    if (_isSubmitting) return;
    setState(() => _selectedPhotos.removeAt(index));
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final num? price =
        num.tryParse(_priceController.text.replaceAll(',', '').trim());
    if (price == null || price < 0) {
      _showSnack('Please enter a valid price in EGP.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final List<String> uploadedUrls = <String>[];

    try {
      for (final _PickedPhoto photo in _selectedPhotos) {
        final String url = await SwapitSupabaseService.uploadItemImage(
          bytes: photo.bytes,
          fileName: photo.fileName,
        );
        uploadedUrls.add(url);
      }

      await SwapitSupabaseService.insertItem(
        kind: _kind,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        condition: _condition,
        estimatedPriceEgp: price,
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
        imageUrls: uploadedUrls,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (uploadedUrls.isNotEmpty) {
        await SwapitSupabaseService.removeItemImages(uploadedUrls);
      }
      if (!mounted) return;
      _showSnack(_cleanError(e), isError: true);
      setState(() => _isSubmitting = false);
    }
  }

  Widget _kindSelector() {
    return Row(
      children: <Widget>[
        Expanded(
          child: ChoiceChip(
            label: const Center(child: Text('Offer')),
            selected: _kind == 'have',
            onSelected: _isSubmitting
                ? null
                : (bool selected) {
                    if (selected) setState(() => _kind = 'have');
                  },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ChoiceChip(
            label: const Center(child: Text('Need')),
            selected: _kind == 'want',
            onSelected: _isSubmitting
                ? null
                : (bool selected) {
                    if (selected) setState(() => _kind = 'want');
                  },
          ),
        ),
      ],
    );
  }

  Widget _photosSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Photos (${_selectedPhotos.length}/$_maxPhotos)',
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Optional. Up to 3 photos, 5 MB each.',
          style: TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: <Widget>[
            for (int i = 0; i < _selectedPhotos.length; i++)
              Stack(
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _selectedPhotos[i].bytes,
                      width: 84,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () => _removePhoto(i),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            if (_selectedPhotos.length < _maxPhotos)
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: AppColors.softBox,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(
                    Icons.add_a_photo_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Add Item',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _kindSelector(),
              const SizedBox(height: 16),
              _photosSection(),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                enabled: !_isSubmitting,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (String? v) => (v == null || v.trim().length < 3)
                    ? 'Please enter at least 3 characters.'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                enabled: !_isSubmitting,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (String? v) => (v == null || v.trim().isEmpty)
                    ? 'Please enter a description.'
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: const InputDecoration(
                  labelText: 'Condition',
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: _conditions
                    .map(
                      (String c) => DropdownMenuItem<String>(
                        value: c,
                        child: Text(c),
                      ),
                    )
                    .toList(),
                onChanged: _isSubmitting
                    ? null
                    : (String? v) {
                        if (v != null) setState(() => _condition = v);
                      },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                enabled: !_isSubmitting,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Estimated price (EGP)',
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (String? v) {
                  final num? p =
                      num.tryParse((v ?? '').replaceAll(',', '').trim());
                  if (p == null) return 'Enter a valid number.';
                  if (p < 0) return 'Price cannot be negative.';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextFormField(
                      controller: _cityController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      validator: (String? v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _districtController,
                      enabled: !_isSubmitting,
                      decoration: const InputDecoration(
                        labelText: 'District',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add Item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PickedPhoto {
  const _PickedPhoto({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}