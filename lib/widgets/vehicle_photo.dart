import 'package:flutter/material.dart';

import '../data/vehicle_photos.dart';
import '../theme/theme.dart';

/// Icon for a booking kind or a service name. Used by the fallback panel.
IconData vehicleIconFor(String kind) => switch (kind) {
      'bus' || 'Buses' => Icons.directions_bus_rounded,
      'train' || 'Trains' => Icons.train_rounded,
      'flight' || 'Flights' => Icons.flight_rounded,
      'cab' || 'Cabs' => Icons.local_taxi_rounded,
      _ => Icons.directions_car_rounded,
    };

/// A bundled vehicle photo with a fixed shape: rounded corners, cropped to
/// [aspectRatio] and never wider than [maxHeight]. If the photo cannot be
/// loaded, a plain panel with the vehicle icon is shown instead.
class VehiclePhoto extends StatelessWidget {
  final String asset;

  /// Describes the photo for screen readers.
  final String label;
  final IconData icon;
  final double aspectRatio;
  final double maxHeight;

  const VehiclePhoto({
    super.key,
    required this.asset,
    required this.label,
    this.icon = Icons.directions_car_rounded,
    this.aspectRatio = 16 / 9,
    this.maxHeight = 220,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            asset,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            semanticLabel: label,
            errorBuilder: (context, error, stackTrace) =>
                VehiclePhotoFallback(label: label, icon: icon),
          ),
        ),
      ),
    );
  }
}

/// Shown in place of a vehicle photo that cannot be loaded.
class VehiclePhotoFallback extends StatelessWidget {
  final String label;
  final IconData icon;

  const VehiclePhotoFallback({
    super.key,
    required this.label,
    this.icon = Icons.directions_car_rounded,
  });

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
                Icon(icon, color: Colors.white70, size: 34),
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

/// Small line under a vehicle photo: says the photo is illustrative and
/// gives its credit from [VehiclePhotos.credits].
class VehiclePhotoCaption extends StatelessWidget {
  final String asset;

  const VehiclePhotoCaption({super.key, required this.asset});

  @override
  Widget build(BuildContext context) {
    final credit = VehiclePhotos.credits[asset];
    const note = 'Illustrative photo. The vehicle you are given may differ.';
    final text = credit == null ? note : '$note ${credit.line}';
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        text,
        key: const Key('vehicle-photo-caption'),
        style: TextStyle(color: context.palette.muted, fontSize: 11),
      ),
    );
  }
}
