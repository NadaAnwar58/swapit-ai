import 'package:supabase_flutter/supabase_flutter.dart';

/// Central place for all Supabase calls used by the Swapit app.
class SwapitSupabaseService {
  SwapitSupabaseService._();

  // ---------------------------------------------------------------------------
  // Access helpers
  // ---------------------------------------------------------------------------

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static Session? get currentSession => client.auth.currentSession;

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) {
    final String? name = fullName?.trim();

    return client.auth.signUp(
      email: email.trim(),
      password: password,
      data: (name != null && name.isNotEmpty)
          ? <String, dynamic>{'full_name': name}
          : null,
    );
  }

  static Future<void> signOut() {
    return client.auth.signOut();
  }

  // ---------------------------------------------------------------------------
  // Categories
  // ---------------------------------------------------------------------------

  /// Fetches all categories. Tries to order by `sort_order`, then `name`,
  /// then `title`; if none of those columns exist, returns them unordered.
  static Future<List<Map<String, dynamic>>> fetchCategories() async {
    const List<String> orderColumns = <String>['sort_order', 'name', 'title'];

    for (final String column in orderColumns) {
      try {
        final List<Map<String, dynamic>> data = await client
            .from('categories')
            .select()
            .order(column, ascending: true);
        return List<Map<String, dynamic>>.from(data);
      } on PostgrestException {
        // Column probably doesn't exist; try the next one.
        continue;
      }
    }

    final List<Map<String, dynamic>> data =
        await client.from('categories').select();
    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------------------------------------------------------------------
  // Items
  // ---------------------------------------------------------------------------

  static Future<List<Map<String, dynamic>>> fetchItems() async {
    final List<Map<String, dynamic>> data = await client
        .from('items')
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<Map<String, dynamic>> insertItem({
    required String title,
    required String description,
    required String condition,
    required num estimatedPriceEgp,
    required String city,
    required String district,
    String kind = 'have',
    String? categoryId,
    num distanceKm = 1.5,
    int matchPercent = 85,
    String matchType = 'Great Match',
    String fairnessLabel = 'Fair Value',
    String actionLabel = 'Propose Swap',
    String status = 'available',
    List<String> imageUrls = const <String>[],
  }) async {
    final User? user = currentUser;
    if (user == null) {
      throw Exception('You must be logged in to add an item.');
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'owner_id': user.id,
      'kind': kind,
      'title': title.trim(),
      'description': description.trim(),
      'condition': condition,
      'estimated_price_egp': estimatedPriceEgp,
      'city': city.trim(),
      'district': district.trim(),
      'distance_km': distanceKm,
      'match_percent': matchPercent,
      'match_type': matchType,
      'fairness_label': fairnessLabel,
      'action_label': actionLabel,
      'status': status,
      'image_urls': imageUrls,
    };

    if (categoryId != null && categoryId.isNotEmpty) {
      payload['category_id'] = categoryId;
    }

    final Map<String, dynamic> row =
        await client.from('items').insert(payload).select().single();

    return Map<String, dynamic>.from(row);
  }

  // ---------------------------------------------------------------------------
  // My offered items
  // ---------------------------------------------------------------------------

  /// الأغراض المتاحة اللي أنا عارضها (kind = have, status = available).
  static Future<List<Map<String, dynamic>>> fetchMyOfferedItems() async {
    final User? user = currentUser;
    if (user == null) return <Map<String, dynamic>>[];

    final List<Map<String, dynamic>> data = await client
        .from('items')
        .select()
        .eq('owner_id', user.id)
        .eq('kind', 'have')
        .eq('status', 'available')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------

  /// ids الأغراض المفضلة للمستخدم الحالي. بترجع Set فاضي لو مفيش تسجيل
  /// دخول أو حصل أي خطأ.
  static Future<Set<String>> fetchFavoriteItemIds() async {
    final User? user = currentUser;
    if (user == null) return <String>{};

    try {
      final List<Map<String, dynamic>> data = await client
          .from('favorites')
          .select('item_id')
          .eq('user_id', user.id);

      return data
          .where((Map<String, dynamic> row) => row['item_id'] != null)
          .map((Map<String, dynamic> row) => row['item_id'].toString())
          .toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// لو الغرض في المفضلة بيتشال وبترجع false، ولو مش فيها بيتضاف وبترجع true.
  static Future<bool> toggleFavorite(String itemId) async {
    final User? user = currentUser;
    if (user == null) {
      throw Exception('You must be logged in to save favorites.');
    }
    if (itemId.isEmpty) {
      throw Exception('This item cannot be saved to favorites.');
    }

    final List<Map<String, dynamic>> existing = await client
        .from('favorites')
        .select('item_id')
        .eq('user_id', user.id)
        .eq('item_id', itemId)
        .limit(1);

    if (existing.isNotEmpty) {
      await client
          .from('favorites')
          .delete()
          .eq('user_id', user.id)
          .eq('item_id', itemId);
      return false;
    }

    await client.from('favorites').insert(<String, dynamic>{
      'user_id': user.id,
      'item_id': itemId,
    });
    return true;
  }

  // ---------------------------------------------------------------------------
  // Swap requests
  // ---------------------------------------------------------------------------

  /// بيبعت طلب تبادل على غرض. بيكتب في جدول `swap_requests`.
  static Future<void> proposeSwap({
    required String targetItemId,
    required String targetOwnerId,
    String? offeredItemId,
    String? message,
  }) async {
    final User? user = currentUser;
    if (user == null) {
      throw Exception('You must be logged in to propose a swap.');
    }
    if (targetItemId.isEmpty || targetOwnerId.isEmpty) {
      throw Exception('This item has no owner information, so it cannot '
          'receive swap requests.');
    }
    if (targetOwnerId == user.id) {
      throw Exception('You cannot propose a swap on your own item.');
    }

    final Map<String, dynamic> payload = <String, dynamic>{
      'requester_id': user.id,
      'target_owner_id': targetOwnerId,
      'target_item_id': targetItemId,
      'status': 'pending',
    };

    if (offeredItemId != null && offeredItemId.isNotEmpty) {
      payload['offered_item_id'] = offeredItemId;
    }

    final String? note = message?.trim();
    if (note != null && note.isNotEmpty) {
      payload['message'] = note;
    }

    try {
      await client.from('swap_requests').insert(payload);
    } on PostgrestException catch (error) {
      final String code = error.code ?? '';

      if (code == '42P01' || code == 'PGRST205') {
        throw Exception('The swap_requests table does not exist yet in '
            'Supabase. Create it first, then try again.');
      }
      if (code == '42501') {
        throw Exception('Permission denied on swap_requests. Check the '
            'grants and row level security policies for this table.');
      }
      if (code == '23503') {
        throw Exception('One of the items in this request no longer exists.');
      }
      if (code == '42703' || code == 'PGRST204') {
        throw Exception('The swap_requests table is missing one of the '
            'expected columns: requester_id, target_owner_id, '
            'target_item_id, offered_item_id, message, status.');
      }
      throw Exception(error.message);
    }
  }
}