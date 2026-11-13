import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../state/nav_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'add_recipe_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final _query = TextEditingController();
  BrewMethod? _method;
  bool _myOnly = false;
  NavController? _nav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<NavController>();
    if (_nav != nav) {
      _nav?.removeListener(_onNav);
      _nav = nav..addListener(_onNav);
    }
  }

  void _onNav() {
    final nav = _nav!;
    if (nav.index != 2) return;
    if (nav.pendingRecipeMethod != null) {
      setState(() => _method = nav.pendingRecipeMethod);
      nav.pendingRecipeMethod = null;
    }
  }

  @override
  void dispose() {
    _nav?.removeListener(_onNav);
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final q = normalizeSearch(_query.text);
    final list = state.allRecipes.where((r) {
      if (_method != null && r.method != _method) return false;
      if (_myOnly && r.authorEmail != state.user?.email) return false;
      if (q.isNotEmpty &&
          !(r.title.matches(q) ||
              r.subtitle.matches(q) ||
              normalizeSearch(r.author).contains(q) ||
              normalizeSearch(methodLabel(context, r.method)).contains(q))) {
        return false;
      }
      return true;
    }).toList()..sort((a, b) => state.recipeRating(b).avg.compareTo(state.recipeRating(a).avg));

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_recipe',
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('add_recipe')),
        onPressed: () async {
          if (!await requireLogin(context) || !context.mounted) return;
          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddRecipeScreen()));
        },
      ),
      body: SafeArea(
        bottom: false,
        child: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 100),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PageHeader(title: context.tr('nav_recipes'), subtitle: context.tr('recipes_subtitle')),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _query,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: context.tr('search_recipes'),
                      prefixIcon: const Icon(Icons.search_rounded),
                      fillColor: AppColors.cream,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.brown, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  ChoicePill(
                    label: context.tr('all'),
                    selected: _method == null && !_myOnly,
                    onTap: () => setState(() {
                      _method = null;
                      _myOnly = false;
                    }),
                  ),
                  if (state.myRecipes.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    ChoicePill(
                      label: context.tr('my_recipes'),
                      selected: _myOnly,
                      onTap: () => setState(() => _myOnly = !_myOnly),
                    ),
                  ],
                  for (final m in BrewMethod.values) ...[
                    const SizedBox(width: 8),
                    ChoicePill(
                      label: methodLabel(context, m),
                      selected: _method == m,
                      onTap: () => setState(() => _method = _method == m ? null : m),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionTitle(
                    _method == null && q.isEmpty
                        ? context.tr('popular_recipes')
                        : context.tr('n_results', {'n': list.length}),
                  ),
                  const SizedBox(height: 8),
                  if (list.isEmpty)
                    EmptyState(
                      icon: Icons.menu_book_outlined,
                      title: context.tr('no_recipes'),
                      message: context.tr('no_recipes_msg'),
                    ),
                  for (final r in list) ...[RecipeCard(recipe: r), const SizedBox(height: 12)],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
