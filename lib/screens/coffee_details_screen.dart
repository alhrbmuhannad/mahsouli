import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'browse_screens.dart';
import 'reviews_screen.dart';

class CoffeeDetailsScreen extends StatelessWidget {
  final Coffee coffee;
  const CoffeeDetailsScreen({super.key, required this.coffee});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final c = coffee;
    final roaster = Catalog.roaster(c.roasterId);
    final origin = Catalog.origin(c.originId);
    final rating = state.coffeeRating(c);
    final fav = state.isFavCoffee(c.id);
    final recipes = state.recipesForCoffee(c);
    final reviews = state.reviewsFor(ReviewTarget.coffee, c.id);
    final similar = Catalog.coffees
        .where((x) => x.id != c.id && (x.originId == c.originId || x.roast == c.roast))
        .take(6)
        .toList();
    final sep = context.isAr ? ' - ' : ' · ';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('coffee_details')),
        actions: [
          IconButton(
            tooltip: context.tr(fav ? 'remove_favorite' : 'add_favorite'),
            onPressed: () {
              final added = state.toggleFavCoffee(c.id);
              showSnack(context, context.tr(added ? 'added_to_saved' : 'removed_from_saved'));
            },
            icon: Icon(fav ? Icons.favorite_rounded : Icons.favorite_border_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          CoffeeThumb(coffee: c, width: double.infinity, height: 200, radius: 28),
          const SizedBox(height: 16),
          InkWell(
            onTap: () =>
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoasterDetailScreen(roaster: roaster))),
            child: Text(
              roaster.name.of(context),
              style: const TextStyle(fontSize: 14, color: AppColors.muted, decoration: TextDecoration.underline),
            ),
          ),
          Text(c.name.of(context), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Pill(text: processLabel(context, c.process)),
              Pill(text: context.tr('roast_x', {'r': roastLabel(context, c.roast)})),
              Pill(text: context.tr('weight_g', {'n': c.weight})),
              if (!c.inStock) Pill(text: context.tr('out_of_stock'), icon: Icons.inventory_2_outlined),
            ],
          ),
          const SizedBox(height: 12),
          InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReviewsScreen(target: ReviewTarget.coffee, targetId: c.id, title: c.name.of(context)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  StarRow(value: rating.avg),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${context.rating(rating.avg)} (${context.number(rating.count)}) · ${context.tr('reviews')}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(context.price(c.price), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Text(c.description.of(context), style: const TextStyle(fontSize: 15, height: 1.6)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                _InfoRow(label: context.tr('flavor_notes'), value: c.notes.map((n) => n.of(context)).join(sep)),
                const Divider(height: 20),
                _InfoRow(label: context.tr('origin'), value: '${origin.flag} ${c.region.of(context)}'),
                const Divider(height: 20),
                _InfoRow(label: context.tr('variety'), value: c.variety.of(context)),
                const Divider(height: 20),
                _InfoRow(
                  label: context.tr('altitude'),
                  value: context.tr('altitude_m', {'v': context.digits(c.altitude)}),
                ),
                const Divider(height: 20),
                _InfoRow(label: context.tr('process'), value: processLabel(context, c.process)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(context.tr('suits_methods'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in c.methods) Pill(text: methodLabel(context, m), filled: true, icon: methodIcon(m)),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _showSeller(context, c, roaster),
            icon: const Icon(Icons.storefront_outlined),
            label: Text(context.tr('visit_product_site')),
          ),
          const SizedBox(height: 20),
          if (recipes.isNotEmpty) ...[
            SectionTitle(context.tr('suggested_recipe')),
            _SuggestedRecipe(recipe: recipes.first, coffee: c),
            if (recipes.length > 1) ...[
              const SizedBox(height: 12),
              Text(context.tr('more_recipes'), style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              for (final r in recipes.skip(1).take(2)) ...[
                RecipeCard(recipe: r, coffee: c),
                const SizedBox(height: 10),
              ],
            ],
            const SizedBox(height: 12),
          ],
          SectionTitle(
            context.tr('reviews'),
            action: context.tr('see_all'),
            onAction: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReviewsScreen(target: ReviewTarget.coffee, targetId: c.id, title: c.name.of(context)),
              ),
            ),
          ),
          if (reviews.isEmpty) Text(context.tr('no_reviews_yet'), style: const TextStyle(color: AppColors.muted)),
          for (final r in reviews.take(2)) ...[ReviewTile(review: r), const SizedBox(height: 10)],
          OutlinedButton.icon(
            onPressed: () => showReviewSheet(context, ReviewTarget.coffee, c.id),
            icon: const Icon(Icons.rate_review_outlined),
            label: Text(
              context.tr(state.myReviewFor(ReviewTarget.coffee, c.id) == null ? 'write_review' : 'edit_review'),
            ),
          ),
          if (similar.isNotEmpty) ...[
            const SizedBox(height: 24),
            SectionTitle(context.tr('similar_coffee')),
            SizedBox(
              height: 226,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: similar.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => CoffeeTile(coffee: similar[i]),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSeller(BuildContext context, Coffee c, Roaster roaster) {
    final link = 'https://mahsouli.app/p/${c.id}';
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(ctx.tr('seller_info'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              InfoTile(icon: Icons.storefront_outlined, label: ctx.tr('roaster'), value: roaster.name.of(ctx)),
              const SizedBox(height: 8),
              InfoTile(icon: Icons.location_on_outlined, label: ctx.tr('city'), value: roaster.city.of(ctx)),
              const SizedBox(height: 8),
              InfoTile(
                icon: Icons.inventory_2_outlined,
                label: ctx.tr('availability'),
                value: ctx.tr(c.inStock ? 'in_stock' : 'out_of_stock'),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: link));
                  Navigator.pop(ctx);
                  showSnack(context, context.tr('link_copied'));
                },
                icon: const Icon(Icons.link_rounded),
                label: Text(ctx.tr('copy_product_link')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 110,
        child: Text(label, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
      ),
      Expanded(
        child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    ],
  );
}

class _SuggestedRecipe extends StatelessWidget {
  final Recipe recipe;
  final Coffee coffee;
  const _SuggestedRecipe({required this.recipe, required this.coffee});

  @override
  Widget build(BuildContext context) {
    final rating = context.watch<AppState>().recipeRating(recipe);
    return Material(
      color: AppColors.peach,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => openRecipe(context, recipe, coffee: coffee),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('suggested_recipe'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(
                '${context.tr('coffee_g', {'n': fmtGrams(recipe.coffee)})} / ${context.tr('water_ml', {'n': recipe.water})} - ${methodLabel(context, recipe.method)}',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Avatar(text: recipe.author[0].toUpperCase(), size: 28, fontSize: 13),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      context.tr('by_author', {'a': ltr('@${recipe.author}')}),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  if (rating.count > 0) RatingLine(value: rating.avg, count: rating.count, long: false),
                  const SizedBox(width: 10),
                  Text(context.tr('view_recipe'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  const Icon(Icons.chevron_right_rounded, size: 18),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
