import 'package:flutter/material.dart';

import '../data/sample_items.dart';
import '../models/swap_item.dart';
import '../services/supabase_service.dart';
import '../theme/app_colors.dart';
import '../widgets/item_card.dart';
import 'add_item_screen.dart';
import 'item_details_screen.dart';
import 'profile_screen.dart';

/// الشاشة الرئيسية: قايمة الأغراض.
class HomeScreen extends StatefulWidget {
  final String userName;
  final String userEmail;

  const HomeScreen({
    super.key,
    this.userName = 'Alex',
    this.userEmail = 'alex@swapit.app',
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SwapItem> _items = List<SwapItem>.from(sampleItems);
  bool _isLoading = true;
  String _searchQuery = '';
  Set<String> _favoriteIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadItemsFromSupabase();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItemsFromSupabase() async {
    setState(() => _isLoading = true);

    try {
      final favoriteIds = await SwapitSupabaseService.fetchFavoriteItemIds();
      final rows = await SwapitSupabaseService.fetchItems();
      if (!mounted) return;
      _favoriteIds = favoriteIds;

      if (rows.isEmpty) {
        setState(() {
          _items = List<SwapItem>.from(sampleItems);
          _isLoading = false;
        });
        return;
      }

      final mapped = rows.map(_mapRowToSwapItem).toList();
      setState(() {
        _items = mapped;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items = List<SwapItem>.from(sampleItems);
        _isLoading = false;
      });
    }
  }

  /// يفتح شاشة إضافة غرض، ولو رجعت `true` بيعمل تحديث للقايمة.
  Future<void> _openAddItemScreen() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const AddItemScreen()),
    );

    if (!mounted) return;

    if (result == true) {
      await _loadItemsFromSupabase();
    }
  }

  /// بيحوّل الغرض التجريبي لـ Map عشان شاشة التفاصيل.
  Map<String, dynamic> _sampleToMap(SwapItem item) {
    final url = item.imageUrl;
    return <String, dynamic>{
      'id': item.id,
      'owner_id': '',
      'kind': 'have',
      'title': item.title,
      'description': item.description,
      'condition': item.condition,
      'estimated_price_egp': item.priceEgp,
      'city': item.ownerCity,
      'district': '',
      'distance_km': item.distanceKm,
      'match_percent': item.matchPercent,
      'fairness_label': item.fairnessLabel,
      'image_urls': <String>[if (url != null) url],
    };
  }

  /// بيفتح شاشة التفاصيل، ولو حالة المفضلة اتغيرت بيحدّث القايمة.
  Future<void> _openItemDetails(SwapItem item) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => ItemDetailsScreen(
          item: item.raw ?? _sampleToMap(item),
          initialIsFavorite: _favoriteIds.contains(item.id),
        ),
      ),
    );

    if (!mounted) return;

    if (changed == true) {
      final favoriteIds = await SwapitSupabaseService.fetchFavoriteItemIds();
      if (!mounted) return;
      setState(() => _favoriteIds = favoriteIds);
    }
  }

  SwapItem _mapRowToSwapItem(Map<String, dynamic> row) {
    final fallback = sampleItems.first;
    final title = (row['title'] ?? 'Swap Item').toString().trim();
    final description = (row['description'] ?? '').toString().trim();
    final condition = (row['condition'] ?? 'Good').toString().trim();
    final city = (row['city'] ?? '').toString().trim();
    final district = (row['district'] ?? '').toString().trim();
    final kind = (row['kind'] ?? '').toString().trim().toLowerCase();

    final rawPrice = row['estimated_price_egp'];
    final priceEgp = rawPrice is num
        ? rawPrice.round()
        : int.tryParse(rawPrice?.toString() ?? '') ?? fallback.priceEgp;

    final locationLabel = [
      if (district.isNotEmpty) district,
      if (city.isNotEmpty) city,
    ].join(', ');

    final rawDistance = row['distance_km'];
    final distanceKm = rawDistance is num
        ? rawDistance.toDouble()
        : double.tryParse(rawDistance?.toString() ?? '') ?? fallback.distanceKm;

    final rawMatch = row['match_percent'];
    final matchPercent = rawMatch is num
        ? rawMatch.round()
        : int.tryParse(rawMatch?.toString() ?? '') ?? fallback.matchPercent;

    String pickText(String key, String fallbackValue) {
      final value = (row[key] ?? '').toString().trim();
      return value.isEmpty ? fallbackValue : value;
    }

    final rawImages = row['image_urls'];
    String? imageUrl;
    if (rawImages is List) {
      for (final entry in rawImages) {
        final url = entry?.toString().trim() ?? '';
        if (url.isNotEmpty) {
          imageUrl = url;
          break;
        }
      }
    }

    final isWanted = kind == 'want' || kind == 'request';

    final categoryLabel =
        (row['category'] ?? (isWanted ? 'WANTED' : 'GENERAL'))
            .toString()
            .toUpperCase();

    return SwapItem(
      id: (row['id'] ?? '').toString(),
      title: title.isEmpty ? 'Swap Item' : title,
      categoryLine: categoryLabel,
      category: categoryLabel,
      condition: condition.isEmpty ? 'Good' : condition,
      priceEgp: priceEgp,
      distanceKm: distanceKm,
      ownerCity: locationLabel.isEmpty ? fallback.ownerCity : locationLabel,
      matchPercent: matchPercent,
      matchType: pickText('match_type', fallback.matchType),
      actionLabel: pickText('action_label', fallback.actionLabel),
      fairnessLabel: pickText('fairness_label', fallback.fairnessLabel),
      fairnessTag: fallback.fairnessTag,
      fairnessNote: fallback.fairnessNote,
      isLargeGap: fallback.isLargeGap,
      postedAgo: 'Just now',
      description: description.isEmpty
          ? 'Available for mindful swapping on Swapit.'
          : description,
      wishlist: fallback.wishlist,
      ownerName: fallback.ownerName,
      ownerSwaps: fallback.ownerSwaps,
      memberSince: fallback.memberSince,
      imageUrl: imageUrl,
      raw: row,
    );
  }

  List<SwapItem> get _filteredItems {
    final q = _searchQuery.trim().toLowerCase();
    if (q.isEmpty) return _items;

    return _items.where((item) {
      return item.title.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.categoryLine.toLowerCase().contains(q) ||
          item.ownerCity.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = _filteredItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddItemScreen,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        tooltip: 'Add item',
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadItemsFromSupabase,
          color: AppColors.secondary,
          child: ListView(
            // مسافة تحت زيادة عشان الزرار العايم ما يغطيش آخر عنصر.
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Hello, ${widget.userName}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProfileScreen(
                            userName: widget.userName,
                            userEmail: widget.userEmail,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.person_outline,
                      size: 28,
                      color: AppColors.primary,
                    ),
                    tooltip: 'Profile',
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Find your next perfect mindful swap in Cairo',
                style: TextStyle(fontSize: 14, color: AppColors.muted),
              ),
              const SizedBox(height: 14),
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: AppColors.muted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                        decoration: const InputDecoration(
                          hintText: 'Search items, categories, or cities...',
                          hintStyle: TextStyle(
                            color: AppColors.muted,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: const Icon(
                          Icons.close,
                          size: 18,
                          color: AppColors.muted,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Smart Matches',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ranked by AI compatibility & fair value',
                          style: TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'View All (${visibleItems.length})',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.secondary),
                  ),
                )
              else if (visibleItems.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Text(
                      'No matching items found.',
                      style: TextStyle(color: AppColors.muted, fontSize: 14),
                    ),
                  ),
                )
              else
                for (final item in visibleItems)
                  ItemCard(
                    item: item,
                    onTap: () => _openItemDetails(item),
                  ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Circularity through Conscious Trading',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}