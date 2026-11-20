/// بيانات غرض واحد.
class SwapItem {
  final String id;
  final String title;
  final String categoryLine; // مثال: ELECTRONICS • PHOTOGRAPHY
  final String category;
  final String condition;
  final int priceEgp;
  final double distanceKm;
  final String ownerCity;
  final int matchPercent;
  final String matchType; // Mutual Match / One-Way Match
  final String actionLabel; // Request Swap / Make an Offer / Bundle & Offer
  final String fairnessLabel;
  final String fairnessTag;
  final String fairnessNote;
  final bool isLargeGap;
  final String postedAgo;
  final String description;
  final List<String> wishlist;
  final String ownerName;
  final int ownerSwaps;
  final String memberSince;

  /// رابط صورة الغرض (اختياري). لو null بيتعرض الشكل الافتراضي.
  final String? imageUrl;

  /// الصف الأصلي من قاعدة البيانات (null للأغراض التجريبية).
  final Map<String, dynamic>? raw;

  const SwapItem({
    required this.id,
    required this.title,
    required this.categoryLine,
    required this.category,
    required this.condition,
    required this.priceEgp,
    required this.distanceKm,
    required this.ownerCity,
    required this.matchPercent,
    required this.matchType,
    required this.actionLabel,
    required this.fairnessLabel,
    required this.fairnessTag,
    required this.fairnessNote,
    this.isLargeGap = false,
    required this.postedAgo,
    required this.description,
    required this.wishlist,
    required this.ownerName,
    required this.ownerSwaps,
    required this.memberSince,
    this.imageUrl,
    this.raw,
  });

  /// مثال: ~32,000 EGP
  String get priceText {
    final digits = priceEgp.toString();
    final withCommas = digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (m) => ',',
    );
    return '~$withCommas EGP';
  }

  /// مثال: 3.2 km
  String get distanceText => '${distanceKm.toStringAsFixed(1)} km';
}