import 'package:flutter/material.dart';

import '../models/destination.dart';
import '../services/favourites_store.dart';
import '../theme/theme.dart';
import 'common.dart';

/// Heart button that adds or removes a destination from the signed-in user's
/// favourites. Tapping it only changes the favourite; it never opens a page.
class FavouriteButton extends StatelessWidget {
  final Destination destination;
  final double size;

  const FavouriteButton({
    super.key,
    required this.destination,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final store = FavouritesStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final liked = store.isFavourite(destination.id);
        final pending = store.isPending(destination.id);

        return Semantics(
          button: true,
          label: liked
              ? 'Remove ${destination.name} from favourites'
              : 'Add ${destination.name} to favourites',
          child: Material(
            color: Colors.white.withValues(alpha: 0.94),
            shape: const CircleBorder(),
            elevation: 2,
            shadowColor: Colors.black26,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: pending
                  ? null
                  : () async {
                      final error = await store.toggle(destination);
                      if (!context.mounted) return;
                      if (error != null) {
                        showAppMessage(context, error, error: true);
                      } else {
                        showAppMessage(
                          context,
                          store.isFavourite(destination.id)
                              ? '${destination.name} added to Favourites'
                              : '${destination.name} removed from Favourites',
                        );
                      }
                    },
              child: SizedBox(
                width: size,
                height: size,
                child: Center(
                  child: pending
                      ? SizedBox(
                          width: size * 0.42,
                          height: size * 0.42,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.palette.pink,
                          ),
                        )
                      : AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          transitionBuilder: (child, animation) =>
                              ScaleTransition(scale: animation, child: child),
                          child: Icon(
                            liked
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                            key: ValueKey(liked),
                            color: liked ? context.palette.pink : context.palette.text,
                            size: size * 0.52,
                          ),
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
