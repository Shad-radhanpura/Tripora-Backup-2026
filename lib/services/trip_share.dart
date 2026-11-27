import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models/saved_trip.dart';

/// Result of asking the device to share a trip.
enum TripShareOutcome {
  /// The user chose an app and the share completed.
  shared,

  /// The share sheet was opened and then closed without an action.
  dismissed,

  /// Native sharing was not available, so the text was copied instead.
  copied,
}

/// Builds and sends a plain-text summary of a saved trip.
///
/// Only data stored with the trip is used. Nothing is invented, and no link
/// is created. The message goes through the device's own share sheet, so
/// the user picks WhatsApp, email or another app and sends it themselves.
class TripShare {
  TripShare._();

  /// Summary text for one saved trip. Missing fields are shown as
  /// "Not recorded" instead of being guessed.
  static String buildText({
    required String destination,
    required int? days,
    required String budget,
    required String interest,
    required String itinerary,
    DateTime? savedAt,
  }) {
    final buffer = StringBuffer()
      ..writeln('Tripora trip: ${_or(destination, 'Destination not recorded')}')
      ..writeln(
        'Duration: ${days == null ? 'Not recorded' : '$days ${days == 1 ? 'day' : 'days'}'}',
      )
      ..writeln('Budget: ${_or(budget, 'Not recorded')}')
      ..writeln('Interest: ${_or(interest, 'Not recorded')}');
    if (savedAt != null) {
      buffer.writeln('Saved: ${formatDate(savedAt)}');
    }
    buffer
      ..writeln()
      ..writeln('Itinerary');
    final body = _plain(itinerary);
    buffer.writeln(
      body.isEmpty ? 'No itinerary text is stored for this trip.' : body,
    );
    buffer
      ..writeln()
      ..write(
        'Shared from Tripora. This is a text copy of the saved itinerary.',
      );
    return buffer.toString();
  }

  /// Opens the native share sheet. If sharing is not available (for example
  /// some desktop browsers), the text is copied to the clipboard instead.
  /// Throws only if both sharing and copying fail.
  static Future<TripShareOutcome> share({
    required String text,
    required String subject,
  }) async {
    final ShareResult result;
    try {
      result = await SharePlus.instance.share(
        ShareParams(text: text, subject: subject, title: subject),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: text));
      return TripShareOutcome.copied;
    }

    switch (result.status) {
      case ShareResultStatus.success:
        return TripShareOutcome.shared;
      case ShareResultStatus.dismissed:
        return TripShareOutcome.dismissed;
      case ShareResultStatus.unavailable:
        await Clipboard.setData(ClipboardData(text: text));
        return TripShareOutcome.copied;
    }
  }

  static String _or(String value, String fallback) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? fallback : trimmed;
  }

  /// Removes markdown markers so the text reads well in a chat app.
  /// The wording of the itinerary is not changed.
  static String _plain(String text) {
    return text
        .split('\n')
        .map(
          (line) => line
              .replaceFirst(RegExp(r'^\s*#{1,6}\s*'), '')
              .replaceAll('**', '')
              .trimRight(),
        )
        .join('\n')
        .trim();
  }
}
