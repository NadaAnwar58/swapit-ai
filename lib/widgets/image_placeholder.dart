import 'package:flutter/material.dart';

/// مكان الصورة لحد ما نحط صور حقيقية.
class ImagePlaceholder extends StatelessWidget {
  final double height;
  final double radius;

  const ImagePlaceholder({super.key, this.height = 190, this.radius = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE9E7DD),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Color(0xFFB5B8AE)),
      ),
    );
  }
}
