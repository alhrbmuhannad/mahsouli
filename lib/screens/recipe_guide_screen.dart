import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'brew_timer_screen.dart';
import 'reviews_screen.dart';

/// "دليل التحضير" – recipe details, brew calculator, steps and rating.
class RecipeGuideScreen extends StatefulWidget {
  final String recipeId;
  final Coffee? coffee;
  const RecipeGuideScreen({super.key, required this.recipeId, this.coffee});

  @override
  State<RecipeGuideScreen> createState() => _RecipeGuideScreenState();
}

class _RecipeGuideScreenState extends State<RecipeGuideScreen> {
  int _cups = 1;
  int _strength = 0; // -1 light, 0 standard, +1 strong

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final r = state.recipe(widget.recipeId);
    if (r == null) {
      return Scaffold(
        appBar: AppBar(),
        body: EmptyState(icon: Icons.menu_book_outlined, title: context.tr('recipe_not_found')),
      );
    }
    final coffee = widget.coffee ?? Catalog.coffee(r.coffeeId);
    final rating = state.recipeRating(r);
    final saved = state.isFavRecipe(r.id);
    final myReview = state.myReviewFor(ReviewTarget.recipe, r.id);

    // Brew calculator.
    final factor = _cups.toDouble();
    final water = (r.water * factor).round();
    final ice = (r.ice * factor).round();
    final strengthMul = 1 + _strength * 0.1;
    final dose = r.coffee * factor * strengthMul;
    final ratio = (water + ice) / dose;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('brew_guide')),
        actions: [
          IconButton(
            tooltip: context.tr(saved ? 'remove_favorite' : 'save_recipe'),
            icon: Icon(saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded),
            onPressed: () {
              final added = state.toggleFavRecipe(r.id);
              showSnack(context, context.tr(added ? 'added_to_saved' : 'removed_from_saved'));
            },
          ),
          if (r.isCustom && r.authorEmail == state.user?.email)
            IconButton(
              tooltip: context.tr('delete'),
              icon: const Icon(Icons.delete_outline_rounded),
              onPressed: () async {
                final ok = await confirmDialog(
                  context,
                  title: context.tr('delete_recipe'),
                  message: context.tr('delete_recipe_msg'),
                  confirm: context.tr('delete'),
                  danger: true,
                );
                if (ok && context.mounted) {
                  Navigator.pop(context);
                  state.deleteRecipe(r.id);
                }
              },
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(24)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (coffee != null)
                  InkWell(
                    onTap: () => openCoffee(context, coffee),
                    child: Text(
                      '${coffee.name.of(context)} - ${methodLabel(context, r.method)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
                  Text(
                    methodLabel(context, r.method),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                const SizedBox(height: 2),
                Text(r.title.of(context), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                Text(
                  '${r.subtitle.of(context)} - ${difficultyLabel(context, r.difficulty)}',
                  style: const TextStyle(fontSize: 15),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (rating.count > 0) ...[
                      RatingLine(value: rating.avg, count: rating.count, long: false, fontSize: 14),
                      const SizedBox(width: 14),
                    ],
                    const Icon(Icons.schedule_rounded, size: 18),
                    const SizedBox(width: 4),
                    Text(durationLabel(context, r.minutes), style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
                const Divider(height: 24, color: AppColors.brown, thickness: 0.3),
                Row(
                  children: [
                    Avatar(text: r.author[0].toUpperCase(), size: 36, fontSize: 16),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('recipe_author'), style: const TextStyle(fontSize: 12)),
                        Text(ltr('@${r.author}'), style: const TextStyle(fontWeight: FontWeight.w800)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ---------------------------------------------------- calculator
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 1.5),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.tr('brew_calculator'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                      ),
                    ),
                    Text(
                      context.tr('ratio_x', {'r': context.digits('1:${ratio.toStringAsFixed(1)}')}),
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: Text(context.tr('cups'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                    _RoundButton(
                      icon: Icons.remove_rounded,
                      onTap: _cups > 1 ? () => setState(() => _cups--) : null,
                      tooltip: context.tr('decrease'),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        context.number(_cups),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                      ),
                    ),
                    _RoundButton(
                      icon: Icons.add_rounded,
                      onTap: _cups < 6 ? () => setState(() => _cups++) : null,
                      tooltip: context.tr('increase'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(context.tr('strength'), style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    selectedBackgroundColor: AppColors.brown,
                    selectedForegroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.inputBorder),
                  ),
                  segments: [
                    ButtonSegment(value: -1, label: Text(context.tr('strength_light'))),
                    ButtonSegment(value: 0, label: Text(context.tr('strength_standard'))),
                    ButtonSegment(value: 1, label: Text(context.tr('strength_strong'))),
                  ],
                  selected: {_strength},
                  onSelectionChanged: (s) => setState(() => _strength = s.first),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            children: [
              InfoTile(
                icon: Icons.water_drop_outlined,
                label: context.tr('water'),
                value: context.tr('ml_n', {'n': water}),
              ),
              InfoTile(
                icon: Icons.scale_outlined,
                label: context.tr('coffee'),
                value: context.tr('g_n', {'n': context.digits(fmtGrams(double.parse(dose.toStringAsFixed(1))))}),
              ),
              InfoTile(icon: Icons.grain_rounded, label: context.tr('grind_size'), value: r.grind.of(context)),
              InfoTile(
                icon: Icons.thermostat_rounded,
                label: context.tr('water_temp'),
                value: context.tr('celsius', {'v': context.digits(r.temp)}),
              ),
              if (ice > 0)
                InfoTile(
                  icon: Icons.ac_unit_rounded,
                  label: context.tr('ice'),
                  value: context.tr('g_n', {'n': context.number(ice)}),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SectionTitle(context.tr('steps')),
          const SizedBox(height: 4),
          for (var i = 0; i < r.steps.length; i++)
            _StepTile(index: i, step: r.steps[i], factor: factor, last: i == r.steps.length - 1),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(context.tr('start_brewing')),
            onPressed: () => Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => BrewTimerScreen(recipe: r, factor: factor),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Text(context.tr('how_was_recipe'), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(context.tr('rating_label'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    for (var n = 1; n <= 5; n++)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Material(
                          color: (myReview?.rating ?? 0) >= n ? AppColors.brown : AppColors.white,
                          shape: const CircleBorder(side: BorderSide(color: AppColors.inputBorder, width: 1.5)),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => showReviewSheet(context, ReviewTarget.recipe, r.id, initialRating: n),
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: Text(
                                  context.number(n),
                                  semanticsLabel: context.tr('n_of_5', {'n': n}),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: (myReview?.rating ?? 0) >= n ? AppColors.white : AppColors.brown,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          ReviewsScreen(target: ReviewTarget.recipe, targetId: r.id, title: r.title.of(context)),
                    ),
                  ),
                  child: Text(context.tr('see_reviews_n', {'n': rating.count})),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String tooltip;
  const _RoundButton({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) => IconButton.filled(
    tooltip: tooltip,
    style: IconButton.styleFrom(
      backgroundColor: AppColors.peach,
      foregroundColor: AppColors.brown,
      disabledBackgroundColor: AppColors.cream,
    ),
    onPressed: onTap,
    icon: Icon(icon),
  );
}

class _StepTile extends StatelessWidget {
  final int index;
  final BrewStep step;
  final double factor;
  final bool last;
  const _StepTile({required this.index, required this.step, required this.factor, required this.last});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.brown, shape: BoxShape.circle),
                child: Text(
                  context.number(index + 1),
                  style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w800),
                ),
              ),
              if (!last) Expanded(child: Container(width: 2, color: AppColors.border)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(step.text.of(context), style: const TextStyle(fontSize: 15, height: 1.5)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      Pill(text: secondsLabel(context, step.seconds), icon: Icons.timer_outlined),
                      if (step.pourTo != null)
                        Pill(
                          text: context.tr('pour_to', {'n': (step.pourTo! * factor).round()}),
                          icon: Icons.water_drop_outlined,
                          filled: true,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
