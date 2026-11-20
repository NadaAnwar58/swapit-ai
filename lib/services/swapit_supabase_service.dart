import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class SwapitSupabaseService {
  SwapitSupabaseService._();

  static const String itemsTable = 'items';
  static const String favoritesTable = 'favorites';
  static const String swapRequestsTable = 'swap_requests';
  static const String imagesBucket = 'item-images';

  static SupabaseClient get client => Supabase.instance.client;

  static User? get currentUser => client.auth.currentUser;

  static User _requireUser() {
    final User? user = currentUser;
    if (user == null) {
      throw Exception('Please log in first.');
    }
    return user;
  }

  // ---------------------------------------------------------------------------
  // Auth
  // ---------------------------------------------------------------------------

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) {
    return client.auth.signInWithPassword(email: email, password: password);
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) {
    return client.auth.signUp(
      email: email,
      password: password,
      data: <String, dynamic>{'full_name': fullName},
    );
  }

  static Future<void> signOut() => client.auth.signOut();

  // ---------------------------------------------------------------------------
  // Items
  // ---------------------------------------------------------------------------

  /// All items, newest first.
  static Future<List<Map<String, dynamic>>> fetchItems() async {
    final data = await client
        .from(itemsTable)
        .select()
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Items that belong to the current user.
  static Future<List<Map<String, dynamic>>> fetchMyItems() async {
    final User? user = currentUser;
    if (user == null) return <Map<String, dynamic>>[];

    final data = await client
        .from(itemsTable)
        .select()
        .eq('owner_id', user.id)
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  /// Current user's items of kind `have` (what they can offer in a swap).
  static Future<List<Map<String, dynamic>>> fetchMyOfferedItems() async {
    final User? user = currentUser;
    if (user == null) return <Map<String, dynamic>>[];

    final data = await client
        .from(itemsTable)
        .select()
        .eq('owner_id', user.id)
        .eq('kind', 'have')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> insertItem({
    required String kind,
    required String title,
    required String description,
    required String condition,
    required num estimatedPriceEgp,
    required String city,
    required String district,
    required List<String> imageUrls,
  }) async {
    final User user = _requireUser();

    await client.from(itemsTable).insert(<String, dynamic>{
      'owner_id': user.id,
      'kind': kind,
      'title': title,
      'description': description,
      'condition': condition,
      'estimated_price_egp': estimatedPriceEgp,
      'city': city,
      'district': district,
      'image_urls': imageUrls,
    });
  }

  static Future<void> deleteItem(
    String itemId, {
    List<String> imageUrls = const <String>[],
  }) async {
    final User user = _requireUser();

    await client
        .from(itemsTable)
        .delete()
        .eq('id', itemId)
        .eq('owner_id', user.id);

    await removeItemImages(imageUrls);
  }

  // ---------------------------------------------------------------------------
  // Images
  // ---------------------------------------------------------------------------

  static String _contentType(String fileName) {
    final String lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  /// Uploads one image and returns its public URL.
  static Future<String> uploadItemImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final User user = _requireUser();

    final String safeName =
        fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final String path =
        '${user.id}/${DateTime.now().microsecondsSinceEpoch}_$safeName';

    await client.storage.from(imagesBucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: _contentType(safeName)),
        );

    return client.storage.from(imagesBucket).getPublicUrl(path);
  }

  /// Best-effort removal of images by their public URLs. Never throws.
  static Future<void> removeItemImages(List<String> urls) async {
    final String marker = '/$imagesBucket/';
    final List<String> paths = <String>[];

    for (final String url in urls) {
      final int index = url.indexOf(marker);
      if (index == -1) continue;
      final String rawPath =
          url.substring(index + marker.length).split('?').first;
      paths.add(Uri.decodeComponent(rawPath));
    }

    if (paths.isEmpty) return;

    try {
      await client.storage.from(imagesBucket).remove(paths);
    } catch (_) {
      // Ignore cleanup failures.
    }
  }

  // ---------------------------------------------------------------------------
  // Favorites
  // ---------------------------------------------------------------------------

  static Future<Set<String>> fetchFavoriteItemIds() async {
    final User? user = currentUser;
    if (user == null) return <String>{};

    final data = await client
        .from(favoritesTable)
        .select('item_id')
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(data)
        .map((Map<String, dynamic> row) => row['item_id'].toString())
        .toSet();
  }

  /// Returns `true` if the item is now a favorite, `false` if it was removed.
  static Future<bool> toggleFavorite(String itemId) async {
    final User user = _requireUser();

    final Map<String, dynamic>? existing = await client
        .from(favoritesTable)
        .select('item_id')
        .eq('user_id', user.id)
        .eq('item_id', itemId)
        .maybeSingle();

    if (existing != null) {
      await client
          .from(favoritesTable)
          .delete()
          .eq('user_id', user.id)
          .eq('item_id', itemId);
      return false;
    }

    await client.from(favoritesTable).insert(<String, dynamic>{
      'user_id': user.id,
      'item_id': itemId,
    });
    return true;
  }

  // ---------------------------------------------------------------------------
  // Swap requests
  // ---------------------------------------------------------------------------

  static Future<void> proposeSwap({
    required String targetItemId,
    required String targetOwnerId,
    String? offeredItemId,
    String message = '',
  }) async {
    final User user = _requireUser();

    if (targetOwnerId == user.id) {
      throw Exception('You cannot request a swap on your own item.');
    }

    await client.from(swapRequestsTable).insert(<String, dynamic>{
      'requester_id': user.id,
      'target_item_id': targetItemId,
      'target_owner_id': targetOwnerId,
      'offered_item_id': offeredItemId,
      'message': message.trim(),
      'status': 'pending',
    });
  }
}