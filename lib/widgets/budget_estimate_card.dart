import 'package:flutter/material.dart';

import '../screens/travel_tools_page.dart' show formatRupees;
import '../services/travel_tools.dart';
import '../theme/theme.dart';
import 'common.dart';

/// Estimated cost breakdown for a trip, from the planner's budget tier.
///
/// Every figure is an estimate in Indian rupees per traveller. Nothing here
/// is a live price, and intercity transport is not included.
class BudgetEstimateCard extends StatelessWidget {
  final String budget;
  final int days;

  /// Travellers are shown per person, so the total is for one traveller.
  const BudgetEstimateCard({super.key, required this.budget, required this.days});

  @override
  Widget build(BuildContext context) {
    final tier = BudgetEstimate.tiers[budget] ?? BudgetEstimate.tiers['Moderate']!;
    final safeDays = days < 1 ? 1 : days;
    final result = tier.breakdown(days: safeDays);
    final nights = safeDays - 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: context.palette.border),
        boxShadow: AppColors.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  size: 20, color: context.palette.teal),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Estimated budget',
                  style: TextStyle(
                    color: context.palette.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              TagChip(label: 'ESTIMATE', color: context.palette.orange),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$budget budget · $safeDays ${safeDays == 1 ? 'day' : 'days'} · per traveller',
            style: TextStyle(color: context.palette.muted, fontSize: 12.5),
          ),
          const SizedBox(height: 12),
          _row(context, 'Accommodation ($nights ${nights == 1 ? 'night' : 'nights'})', result.stay),
          _row(context, 'Food', result.food),
          _row(context, 'Local travel', result.transport),
          _row(context, 'Attractions and activities', result.activities),
          _row(context, 'Buffer for extra costs (10%)', result.buffer),
          const Divider(height: 22),
          _row(context, 'Estimated total', result.total, strong: true),
          const SizedBox(height: 10),
          Text(
            'These are rough planning figures, not prices. Flights, trains and '
            'buses between cities are not included.',
            style: TextStyle(color: context.palette.muted, fontSize: 11.5, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, int amount, {bool strong = false}) {
    final style = TextStyle(
      color: context.palette.text,
      fontSize: strong ? 15 : 13.5,
      fontWeight: strong ? FontWeight.w900 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(formatRupees(amount), style: style),
        ],
      ),
    );
  }
}
