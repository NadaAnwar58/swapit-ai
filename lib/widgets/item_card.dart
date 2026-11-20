import 'package:flutter/material.dart';

import '../models/swap_item.dart';
import '../theme/app_colors.dart';
import 'image_placeholder.dart';
import 'pill.dart';

/// كارت الغرض في الشاشة الرئيسية.
class ItemCard extends StatelessWidget {
  final SwapItem item;
  final VoidCallback onTap;

  const ItemCard({super.key, required this.item, required this.onTap});

  static const double _imageHeight = 190;

  /// بيعرض صورة الغرض لو فيه رابط، ولو مفيش (أو فشل التحميل)
  /// بيرجع للشكل الافتراضي.
  Widget _buildImage() {
    final url = item.imageUrl?.trim() ?? '';
    if (url.isEmpty) {
      return const ImagePlaceholder(height: _imageHeight);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Image.network(
        url,
        width: double.infinity,
        height: _imageHeight,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return const ImagePlaceholder(height: _imageHeight);
        },
        errorBuilder: (context, error, stackTrace) {
          return const ImagePlaceholder(height: _imageHeight);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final warn = item.isLargeGap;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    _buildImage(),
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Pill(
                        text: item.matchType,
                        background: AppColors.softGreen,
                        foreground: AppColors.primary,
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Pill(
                        text: '${item.matchPercent}% Match',
                        background: AppColors.primary,
                        foreground: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      item.priceText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.near_me_outlined,
                        size: 14, color: AppColors.muted),
                    const SizedBox(width: 4),
                    Text(
                      '${item.ownerCity} · ${item.distanceText} away',
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: warn ? AppColors.warnBg : AppColors.softBox,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.fairnessLabel,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: warn
                                    ? AppColors.warnText
                                    : AppColors.secondary,
                              ),
                            ),
                          ),
                          Text(
                            item.fairnessTag,
                            style: const TextStyle(
                                fontSize: 11, color: AppColors.muted),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.fairnessNote,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    // TODO: هنربطه بطلب التبادل في مرحلة لاحقة
                    onPressed: () {},
                    icon: const Icon(Icons.swap_horiz, size: 18),
                    label: Text(item.actionLabel),
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