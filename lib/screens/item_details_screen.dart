import 'package:flutter/material.dart';

import '../models/swap_item.dart';
import '../theme/app_colors.dart';
import '../widgets/image_placeholder.dart';
import '../widgets/pill.dart';

/// شاشة تفاصيل الغرض (فيها زرار الرجوع).
class ItemDetailsScreen extends StatelessWidget {
  final SwapItem item;

  const ItemDetailsScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            // الصف العلوي: رجوع + شارة + مشاركة + مفضلة
            Row(
              children: [
                _CircleButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.of(context).pop(), // زرار الرجوع
                ),
                const Spacer(),
                const Pill(
                  text: 'AI MATCH VERIFIED',
                  background: AppColors.softGreen,
                  foreground: AppColors.secondary,
                ),
                const Spacer(),
                _CircleButton(icon: Icons.share_outlined, onTap: () {}),
                const SizedBox(width: 8),
                _CircleButton(icon: Icons.favorite_border, onTap: () {}),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                const ImagePlaceholder(height: 260, radius: 22),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Pill(
                    text: '${item.matchPercent}% Match',
                    background: Colors.white,
                    foreground: AppColors.primary,
                  ),
                ),
                const Positioned(
                  top: 12,
                  right: 12,
                  child: Pill(
                    text: 'Available',
                    background: AppColors.softGreen,
                    foreground: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.categoryLine,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                      color: AppColors.secondary,
                    ),
                  ),
                ),
                const Icon(Icons.schedule, size: 13, color: AppColors.muted),
                const SizedBox(width: 4),
                Text(
                  item.postedAgo,
                  style:
                      const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              item.title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                height: 1.2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            _Card(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESTIMATED SWAP VALUE',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.6,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.priceText,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Pill(
                        text: '9.8/10 Score',
                        background: AppColors.softGreen,
                        foreground: AppColors.secondary,
                      ),
                      SizedBox(height: 4),
                      Text('Verified valuation',
                          style:
                              TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: item.isLargeGap ? AppColors.warnBg : AppColors.softBox,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.matchType == 'Mutual Match'
                        ? 'Mutual Swap Opportunity'
                        : 'Swap Opportunity',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${item.fairnessLabel} · ${item.fairnessTag}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.fairnessNote,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _InfoTile('CONDITION', item.condition)),
                const SizedBox(width: 10),
                Expanded(child: _InfoTile('CATEGORY', item.category)),
              ],
            ),
            const SizedBox(height: 10),
            _InfoTile('LOCATION', '${item.ownerCity} · ${item.distanceText}'),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'About this item',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: const TextStyle(
                        fontSize: 14, height: 1.5, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Owner's Swap Wishlist",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      Text('Cash-free trade',
                          style:
                              TextStyle(fontSize: 11, color: AppColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Items ${item.ownerName.split(' ').first} is specifically interested in accepting for this swap:',
                    style:
                        const TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final w in item.wishlist)
                        Pill(
                          text: w,
                          background: AppColors.softGreen,
                          foreground: AppColors.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.softBox,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'You can also propose bundles or request secondary balance items.',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.softBox,
                        child: Icon(Icons.person, color: AppColors.muted),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.ownerName,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              item.ownerCity,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoTile(
                            '${item.ownerSwaps} Swaps', '100% completed'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _InfoTile('Member', 'Since ${item.memberSince}'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(Icons.lock_outline,
                          size: 16, color: AppColors.muted),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'WhatsApp & exact address unlock instantly once both swappers accept.',
                          style:
                              TextStyle(fontSize: 12, color: AppColors.muted),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.softBox,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined,
                      size: 18, color: AppColors.secondary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Always inspect items and swap in well-lit public spots (e.g. cafe in Zamalek/Maadi).',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const Center(
              child: Text(
                'Report listing or inaccurate specs',
                style: TextStyle(fontSize: 12, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      shape: const CircleBorder(side: BorderSide(color: AppColors.border)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;

  const _InfoTile(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              letterSpacing: 0.5,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}