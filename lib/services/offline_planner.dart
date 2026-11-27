import '../data/destinations.dart';

/// Builds a simple day-by-day plan WITHOUT AI, used only when the AI service
/// is unavailable and the user chooses this option. The text starts with a
/// clear label so it is never mistaken for an AI-generated itinerary.
class OfflinePlanner {
  OfflinePlanner._();

  static const String label =
      'OFFLINE SAMPLE PLAN (not AI-generated: the AI service was unavailable)';

  static String build({
    required String destination,
    required String budget,
    required int days,
    required String interest,
  }) {
    final match = DestinationCatalog.matchName(destination);
    final places = <String>[
      ...?match?.highlights,
      'the old town and main market',
      'a local museum or heritage site',
      'a scenic viewpoint',
      'a guided walking tour',
      'a nearby day-trip spot',
    ];

    String place(int i) => places[i % places.length];

    final interestNote = switch (interest.toLowerCase()) {
      'adventure' => 'an outdoor or adventure activity',
      'beach' => 'time at the beach or waterfront',
      'shopping' => 'browsing local markets and handicraft shops',
      'nature' => 'a nature walk or park visit',
      _ => 'a cultural performance or heritage walk',
    };

    final perDay = switch (budget.toLowerCase()) {
      'low' || 'budget' => 2500,
      'luxury' || 'high' => 12000,
      _ => 5500,
    };

    final buffer = StringBuffer()
      ..writeln(label)
      ..writeln()
      ..writeln('Destination: $destination')
      ..writeln('Budget: $budget · Interest: $interest · $days days')
      ..writeln();

    for (var d = 1; d <= days; d++) {
      buffer
        ..writeln('Day $d')
        ..writeln(d == 1
            ? 'Morning: Arrive in $destination and check in.'
            : 'Morning: Visit ${place(d * 2 - 2)}.')
        ..writeln('Afternoon: Explore ${place(d * 2 - 1)}.')
        ..writeln(d == days
            ? 'Evening: Pack up and prepare for departure.'
            : 'Evening: Enjoy $interestNote.')
        ..writeln();
    }

    buffer
      ..writeln('Estimated Total Trip Expense:')
      ..writeln('- Roughly ₹${perDay * days} per person for stay, local '
          'transport and entry tickets (rough sample estimate).');
    if (match != null) buffer.writeln('- Best time to visit: ${match.bestTime}');

    return buffer.toString();
  }
}
