import 'package:flutter/material.dart';

import '../data/destinations.dart';
import '../models/saved_trip.dart' show formatDate;
import '../models/travel_experience.dart';
import '../services/app_firebase.dart';
import '../services/experience_store.dart';
import '../theme/theme.dart';
import '../widgets/common.dart';
import '../widgets/destination_image.dart';
import 'experience_editor_page.dart';

/// Shows [rating] as five stars, with the number after them.
class StarRow extends StatelessWidget {
  final int rating;
  final double size;

  const StarRow({super.key, required this.rating, this.size = 18});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: palette.orange,
          ),
        const SizedBox(width: 6),
        Text(
          '$rating/5',
          style: TextStyle(
            color: palette.text,
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// One experience in a list: photo from the destination catalogue, title,
/// rating, author and date, with a short extract of the story.
class ExperienceCard extends StatelessWidget {
  final TravelExperience experience;
  final VoidCallback onTap;

  const ExperienceCard({
    super.key,
    required this.experience,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final destination = DestinationCatalog.byId(experience.destinationId);
    return Material(
      color: palette.surface,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: Key('experience-card-${experience.id}'),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 150,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  DestinationImage(
                    url: destination?.imageUrl,
                    label: experience.destinationName,
                  ),
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: TagChip(
                      label: experience.destinationName,
                      color: Colors.white,
                      icon: Icons.location_on_rounded,
                      onDark: true,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    experience.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: palette.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StarRow(rating: experience.rating, size: 16),
                  const SizedBox(height: 6),
                  Text(
                    '${experience.authorName} · '
                    '${formatDate(experience.publishedAt)}',
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    experience.story,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: palette.text, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Text shown above the feed and on "My experiences", so people know where
/// the records are kept.
class DeviceOnlyNotice extends StatelessWidget {
  const DeviceOnlyNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      key: const Key('experience-device-notice'),
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: palette.surfaceTint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.phone_android_rounded, color: palette.blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Saved on this device only. Other travellers, the admin and your '
              'other devices cannot see these yet, and they are not backed up.',
              style: TextStyle(color: palette.text, fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Every experience saved on this device, with filters by destination and by
/// rating.
class ExperienceFeedPage extends StatefulWidget {
  const ExperienceFeedPage({super.key});

  @override
  State<ExperienceFeedPage> createState() => _ExperienceFeedPageState();
}

class _ExperienceFeedPageState extends State<ExperienceFeedPage> {
  final ExperienceStore _store = ExperienceStore.instance;
  String? _destinationId;
  int _minRating = 0;
  bool _topRated = false;

  @override
  void initState() {
    super.initState();
    _store.load();
  }

  List<TravelExperience> _visible(List<TravelExperience> all) {
    final list = all
        .where(
          (e) =>
              (_destinationId == null || e.destinationId == _destinationId) &&
              e.rating >= _minRating,
        )
        .toList();
    if (_topRated) {
      list.sort((a, b) {
        final byRating = b.rating.compareTo(a.rating);
        return byRating != 0 ? byRating : b.publishedAt.compareTo(a.publishedAt);
      });
    }
    return list;
  }

  void _write() => SafeNav.push(context, const ExperienceEditorPage());

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(title: const Text('Travel experiences')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('experience-write'),
        onPressed: _write,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Write experience'),
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          if (!_store.isLoaded) {
            return const LoadingState(message: 'Loading experiences…');
          }
          if (_store.readFailed) {
            return const EmptyState(
              icon: Icons.lock_clock_outlined,
              title: 'Saved experiences could not be read',
              message: 'New experiences are blocked so the saved ones are not '
                  'overwritten. Restart the app to try again.',
            );
          }
          final all = _store.all;
          final visible = _visible(all);
          final destinations = <String, String>{
            for (final e in all) e.destinationId: e.destinationName,
          };
          final ids = destinations.keys.toList()
            ..sort((a, b) => destinations[a]!.compareTo(destinations[b]!));

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                children: [
                  const DeviceOnlyNotice(),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        key: const Key('feed-filter-all'),
                        label: const Text('All destinations'),
                        selected: _destinationId == null,
                        onSelected: (_) => setState(() => _destinationId = null),
                      ),
                      for (final id in ids)
                        ChoiceChip(
                          key: Key('feed-filter-$id'),
                          label: Text(destinations[id]!),
                          selected: _destinationId == id,
                          onSelected: (_) => setState(() => _destinationId = id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        key: const Key('feed-rating-any'),
                        label: const Text('Any rating'),
                        selected: _minRating == 0,
                        onSelected: (_) => setState(() => _minRating = 0),
                      ),
                      ChoiceChip(
                        key: const Key('feed-rating-3'),
                        label: const Text('3 stars & up'),
                        selected: _minRating == 3,
                        onSelected: (_) => setState(() => _minRating = 3),
                      ),
                      ChoiceChip(
                        key: const Key('feed-rating-4'),
                        label: const Text('4 stars & up'),
                        selected: _minRating == 4,
                        onSelected: (_) => setState(() => _minRating = 4),
                      ),
                      FilterChip(
                        key: const Key('feed-sort-top'),
                        label: const Text('Top rated first'),
                        selected: _topRated,
                        onSelected: (v) => setState(() => _topRated = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (all.isEmpty)
                    EmptyState(
                      icon: Icons.auto_stories_rounded,
                      title: 'No experiences yet',
                      message: 'Write about a trip you have taken. Your '
                          'experiences appear here with the destination photo.',
                      actionLabel: 'Write an experience',
                      onAction: _write,
                    )
                  else if (visible.isEmpty)
                    const EmptyState(
                      icon: Icons.filter_alt_off_rounded,
                      title: 'Nothing matches these filters',
                      message: 'Try another destination or a lower rating.',
                    )
                  else
                    for (final experience in visible) ...[
                      ExperienceCard(
                        experience: experience,
                        onTap: () => SafeNav.push(
                          context,
                          ExperienceDetailPage(experienceId: experience.id),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The full experience. Only its author sees the edit and delete actions.
class ExperienceDetailPage extends StatelessWidget {
  final String experienceId;

  const ExperienceDetailPage({super.key, required this.experienceId});

  Future<void> _delete(BuildContext context, TravelExperience experience) async {
    final uid = AppFirebase.auth.currentUser?.uid ?? '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this experience?'),
        content: const Text('It will be removed from this device. This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            key: const Key('experience-delete-confirm'),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await ExperienceStore.instance.delete(uid: uid, id: experience.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      showAppMessage(context, 'Experience deleted.');
    } catch (e) {
      if (context.mounted) showAppMessage(context, '$e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListenableBuilder(
      listenable: ExperienceStore.instance,
      builder: (context, _) {
        final experience = ExperienceStore.instance.byId(experienceId);
        if (experience == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(
              icon: Icons.delete_outline_rounded,
              title: 'Experience removed',
              message: 'This experience is no longer on this device.',
            ),
          );
        }
        final uid = AppFirebase.auth.currentUser?.uid ?? '';
        final isAuthor = experience.isOwnedBy(uid);
        final destination = DestinationCatalog.byId(experience.destinationId);
        final edited = experience.updatedAt.difference(experience.publishedAt).inMinutes > 0;

        return Scaffold(
          backgroundColor: palette.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                foregroundColor: Colors.white,
                backgroundColor: palette.navy,
                actions: [
                  if (isAuthor) ...[
                    IconButton(
                      key: const Key('experience-edit'),
                      tooltip: 'Edit experience',
                      icon: const Icon(Icons.edit_rounded),
                      onPressed: () => SafeNav.push(
                        context,
                        ExperienceEditorPage(existing: experience),
                      ),
                    ),
                    IconButton(
                      key: const Key('experience-delete'),
                      tooltip: 'Delete experience',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () => _delete(context, experience),
                    ),
                  ],
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: DestinationImage(
                    url: destination?.imageUrl,
                    label: experience.destinationName,
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      experience.title,
                      style: TextStyle(
                        color: palette.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        TagChip(
                          label: experience.destinationName,
                          color: palette.blue,
                          icon: Icons.location_on_rounded,
                        ),
                        StarRow(rating: experience.rating),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${isAuthor ? 'Written by you' : 'By ${experience.authorName}'}'
                      ' · Published ${formatDate(experience.publishedAt)}'
                      '${edited ? ' · Edited ${formatDate(experience.updatedAt)}' : ''}',
                      style: TextStyle(color: palette.muted, fontSize: 12.5),
                    ),
                    const SizedBox(height: 18),
                    _Section(title: 'The trip', body: experience.story),
                    if (experience.tips.isNotEmpty)
                      _Section(title: 'Travel tips', body: experience.tips),
                    if (experience.highlights.isNotEmpty)
                      _Section(
                        title: 'Highlights',
                        children: [
                          for (final item in experience.highlights)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 18, color: palette.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: TextStyle(color: palette.text, height: 1.4),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String? body;
  final List<Widget>? children;

  const _Section({required this.title, this.body, this.children});

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          if (body != null)
            Text(body!, style: TextStyle(color: palette.text, height: 1.5)),
          ...?children,
        ],
      ),
    );
  }
}

/// The signed-in traveller's own experiences.
class MyExperiencesPage extends StatefulWidget {
  const MyExperiencesPage({super.key});

  @override
  State<MyExperiencesPage> createState() => _MyExperiencesPageState();
}

class _MyExperiencesPageState extends State<MyExperiencesPage> {
  @override
  void initState() {
    super.initState();
    ExperienceStore.instance.load();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final uid = AppFirebase.auth.currentUser?.uid;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        title: const Text('My travel experiences'),
        actions: [
          IconButton(
            tooltip: 'Browse all experiences',
            icon: const Icon(Icons.explore_rounded),
            onPressed: () => SafeNav.push(context, const ExperienceFeedPage()),
          ),
        ],
      ),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton.extended(
              key: const Key('my-experience-write'),
              onPressed: () => SafeNav.push(context, const ExperienceEditorPage()),
              icon: const Icon(Icons.edit_rounded),
              label: const Text('Write experience'),
            ),
      body: uid == null
          ? const EmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to see your experiences',
              message: 'Experiences you write are linked to your account.',
            )
          : ListenableBuilder(
              listenable: ExperienceStore.instance,
              builder: (context, _) {
                if (!ExperienceStore.instance.isLoaded) {
                  return const LoadingState(message: 'Loading your experiences…');
                }
                final mine = ExperienceStore.instance.byAuthor(uid);
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(18, 14, 18, 110),
                      children: [
                        const DeviceOnlyNotice(),
                        const SizedBox(height: 14),
                        if (mine.isEmpty)
                          EmptyState(
                            icon: Icons.auto_stories_rounded,
                            title: 'You have not written an experience yet',
                            message: 'Share what you saw, ate and learned on a '
                                'trip. Only you can edit or delete it.',
                            actionLabel: 'Write an experience',
                            onAction: () => SafeNav.push(
                              context,
                              const ExperienceEditorPage(),
                            ),
                          )
                        else
                          for (final experience in mine) ...[
                            ExperienceCard(
                              experience: experience,
                              onTap: () => SafeNav.push(
                                context,
                                ExperienceDetailPage(experienceId: experience.id),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
