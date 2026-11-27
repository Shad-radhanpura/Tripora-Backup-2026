import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../theme/theme.dart';
import '../widgets/budget_estimate_card.dart';
import '../models/saved_trip.dart';
import '../widgets/destination_image.dart';
import '../services/trip_share.dart';
import 'travel_checklist_section.dart';

class ItineraryPage extends StatelessWidget {
  final String itinerary;
  final String destination;
  final int days;
  final String budget;
  final String interest;

  /// True when this itinerary is stored in Firestore (My Trips).
  final bool isSaved;

  /// When the saved trip was created, if known.
  final DateTime? savedAt;

  /// Hide "Plan Another Trip" when opened from My Trips or the Admin Panel.
  final bool showPlanAnother;

  /// Optional subtitle shown under the header (e.g. the owner, for admins).
  final String? subtitle;

  /// Firestore ID of the saved trip. Set only by the owner's My Trips view;
  /// when null (Admin Panel) the travel-documents checklist is not shown.
  final String? tripId;

  const ItineraryPage({
    super.key,
    required this.itinerary,
    required this.destination,
    required this.days,
    required this.budget,
    required this.interest,
    this.isSaved = false,
    this.savedAt,
    this.showPlanAnother = true,
    this.subtitle,
    this.tripId,
  });


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              _buildHero(context),
              _buildTripSummary(context),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: BudgetEstimateCard(budget: budget, days: days),
              ),
              _buildItinerary(context),
              if (tripId != null) _buildShareButton(context),
              if (tripId != null) TravelChecklistSection(tripId: tripId!),
              if (showPlanAnother) _buildBottomCta(context),
              const SizedBox(height: 35),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  /// Shares a text summary of this saved trip through the device's own
  /// share sheet (WhatsApp, email, etc.). Only the owner's view has this
  /// button, because the trip ID is passed only from My Trips.
  Widget _buildShareButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton.icon(
          key: const Key('share-trip'),
          onPressed: () => _shareTrip(context),
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text(
            'Share trip',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: context.palette.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _shareTrip(BuildContext context) async {
    final text = TripShare.buildText(
      destination: destination,
      days: days > 0 ? days : null,
      budget: budget,
      interest: interest,
      itinerary: itinerary,
      savedAt: savedAt,
    );
    try {
      final outcome = await TripShare.share(
        text: text,
        subject: 'Tripora trip: $destination',
      );
      if (!context.mounted) return;
      final message = switch (outcome) {
        TripShareOutcome.shared => 'Trip shared.',
        TripShareOutcome.copied =>
          'Sharing is not available here, so the trip text was copied.',
        TripShareOutcome.dismissed => null,
      };
      if (message != null) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (e) {
      debugPrint('Share failed: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not share this trip. Please try again.'),
          ),
        );
    }
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        12,
        18,
        8,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: context.palette.surface,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: context.palette.border,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: context.palette.text,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Your journey',
                  style: TextStyle(
                    color: context.palette.text,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  subtitle ??
                      (isSaved
                          ? (savedAt == null
                              ? 'Saved in My Trips'
                              : 'Saved in My Trips · ${formatDate(savedAt)}')
                          : 'Created by Tripora AI'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.palette.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 11,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: context.palette.surfaceTint,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              isSaved ? '✓ Saved' : '✨ AI',
              style: TextStyle(
                color: context.palette.blue,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HERO
  // ============================================================

  Widget _buildHero(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        16,
        8,
        16,
        0,
      ),
      child: Container(
        height: 260,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(29),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: 0.12,
              ),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: Stack(
            fit: StackFit.expand,
            children: [
              DestinationImage(
                url: _destinationImage(),
                label: destination,
              ),

              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(
                        alpha: 0.78,
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.92,
                    ),
                    borderRadius:
                    BorderRadius.circular(30),
                  ),
                  child: Text(
                    '✨ Personalized trip',
                    style: TextStyle(
                      color: context.palette.text,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

              Positioned(
                left: 19,
                right: 19,
                bottom: 18,
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '$days ${days == 1 ? 'day' : 'days'} • $interest • $budget',
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.85,
                        ),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _destinationImage() {
    // Prefer the verified photo from the destination catalogue.
    final match = DestinationCatalog.matchName(destination);
    if (match != null) return match.imageUrl;

    final value = destination.toLowerCase();

    if (value.contains('manali') ||
        value.contains('himachal')) {
      return 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4';
    }

    if (value.contains('goa')) {
      return 'https://images.unsplash.com/photo-1510414842594-a61c69b5ae57';
    }

    if (value.contains('dubai')) {
      return 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c';
    }

    if (value.contains('bali')) {
      return 'https://images.unsplash.com/photo-1537996194471-e657df975ab4';
    }

    if (value.contains('paris')) {
      return 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34';
    }

    if (value.contains('tokyo')) {
      return 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf';
    }

    if (value.contains('kerala')) {
      return 'https://images.unsplash.com/photo-1602216056096-3b40cc0c9944';
    }

    return 'https://images.unsplash.com/photo-1500534623283-312aade485b7';
  }

  // ============================================================
  // SUMMARY
  // ============================================================

  Widget _buildTripSummary(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        20,
        18,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: context.palette.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: context.palette.border,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _summaryItem(context, 
                '🗓️',
                '$days days',
                'Duration',
              ),
            ),
            _divider(context),
            Expanded(
              child: _summaryItem(context, 
                '💰',
                budget,
                'Budget',
              ),
            ),
            _divider(context),
            Expanded(
              child: _summaryItem(context, 
                '✨',
                interest,
                'Interest',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(BuildContext context, 
      String emoji,
      String title,
      String subtitle,
      ) {
    return Column(
      children: [
        Text(
          emoji,
          style: const TextStyle(fontSize: 20),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: context.palette.text,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(
            color: context.palette.muted,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  Widget _divider(BuildContext context) {
    return Container(
      width: 1,
      height: 43,
      color: context.palette.border,
    );
  }

  // ============================================================
  // ITINERARY
  // ============================================================

  Widget _buildItinerary(BuildContext context) {
    final cleaned = itinerary.trim();

    final sections = _splitItinerary(cleaned);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        25,
        18,
        0,
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Text(
            'Your itinerary',
            style: TextStyle(
              color: context.palette.text,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'A personalized plan for your journey.',
            style: TextStyle(
              color: context.palette.muted,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 16),

          if (sections.isEmpty)
            _fallbackItinerary(context, cleaned)
          else
            ...sections.asMap().entries.map(
                  (entry) {
                return _dayCard(context, 
                  entry.key + 1,
                  entry.value,
                );
              },
            ),
        ],
      ),
    );
  }

  List<String> _splitItinerary(String text) {
    if (text.isEmpty) {
      return [];
    }

    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    final List<String> groups = [];

    String current = '';

    for (final line in lines) {
      final lower = line.toLowerCase();

      final isDay =
          lower.startsWith('day ') ||
              lower.startsWith('day:') ||
              lower.contains('day 1') ||
              lower.contains('day 2') ||
              lower.contains('day 3') ||
              lower.contains('day 4') ||
              lower.contains('day 5') ||
              lower.contains('day 6') ||
              lower.contains('day 7');

      if (isDay && current.isNotEmpty) {
        groups.add(current.trim());
        current = line;
      } else {
        if (current.isEmpty) {
          current = line;
        } else {
          current += '\n$line';
        }
      }
    }

    if (current.isNotEmpty) {
      groups.add(current.trim());
    }

    return groups;
  }

  Widget _dayCard(BuildContext context, 
      int dayNumber,
      String content,
      ) {
    final lines = content.split('\n');

    String title = 'Day $dayNumber';
    String body = content;

    if (lines.isNotEmpty) {
      title = lines.first
          .replaceAll('#', '')
          .trim();

      if (title.length > 50) {
        title = 'Day $dayNumber';
      }

      if (lines.length > 1) {
        body = lines.skip(1).join('\n');
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: context.palette.border,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.035,
            ),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.palette.blue,
                    context.palette.navy,
                  ],
                ),
                borderRadius:
                BorderRadius.circular(16),
              ),
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Text(
                    '$dayNumber',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Text(
                    'DAY',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: context.palette.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    body,
                    style: TextStyle(
                      color: context.palette.muted,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallbackItinerary(BuildContext context, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        text.isEmpty
            ? 'Your personalized itinerary will appear here.'
            : text,
        style: TextStyle(
          color: context.palette.muted,
          fontSize: 12,
          height: 1.55,
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM CTA
  // ============================================================

  Widget _buildBottomCta(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        18,
        25,
        18,
        0,
      ),
      child: Container(
        padding: const EdgeInsets.all(19),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              context.palette.blue,
              context.palette.navy,
            ],
          ),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            const Text(
              'Ready to explore? ✈️',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              'Your Tripora journey is ready.',
              style: TextStyle(
                color: Colors.white.withValues(
                  alpha: 0.78,
                ),
                fontSize: 11,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 49,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.palette.surface,
                  foregroundColor: context.palette.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'Plan Another Trip',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
