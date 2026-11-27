import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../data/local_food.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/dish_photo.dart';
import '../widgets/image_detail_dialog.dart';

/// Which dishes to show.
enum DietFilter { all, vegetarian, nonVegetarian }

/// Keeps the dishes that match [filter], in their original order.
List<LocalDish> filterDishes(List<LocalDish> dishes, DietFilter filter) {
  return switch (filter) {
    DietFilter.all => dishes,
    DietFilter.vegetarian => dishes.where((d) => d.vegetarian).toList(),
    DietFilter.nonVegetarian => dishes.where((d) => !d.vegetarian).toList(),
  };
}

/// Local food for one destination. Only destinations with a food guide can
/// be chosen here, and the list always comes from [FoodCatalog].
class FoodExplorerPage extends StatefulWidget {
  final String destinationId;

  const FoodExplorerPage({super.key, required this.destinationId});

  @override
  State<FoodExplorerPage> createState() => _FoodExplorerPageState();
}

class _FoodExplorerPageState extends State<FoodExplorerPage> {
  late String _destinationId = widget.destinationId;
  DietFilter _filter = DietFilter.all;

  @override
  Widget build(BuildContext context) {
    final destination = DestinationCatalog.byId(_destinationId);
    final dishes = FoodCatalog.forDestination(_destinationId);
    final visible = filterDishes(dishes, _filter);
    final name = destination?.name ?? _destinationId;

    return Scaffold(
      backgroundColor: context.palette.background,
      appBar: AppBar(title: const Text('Local food')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 30),
            children: [
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (final id in FoodCatalog.destinationIds)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          key: Key('food-destination-$id'),
                          label: Text(DestinationCatalog.byId(id)?.name ?? id),
                          selected: _destinationId == id,
                          onSelected: (_) => setState(() => _destinationId = id),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Dishes to try in $name',
                style: TextStyle(
                  color: context.palette.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'General information about well-known local dishes.',
                style: TextStyle(color: context.palette.muted, fontSize: 13),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _filterChip(DietFilter.all, 'All dishes'),
                  _filterChip(DietFilter.vegetarian, 'Vegetarian'),
                  _filterChip(DietFilter.nonVegetarian, 'Non-vegetarian'),
                ],
              ),
              const SizedBox(height: 14),
              if (visible.isEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No dishes match this filter for this destination.',
                    style: TextStyle(color: context.palette.muted),
                  ),
                )
              else
                for (final dish in visible) ...[
                  _DishCard(dish: dish, destinationName: name),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: context.palette.surfaceTint,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Vegetarian travellers: look for dishes marked Vegetarian. '
                  'Many dishes have vegetarian versions, so ask the restaurant. '
                  'Dishes are general information, not a restaurant listing. '
                  'Check menus locally for availability and prices.',
                  style: TextStyle(color: context.palette.text, fontSize: 12.5, height: 1.45),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(DietFilter filter, String label) {
    return ChoiceChip(
      key: Key('food-filter-${filter.name}'),
      label: Text(label),
      selected: _filter == filter,
      onSelected: (_) => setState(() => _filter = filter),
    );
  }
}

class _DishCard extends StatelessWidget {
  final LocalDish dish;
  final String destinationName;

  const _DishCard({required this.dish, required this.destinationName});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final veg = dish.vegetarian;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
        boxShadow: AppColors.softShadow(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (dish.hasPhoto)
            InkWell(
              key: Key('food-photo-${dish.name}'),
              onTap: () => showImageDetailDialog(
                context,
                image: ColoredBox(
                  color: Colors.black,
                  child: Image.asset(dish.image!, fit: BoxFit.contain, semanticLabel: dish.name),
                ),
                title: dish.name,
                details: [
                  ('Destination', destinationName),
                  ('Type', dish.vegetarian ? 'Vegetarian' : 'Non-vegetarian'),
                  ('Kind', dish.category),
                  ('About', dish.description),
                ],
                footer: 'Photo: ${dish.credit!.author} · ${dish.credit!.licence} · Wikimedia Commons',
              ),
              child: DishPhoto(asset: dish.image!, label: dish.name),
            )
          else
            SizedBox(
              key: Key('food-placeholder-${dish.name}'),
              height: 180,
              child: DishPhotoFallback(label: dish.name),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    TagChip(
                      label: destinationName,
                      color: palette.blue,
                      icon: Icons.location_on_rounded,
                    ),
                    TagChip(
                      label: veg ? 'Vegetarian' : 'Non-vegetarian',
                      color: veg ? palette.green : palette.coral,
                      icon: veg ? Icons.eco_rounded : Icons.restaurant_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  dish.name,
                  style: TextStyle(
                    color: palette.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  dish.category,
                  style: TextStyle(
                    color: palette.teal,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dish.description,
                  style: TextStyle(color: palette.muted, fontSize: 13.5, height: 1.45),
                ),
                const SizedBox(height: 10),
                Text(
                  dish.hasPhoto
                      ? 'Photo: ${dish.credit!.author} · ${dish.credit!.licence} · Wikimedia Commons'
                      : 'Placeholder: no verified photo for this dish yet.',
                  key: Key('food-credit-${dish.name}'),
                  style: TextStyle(color: palette.muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
