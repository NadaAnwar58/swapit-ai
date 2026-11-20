import 'package:flutter/material.dart';

import '../services/swapit_supabase_service.dart';
import '../theme/app_colors.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';

class MyItemsScreen extends StatefulWidget {
  const MyItemsScreen({super.key});

  @override
  State<MyItemsScreen> createState() => _MyItemsScreenState();
}

class _MyItemsScreenState extends State<MyItemsScreen> {
  List<Map<String, dynamic>> _items = <Map<String, dynamic>>[];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _cleanError(Object e) {
    final String raw = e.toString();
    return raw.startsWith('Exception: ') ? raw.substring(11) : raw;
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<Map<String, dynamic>> items =
          await SwapitSupabaseService.fetchMyItems();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = _cleanError(e);
        _isLoading = false;
      });
    }
  }

  Future<void> _openAddItem() async {
    final bool? added = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddItemScreen()),
    );
    if (!mounted) return;
    if (added == true) {
      await _load();
    }
  }

  Future<void> _openDetails(Map<String, dynamic> item) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ItemDetailsScreen(item: item),
      ),
    );
  }

  List<String> _imageUrls(Map<String, dynamic> item) {
    final dynamic raw = item['image_urls'];
    if (raw is! List) return <String>[];
    return raw
        .map((dynamic e) => e?.toString().trim() ?? '')
        .where((String url) => url.isNotEmpty)
        .toList();
  }

  Future<void> _confirmDelete(Map<String, dynamic> item) async {
    final String id = (item['id'] ?? '').toString();
    if (id.isEmpty) return;

    final String title = (item['title'] ?? '').toString().trim();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.background,
          title: const Text('Delete item?'),
          content: Text(
            title.isEmpty
                ? 'This item will be removed permanently.'
                : '"$title" will be removed permanently.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppColors.muted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    if (!mounted) return;

    try {
      await SwapitSupabaseService.deleteItem(id, imageUrls: _imageUrls(item));
      if (!mounted) return;
      setState(() {
        _items = _items
            .where((Map<String, dynamic> e) => (e['id'] ?? '').toString() != id)
            .toList();
      });
      messenger.showSnackBar(const SnackBar(content: Text('Item deleted.')));
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: AppColors.error,
          content: Text('Could not delete: ${_cleanError(e)}'),
        ),
      );
    }
  }

  Widget _thumbnail(Map<String, dynamic> item) {
    final List<String> urls = _imageUrls(item);

    Widget placeholder() => Container(
          width: 64,
          height: 64,
          color: AppColors.softBox,
          alignment: Alignment.center,
          child: const Icon(Icons.image_outlined, color: AppColors.muted),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: urls.isEmpty
          ? placeholder()
          : Image.network(
              urls.first,
              width: 64,
              height: 64,
              fit: BoxFit.cover,
              errorBuilder: (
                BuildContext context,
                Object error,
                StackTrace? stackTrace,
              ) =>
                  placeholder(),
            ),
    );
  }

  Widget _itemTile(Map<String, dynamic> item) {
    final String title = (item['title'] ?? '').toString().trim();
    final String condition = (item['condition'] ?? '').toString().trim();
    final bool isWanted = (item['kind'] ?? '').toString() == 'want';
    final dynamic rawPrice = item['estimated_price_egp'];
    final num? price =
        rawPrice is num ? rawPrice : num.tryParse(rawPrice?.toString() ?? '');

    final String subtitle = <String>[
      isWanted ? 'Need' : 'Offer',
      if (condition.isNotEmpty) condition,
      if (price != null) '~${price.round()} EGP',
    ].join(' · ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
        onTap: () => _openDetails(item),
        leading: _thumbnail(item),
        title: Text(
          title.isEmpty ? 'Untitled item' : title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
        subtitle: Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.muted),
        ),
        trailing: IconButton(
          tooltip: 'Delete',
          icon: const Icon(Icons.delete_outline, color: AppColors.error),
          onPressed: () => _confirmDelete(item),
        ),
      ),
    );
  }

  Widget _centerMessage(String text, {bool showRetry = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Column(
        children: <Widget>[
          Text(
            text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
          if (showRetry) ...<Widget>[
            const SizedBox(height: 12),
            TextButton(
              onPressed: _load,
              child: const Text(
                'Try again',
                style: TextStyle(color: AppColors.primary),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? error = _error;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.primary),
        title: const Text(
          'My Items',
          style: TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItem,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add item',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          color: AppColors.secondary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
            children: <Widget>[
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child:
                        CircularProgressIndicator(color: AppColors.secondary),
                  ),
                )
              else if (error != null)
                _centerMessage('Could not load your items.\n$error',
                    showRetry: true)
              else if (_items.isEmpty)
                _centerMessage(
                  'You have not added any items yet.\nTap + to add your first one.',
                )
              else
                for (final Map<String, dynamic> item in _items) _itemTile(item),
            ],
          ),
        ),
      ),
    );
  }
}