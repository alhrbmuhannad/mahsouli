import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ReviewsScreen extends StatelessWidget {
  final ReviewTarget target;
  final String targetId;
  final String title;
  const ReviewsScreen({super.key, required this.target, required this.targetId, required this.title});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final reviews = state.reviewsFor(target, targetId);
    final ({double avg, int count}) rating;
    if (target == ReviewTarget.coffee) {
      rating = state.coffeeRating(Catalog.coffee(targetId)!);
    } else {
      final r = state.recipe(targetId);
      rating = r == null ? (avg: 0.0, count: 0) : state.recipeRating(r);
    }
    final dist = List.filled(5, 0);
    for (final r in reviews) {
      dist[r.rating - 1]++;
    }
    final maxDist = dist.fold<int>(1, (m, v) => v > m ? v : m);
    final mine = state.myReviewFor(target, targetId);

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('reviews'))),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        onPressed: () => showReviewSheet(context, target, targetId),
        icon: const Icon(Icons.rate_review_outlined),
        label: Text(context.tr(mine == null ? 'write_review' : 'edit_review')),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        children: [
          Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                Column(
                  children: [
                    Text(context.rating(rating.avg), style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w800)),
                    StarRow(value: rating.avg),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('n_ratings', {'n': rating.count}),
                      style: const TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      for (var s = 5; s >= 1; s--)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Text(context.number(s), style: const TextStyle(fontSize: 12)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: dist[s - 1] / maxDist,
                                    minHeight: 8,
                                    color: AppColors.star,
                                    backgroundColor: AppColors.border,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (reviews.isEmpty)
            EmptyState(
              icon: Icons.chat_bubble_outline_rounded,
              title: context.tr('no_reviews_yet'),
              message: context.tr('be_first_review'),
            ),
          for (final r in reviews) ...[ReviewTile(review: r), const SizedBox(height: 10)],
        ],
      ),
    );
  }
}

class ReviewTile extends StatelessWidget {
  final Review review;
  final bool showTarget;
  const ReviewTile({super.key, required this.review, this.showTarget = false});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isMine = review.authorEmail != null && review.authorEmail == state.user?.email;
    String? targetName;
    if (showTarget) {
      targetName = review.target == ReviewTarget.coffee
          ? Catalog.coffee(review.targetId)?.name.of(context)
          : state.recipe(review.targetId)?.title.of(context);
    }
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: showTarget
          ? () {
              if (review.target == ReviewTarget.coffee) {
                final c = Catalog.coffee(review.targetId);
                if (c != null) openCoffee(context, c);
              } else {
                final r = state.recipe(review.targetId);
                if (r != null) openRecipe(context, r);
              }
            }
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (targetName != null) ...[
            Row(
              children: [
                Icon(review.target == ReviewTarget.coffee ? Icons.grain_rounded : Icons.menu_book_rounded, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(targetName, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          Row(
            children: [
              Avatar(
                text: review.authorName.isEmpty ? '?' : review.authorName[0].toUpperCase(),
                size: 34,
                fontSize: 15,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isMine ? context.tr('you') : review.authorName,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(context.timeAgo(review.date), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                  ],
                ),
              ),
              StarRow(value: review.rating.toDouble(), size: 15),
              if (isMine)
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (v) async {
                    if (v == 'edit') {
                      showReviewSheet(context, review.target, review.targetId);
                    } else {
                      final ok = await confirmDialog(
                        context,
                        title: context.tr('delete_review'),
                        message: context.tr('delete_review_msg'),
                        confirm: context.tr('delete'),
                        danger: true,
                      );
                      if (ok) state.deleteReview(review);
                    }
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(value: 'edit', child: Text(ctx.tr('edit'))),
                    PopupMenuItem(value: 'delete', child: Text(ctx.tr('delete'))),
                  ],
                ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(review.comment, style: const TextStyle(fontSize: 14, height: 1.5)),
          ],
        ],
      ),
    );
  }
}

/// Bottom sheet to add / edit the current user's review.
Future<void> showReviewSheet(BuildContext context, ReviewTarget target, String targetId, {int? initialRating}) async {
  if (!await requireLogin(context)) return;
  if (!context.mounted) return;
  final state = context.read<AppState>();
  final existing = state.myReviewFor(target, targetId);
  final earned = await showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    builder: (_) => _ReviewSheet(
      target: target,
      targetId: targetId,
      initialRating: initialRating ?? existing?.rating ?? 0,
      initialComment: existing?.comment ?? '',
    ),
  );
  if (earned == null || !context.mounted) return;
  showSnack(context, earned > 0 ? context.tr('review_thanks_points', {'n': earned}) : context.tr('review_updated'));
}

class _ReviewSheet extends StatefulWidget {
  final ReviewTarget target;
  final String targetId;
  final int initialRating;
  final String initialComment;
  const _ReviewSheet({
    required this.target,
    required this.targetId,
    required this.initialRating,
    required this.initialComment,
  });

  @override
  State<_ReviewSheet> createState() => _ReviewSheetState();
}

class _ReviewSheetState extends State<_ReviewSheet> {
  late int _rating = widget.initialRating;
  late final _comment = TextEditingController(text: widget.initialComment);

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.tr(widget.target == ReviewTarget.coffee ? 'rate_coffee' : 'rate_recipe'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          StarPicker(value: _rating, onChanged: (v) => setState(() => _rating = v)),
          if (_rating > 0)
            Text(
              context.tr('stars_$_rating'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _comment,
            maxLines: 4,
            maxLength: 300,
            decoration: InputDecoration(hintText: context.tr('review_hint')),
          ),
          const SizedBox(height: 8),
          FilledButton(
            onPressed: _rating == 0
                ? null
                : () {
                    final earned = context.read<AppState>().submitReview(
                      widget.target,
                      widget.targetId,
                      _rating,
                      _comment.text,
                    );
                    Navigator.pop(context, earned);
                  },
            child: Text(context.tr('submit_review')),
          ),
        ],
      ),
    );
  }
}
