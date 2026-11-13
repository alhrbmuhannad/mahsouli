import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../state/nav_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nav = context.read<NavController>();
    final coffees = state.favoriteCoffees;
    final recipes = state.favoriteRecipes;

    Widget tab(int i, String label, int count) => Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = i),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _tab == i ? AppColors.brown : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            '$label (${context.number(count)})',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: _tab == i ? AppColors.white : AppColors.brown,
            ),
          ),
        ),
      ),
    );

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            PageHeader(title: context.tr('nav_saved'), subtitle: context.tr('saved_subtitle')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(18)),
              child: Row(
                children: [
                  tab(0, context.tr('bean_types'), coffees.length),
                  tab(1, context.tr('nav_recipes'), recipes.length),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (_tab == 0) ...[
              if (coffees.isEmpty)
                EmptyState(
                  icon: Icons.favorite_border_rounded,
                  title: context.tr('no_saved_coffee'),
                  message: context.tr('no_saved_coffee_msg'),
                  action: context.tr('explore_coffee'),
                  onAction: () => nav.openSearch(),
                ),
              for (final c in coffees) ...[CoffeeCard(coffee: c, showFavorite: true), const SizedBox(height: 12)],
            ] else ...[
              if (recipes.isEmpty)
                EmptyState(
                  icon: Icons.bookmark_border_rounded,
                  title: context.tr('no_saved_recipes'),
                  message: context.tr('no_saved_recipes_msg'),
                  action: context.tr('explore_recipes'),
                  onAction: () => nav.openRecipes(),
                ),
              for (final r in recipes) ...[RecipeCard(recipe: r), const SizedBox(height: 12)],
            ],
          ],
        ),
      ),
    );
  }
}
