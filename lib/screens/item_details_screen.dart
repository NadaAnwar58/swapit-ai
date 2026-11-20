import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show PostgrestException, User;

import '../services/swapit_supabase_service.dart';
import '../theme/app_colors.dart';

String _cleanError(Object error) {
  if (error is PostgrestException) return error.message;

  final String message = error.toString();
  const String prefix = 'Exception: ';
  if (message.startsWith(prefix)) {
    return message.substring(prefix.length);
  }
  return message;
}

/// شاشة تفاصيل الغرض.
///
/// بترجع `true` عند الرجوع لو حالة المفضلة اتغيرت، عشان الشاشة اللي قبلها
/// تحدّث نفسها.
class ItemDetailsScreen extends StatefulWidget {
  const ItemDetailsScreen({
    super.key,
    required this.item,
    this.initialIsFavorite = false,
  });

  final Map<String, dynamic> item;
  final bool initialIsFavorite;

  @override
  State<ItemDetailsScreen> createState() => _ItemDetailsScreenState();
}

class _ItemDetailsScreenState extends State<ItemDetailsScreen> {
  late bool _isFavorite;
  bool _isTogglingFavorite = false;

  @override
  void initState() {
    super.initState();
    _isFavorite = widget.initialIsFavorite;
  }

  // ---------------------------------------------------------------------------
  // Item helpers
  // ---------------------------------------------------------------------------

  String _text(String key) => (widget.item[key] ?? '').toString().trim();

  num? _number(String key) {
    final dynamic raw = widget.item[key];
    if (raw is num) return raw;
    return num.tryParse(raw?.toString() ?? '');
  }

  String get _itemId => _text('id');

  /// صاحب الغرض (عمود `owner_id` في جدول `items`).
  String get _ownerId => _text('owner_id');

  bool get _isOwnItem {
    final User? user = SwapitSupabaseService.currentUser;
    return user != null && _ownerId.isNotEmpty && _ownerId == user.id;
  }

  bool get _isWanted {
    final String kind = _text('kind').toLowerCase();
    return kind == 'want' || kind == 'request';
  }

  bool get _favoriteChanged => _isFavorite != widget.initialIsFavorite;

  String? get _imageUrl {
    final dynamic raw = widget.item['image_urls'];

    final List<dynamic> candidates = raw is List
        ? raw
        : (raw is String ? <dynamic>[raw] : <dynamic>[]);

    for (final dynamic entry in candidates) {
      final String url = entry?.toString().trim() ?? '';
      final Uri? uri = Uri.tryParse(url);
      if (uri != null &&
          (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty) {
        return url;
      }
    }
    return null;
  }

  String _formatPrice(num value) {
    final String digits = value.round().toString();
    final String withCommas = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (Match match) => ',',
    );
    return '~$withCommas EGP';
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _toggleFavorite() async {
    if (_isTogglingFavorite) return;

    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (_itemId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('This item cannot be saved yet.')),
      );
      return;
    }

    setState(() => _isTogglingFavorite = true);

    try {
      final bool nowFavorite =
          await SwapitSupabaseService.toggleFavorite(_itemId);
      if (!mounted) return;

      setState(() => _isFavorite = nowFavorite);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            nowFavorite ? 'Saved to favorites.' : 'Removed from favorites.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Could not update favorites: ${_cleanError(error)}'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isTogglingFavorite = false);
      }
    }
  }

  Future<void> _openProposeSheet() async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    if (_itemId.isEmpty || _ownerId.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'This is a sample item, so it cannot receive swap requests.',
          ),
        ),
      );
      return;
    }

    if (SwapitSupabaseService.currentUser == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Please log in to propose a swap.')),
      );
      return;
    }

    final String title = _text('title');

    final bool? sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        return _ProposeSwapSheet(
          targetItemId: _itemId,
          targetOwnerId: _ownerId,
          targetTitle: title.isEmpty ? 'this item' : title,
        );
      },
    );

    if (!mounted) return;

    if (sent == true) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Swap request sent.')),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------

  Widget _buildBanner() {
    final String? url = _imageUrl;

    final Widget image = url == null
        ? const _ImagePlaceholder()
        : Image.network(
            url,
            width: double.infinity,
            height: 260,
            fit: BoxFit.cover,
            loadingBuilder: (
              BuildContext context,
              Widget child,
              ImageChunkEvent? progress,
            ) {
              if (progress == null) return child;
              return const _ImagePlaceholder();
            },
            errorBuilder: (
              BuildContext context,
              Object error,
              StackTrace? stackTrace,
            ) {
              return const _ImagePlaceholder();
            },
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(height: 260, width: double.infinity, child: image),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String title = _text('title');
    final String description = _text('description');
    final String condition = _text('condition');
    final String fairness = _text('fairness_label');
    final String city = _text('city');
    final String district = _text('district');
    final num? price = _number('estimated_price_egp');
    final num? matchPercent = _number('match_percent');
    final num? distanceKm = _number('distance_km');

    final String placeLabel = <String>[
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) city,
    ].join(', ');

    final String locationLabel = <String>[
      if (placeLabel.isNotEmpty) placeLabel,
      if (distanceKm != null) '${distanceKm.toStringAsFixed(1)} km away',
    ].join(' · ');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        Navigator.of(context).pop<bool>(_favoriteChanged);
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.primary,
          elevation: 0,
          scrolledUnderElevation: 0,
          title: const Text('Item details'),
          actions: <Widget>[
            IconButton(
              onPressed: _isTogglingFavorite ? null : _toggleFavorite,
              tooltip:
                  _isFavorite ? 'Remove from favorites' : 'Save to favorites',
              icon: _isTogglingFavorite
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? AppColors.error : AppColors.primary,
                    ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: <Widget>[
            _buildBanner(),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                _Badge(
                  label: _isWanted ? 'I need' : 'I offer',
                  icon: _isWanted ? Icons.search : Icons.card_giftcard,
                  filled: true,
                ),
                if (condition.isNotEmpty)
                  _Badge(label: condition, icon: Icons.verified_outlined),
                if (matchPercent != null)
                  _Badge(
                    label: '${matchPercent.round()}% Match',
                    icon: Icons.auto_awesome_outlined,
                  ),
                if (fairness.isNotEmpty)
                  _Badge(label: fairness, icon: Icons.balance_outlined),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title.isEmpty ? 'Untitled item' : title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            if (price != null) ...<Widget>[
              const SizedBox(height: 6),
              Text(
                _formatPrice(price),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondary,
                ),
              ),
            ],
            if (locationLabel.isNotEmpty) ...<Widget>[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      locationLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 22),
            const Text(
              'Description',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.softBox,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                description.isEmpty ? 'No description provided.' : description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.45,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isOwnItem ? null : _openProposeSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.border,
                  disabledForegroundColor: AppColors.muted,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.swap_horiz),
                label: Text(
                  _isOwnItem ? 'This is your item' : 'Propose Swap',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Small private widgets
// -----------------------------------------------------------------------------

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 260,
      color: AppColors.softBox,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 56,
        color: AppColors.muted,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.icon,
    this.filled = false,
  });

  final String label;
  final IconData? icon;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final Color foreground = filled ? Colors.white : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: filled ? AppColors.primary : AppColors.softBox,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: filled ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableTile extends StatelessWidget {
  const _SelectableTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final String? sub = subtitle;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? AppColors.softBox : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.muted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      if (sub != null && sub.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 2),
                        Text(
                          sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ],
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

// -----------------------------------------------------------------------------
// Propose swap bottom sheet
// -----------------------------------------------------------------------------

class _ProposeSwapSheet extends StatefulWidget {
  const _ProposeSwapSheet({
    required this.targetItemId,
    required this.targetOwnerId,
    required this.targetTitle,
  });

  final String targetItemId;
  final String targetOwnerId;
  final String targetTitle;

  @override
  State<_ProposeSwapSheet> createState() => _ProposeSwapSheetState();
}

class _ProposeSwapSheetState extends State<_ProposeSwapSheet> {
  final TextEditingController _messageController = TextEditingController();

  List<Map<String, dynamic>> _myItems = <Map<String, dynamic>>[];
  String? _selectedItemId;
  bool _isLoadingItems = true;
  bool _loadFailed = false;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _loadMyItems();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadMyItems() async {
    try {
      final List<Map<String, dynamic>> items =
          await SwapitSupabaseService.fetchMyOfferedItems();
      if (!mounted) return;
      setState(() {
        _myItems = items;
        _isLoadingItems = false;
        _loadFailed = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _myItems = <Map<String, dynamic>>[];
        _isLoadingItems = false;
        _loadFailed = true;
      });
    }
  }

  String _itemTitle(Map<String, dynamic> item) {
    final String title = (item['title'] ?? '').toString().trim();
    return title.isEmpty ? 'Untitled item' : title;
  }

  String _itemSubtitle(Map<String, dynamic> item) {
    final String condition = (item['condition'] ?? '').toString().trim();
    final dynamic rawPrice = item['estimated_price_egp'];
    final num? price =
        rawPrice is num ? rawPrice : num.tryParse(rawPrice?.toString() ?? '');

    return <String>[
      if (condition.isNotEmpty) condition,
      if (price != null) '~${price.round()} EGP',
    ].join(' · ');
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final NavigatorState navigator = Navigator.of(context);

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await SwapitSupabaseService.proposeSwap(
        targetItemId: widget.targetItemId,
        targetOwnerId: widget.targetOwnerId,
        offeredItemId: _selectedItemId,
        message: _messageController.text,
      );
      if (!mounted) return;
      navigator.pop<bool>(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorText = _cleanError(error);
        _isSubmitting = false;
      });
    }
  }

  Widget _buildItemsSection() {
    if (_isLoadingItems) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.secondary),
        ),
      );
    }

    if (_loadFailed) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'Could not load your items. You can still send a request without '
          'choosing one.',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      );
    }

    if (_myItems.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Text(
          'You do not have any available offers yet. You can still send your '
          'request without choosing an item.',
          style: TextStyle(fontSize: 13, color: AppColors.muted),
        ),
      );
    }

    return Column(
      children: <Widget>[
        _SelectableTile(
          title: 'No item, just send a request',
          selected: _selectedItemId == null,
          onTap: _isSubmitting
              ? null
              : () => setState(() => _selectedItemId = null),
        ),
        for (final Map<String, dynamic> item in _myItems)
          _SelectableTile(
            title: _itemTitle(item),
            subtitle: _itemSubtitle(item),
            selected: _selectedItemId == (item['id'] ?? '').toString(),
            onTap: _isSubmitting
                ? null
                : () => setState(
                      () => _selectedItemId = (item['id'] ?? '').toString(),
                    ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? errorText = _errorText;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Propose a swap',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'For: ${widget.targetTitle}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 18),
            const Text(
              'Choose one of your items to offer (optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            _buildItemsSection(),
            const SizedBox(height: 12),
            TextField(
              controller: _messageController,
              enabled: !_isSubmitting,
              maxLength: 200,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: 'Note (optional)',
                hintText: 'Say hello or suggest a meeting spot',
                labelStyle: const TextStyle(color: AppColors.muted),
                hintStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.softBox,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.6,
                  ),
                ),
              ),
            ),
            if (errorText != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                errorText,
                style: const TextStyle(fontSize: 13, color: AppColors.error),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
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
                        'Send request',
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
    );
  }
}