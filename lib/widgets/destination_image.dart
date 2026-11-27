import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Network photo with a soft placeholder while loading and an attractive
/// gradient fallback if the photo cannot be loaded (offline, slow network,
/// blocked host).
class DestinationImage extends StatelessWidget {
  final String? url;
  final String label;
  final BoxFit fit;

  /// Decode width in physical pixels; keeps memory low for small cards.
  final int? cacheWidth;

  const DestinationImage({
    super.key,
    required this.url,
    this.label = '',
    this.fit = BoxFit.cover,
    this.cacheWidth,
  });

  // Wikimedia asks apps to identify themselves. Browsers do not allow a
  // custom User-Agent, so the header is only sent on Android.
  static const Map<String, String>? _headers = kIsWeb
      ? null
      : {'User-Agent': 'TriporaApp/1.0 (Flutter; MCA student project)'};

  @override
  Widget build(BuildContext context) {
    final value = url;
    if (value == null || value.isEmpty) return _fallback();

    return Image.network(
      value,
      fit: fit,
      headers: _headers,
      cacheWidth: cacheWidth,
      gaplessPlayback: true,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          color: const Color(0xFFE8EEF8),
          alignment: Alignment.center,
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: context.palette.blue,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  Widget _fallback() {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.landscape_rounded,
              color: Colors.white70,
              size: 34,
            ),
            if (label.isNotEmpty) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ],
          ),
        ),
      ),
    );
  }
}
