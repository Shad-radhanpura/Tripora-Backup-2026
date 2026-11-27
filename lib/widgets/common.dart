import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Pushes a route but ignores repeated taps for a short moment, so a quick
/// double-tap cannot open the same screen twice.
class SafeNav {
  SafeNav._();

  static bool _busy = false;

  static Future<T?> push<T>(BuildContext context, Widget page) async {
    if (_busy) return null;
    _busy = true;
    Future.delayed(const Duration(milliseconds: 600), () => _busy = false);
    return Navigator.of(context).push<T>(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

void showAppMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? context.palette.danger : context.palette.navy,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
}

/// Human-readable text for a Firestore error, without internal details.
String describeFirestoreError(Object? error) {
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return 'Permission denied by Firestore security rules.';
      case 'unavailable':
        return 'The database is unreachable. Check your internet connection.';
      case 'failed-precondition':
        return 'This query needs a Firestore index (failed-precondition).';
      default:
        return 'Firestore error: ${error.code}';
    }
  }
  if (error is TimeoutException) {
    return 'The request timed out. Check your internet connection.';
  }
  return 'Something went wrong while loading data.';
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? color;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                color: (color ?? context.palette.blue).withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: color ?? context.palette.blue),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.palette.text,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.palette.muted,
                fontSize: 13,
                height: 1.45,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.explore_rounded, size: 19),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 22,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final Object? error;
  final String title;

  const ErrorState({
    super.key,
    required this.error,
    this.title = 'Could not load data',
  });

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      color: context.palette.danger,
      title: title,
      message: describeFirestoreError(error),
    );
  }
}

class LoadingState extends StatelessWidget {
  final String? message;

  const LoadingState({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: context.palette.blue),
          if (message != null) ...[
            const SizedBox(height: 14),
            Text(message!, style: TextStyle(color: context.palette.muted)),
          ],
        ],
      ),
    );
  }
}

/// Small rounded label, e.g. a category or budget tag.
class TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool onDark;

  const TagChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.onDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: onDark
            ? Colors.white.withValues(alpha: 0.22)
            : color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: onDark ? Colors.white : color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: onDark ? Colors.white : color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.palette.text,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(
                  subtitle!,
                  style: TextStyle(color: context.palette.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

/// Notice shown on every booking screen. Tripora has no real booking
/// provider, so bookings are demo requests and must never look like a
/// confirmed real-world reservation.
class DemoNotice extends StatelessWidget {
  final String message;

  const DemoNotice({
    super.key,
    this.message = 'Demo booking: sample prices and schedules. No seat, room '
        'or tour is actually reserved and no payment is taken.',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.warningSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.palette.warningBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: context.palette.warningText, size: 20),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: context.palette.warningText,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Coloured pill for a booking status.
class StatusPill extends StatelessWidget {
  final String status;
  final String label;

  const StatusPill({super.key, required this.status, required this.label});

  static Color colorFor(BuildContext context, String status) => switch (status) {
        'pending' => context.palette.orange,
        'confirmed' => context.palette.blue,
        'completed' => context.palette.green,
        'cancelled' => context.palette.danger,
        _ => context.palette.muted,
      };

  @override
  Widget build(BuildContext context) {
    return TagChip(label: label, color: colorFor(context, status));
  }
}
