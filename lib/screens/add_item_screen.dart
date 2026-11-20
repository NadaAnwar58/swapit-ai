import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../theme/app_colors.dart';

/// Simple holder for a category shown in the dropdown.
class _CategoryOption {
  const _CategoryOption({required this.id, required this.label});

  final String id;
  final String label;
}

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

  // Used as the value of the "no category" entry in the dropdown.
  static const String _noCategory = '';

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _imageUrlController = TextEditingController();

  String _kind = 'have';
  String _condition = _conditions[2];
  String? _categoryId;

  List<_CategoryOption> _categories = <_CategoryOption>[];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  Future<void> _loadCategories() async {
    try {
      final List<Map<String, dynamic>> rows =
          await SwapitSupabaseService.fetchCategories();

      final List<_CategoryOption> options = <_CategoryOption>[];
      for (final Map<String, dynamic> row in rows) {
        final dynamic id = row['id'];
        if (id == null) continue;
        options.add(
          _CategoryOption(id: id.toString(), label: _categoryLabel(row)),
        );
      }

      if (!mounted) return;
      setState(() {
        _categories = options;
      });
    } catch (_) {
      // Categories are optional: if loading fails, the dropdown stays hidden.
      if (!mounted) return;
      setState(() {
        _categories = <_CategoryOption>[];
      });
    }
  }

  String _categoryLabel(Map<String, dynamic> row) {
    const List<String> keys = <String>['name', 'title', 'name_en', 'label'];
    for (final String key in keys) {
      final dynamic value = row[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return 'Category';
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  /// Converts Arabic-Indic digits and separators to normal ones so that
  /// numbers typed on an Arabic keyboard can be parsed.
  String _normalizeNumber(String input) {
    const String arabicDigits = '٠١٢٣٤٥٦٧٨٩';
    final StringBuffer buffer = StringBuffer();

    for (final int rune in input.trim().runes) {
      final String char = String.fromCharCode(rune);
      final int index = arabicDigits.indexOf(char);
      if (index >= 0) {
        buffer.write(index.toString());
      } else if (char == '٫') {
        buffer.write('.');
      } else if (char == '٬' || char == ',' || char == ' ') {
        // Thousands separators and spaces are ignored.
        continue;
      } else {
        buffer.write(char);
      }
    }

    return buffer.toString();
  }

  num? _parsePrice(String? input) {
    if (input == null) return null;
    return num.tryParse(_normalizeNumber(input));
  }

  bool _isValidUrl(String value) {
    final Uri? uri = Uri.tryParse(value);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  String _cleanError(Object error) {
    final String message = error.toString();
    const String prefix = 'Exception: ';
    if (message.startsWith(prefix)) {
      return message.substring(prefix.length);
    }
    return message;
  }

  InputDecoration _decoration(String label, {String? hint}) {
    final OutlineInputBorder normalBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppColors.border),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      filled: true,
      fillColor: AppColors.softBox,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: normalBorder,
      enabledBorder: normalBorder,
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.error, width: 1.6),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Submit
  // ---------------------------------------------------------------------------

  Future<void> _submit() async {
    if (_isSubmitting) return;

    FocusScope.of(context).unfocus();

    final FormState? form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final num? price = _parsePrice(_priceController.text);
    if (price == null) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState navigator = Navigator.of(context);

    final String imageUrl = _imageUrlController.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    try {
      await SwapitSupabaseService.insertItem(
        kind: _kind,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        condition: _condition,
        estimatedPriceEgp: price,
        city: _cityController.text.trim(),
        district: _districtController.text.trim(),
        categoryId: _categoryId,
        imageUrls: imageUrl.isEmpty ? <String>[] : <String>[imageUrl],
      );

      if (!mounted) return;

      messenger.showSnackBar(
        const SnackBar(content: Text('Item added successfully.')),
      );
      navigator.pop(true);
    } catch (error) {
      if (!mounted) return;

      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Could not add item: ${_cleanError(error)}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text('Add Item'),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: <Widget>[
                SegmentedButton<String>(
                  segments: const <ButtonSegment<String>>[
                    ButtonSegment<String>(
                      value: 'have',
                      label: Text('I offer'),
                      icon: Icon(Icons.card_giftcard),
                    ),
                    ButtonSegment<String>(
                      value: 'want',
                      label: Text('I need'),
                      icon: Icon(Icons.search),
                    ),
                  ],
                  selected: <String>{_kind},
                  onSelectionChanged: _isSubmitting
                      ? null
                      : (Set<String> selection) {
                          setState(() {
                            _kind = selection.first;
                          });
                        },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _titleController,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration('Title', hint: 'e.g. Used bicycle'),
                  validator: (String? value) {
                    final String text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Please enter a title.';
                    if (text.length < 3) {
                      return 'Title must be at least 3 characters.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_isSubmitting,
                  minLines: 3,
                  maxLines: 5,
                  textInputAction: TextInputAction.newline,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _decoration(
                    'Description',
                    hint: 'Describe the item and what you want in return',
                  ),
                  validator: (String? value) {
                    final String text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Please enter a description.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                if (_categories.isNotEmpty) ...<Widget>[
                  InputDecorator(
                    decoration: _decoration('Category (optional)'),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        isDense: true,
                        value: _categoryId ?? _noCategory,
                        dropdownColor: AppColors.softBox,
                        items: <DropdownMenuItem<String>>[
                          const DropdownMenuItem<String>(
                            value: _noCategory,
                            child: Text('No category'),
                          ),
                          ..._categories.map(
                            (_CategoryOption option) =>
                                DropdownMenuItem<String>(
                              value: option.id,
                              child: Text(
                                option.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (String? value) {
                                setState(() {
                                  _categoryId =
                                      (value == null || value.isEmpty)
                                          ? null
                                          : value;
                                });
                              },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                InputDecorator(
                  decoration: _decoration('Condition'),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      isDense: true,
                      value: _condition,
                      dropdownColor: AppColors.softBox,
                      items: _conditions
                          .map(
                            (String condition) => DropdownMenuItem<String>(
                              value: condition,
                              child: Text(condition),
                            ),
                          )
                          .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (String? value) {
                              if (value == null) return;
                              setState(() {
                                _condition = value;
                              });
                            },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _priceController,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.next,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration(
                    'Estimated price (EGP)',
                    hint: 'e.g. 1500',
                  ),
                  validator: (String? value) {
                    final String text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Please enter an estimated price.';
                    final num? price = _parsePrice(text);
                    if (price == null) return 'Please enter a valid number.';
                    if (price < 0) return 'Price cannot be negative.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _cityController,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: _decoration('City'),
                        validator: (String? value) {
                          if ((value?.trim() ?? '').isEmpty) {
                            return 'Required.';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _districtController,
                        enabled: !_isSubmitting,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        decoration: _decoration('District'),
                        validator: (String? value) {
                          if ((value?.trim() ?? '').isEmpty) {
                            return 'Required.';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _imageUrlController,
                  enabled: !_isSubmitting,
                  textInputAction: TextInputAction.done,
                  keyboardType: TextInputType.url,
                  decoration: _decoration(
                    'Image URL (optional)',
                    hint: 'https://...',
                  ),
                  validator: (String? value) {
                    final String text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    if (!_isValidUrl(text)) {
                      return 'Please enter a valid http(s) link.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.border,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Add Item',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}