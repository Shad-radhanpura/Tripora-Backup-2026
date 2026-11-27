import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A dish photo bundled with the app. If the photo cannot be loaded, the
/// space shows a coloured panel with the dish name instead of a broken image.
class DishPhoto extends StatelessWidget {
  final String asset;
  final String label;
  final double height;

  const DishPhoto({
    super.key,
    required this.asset,
    required this.label,
    this.height = 180,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        semanticLabel: label,
        errorBuilder: (context, error, stackTrace) =>
            DishPhotoFallback(label: label),
      ),
    );
  }
}

/// Shown in place of a dish photo that cannot be loaded.
class DishPhotoFallback extends StatelessWidget {
  final String label;

  const DishPhotoFallback({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white70,
                  size: 34,
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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
