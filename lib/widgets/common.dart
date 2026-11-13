import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../screens/coffee_details_screen.dart';
import '../screens/recipe_guide_screen.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

// ------------------------------------------------------------------ labels
String roastLabel(BuildContext c, RoastLevel r) => c.tr('roast_${r.name}');
String processLabel(BuildContext c, ProcessType p) => c.tr('process_${p.name}');
String methodLabel(BuildContext c, BrewMethod m) => c.tr('method_${m.name}');
String difficultyLabel(BuildContext c, Difficulty d) => c.tr('diff_${d.name}');

String durationLabel(BuildContext c, int minutes) {
  if (minutes >= 60) {
    return c.tr('hours_n', {'n': (minutes / 60).round()});
  }
  return c.tr('minutes_n', {'n': minutes});
}

String secondsLabel(BuildContext c, int seconds) {
  if (seconds >= 3600) return c.tr('hours_n', {'n': (seconds / 3600).round()});
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return c.digits('$m:${s.toString().padLeft(2, '0')}');
}

Color roastColor(RoastLevel r) => switch (r) {
  RoastLevel.light => AppColors.roastLight,
  RoastLevel.medium => AppColors.roastMedium,
  RoastLevel.dark => AppColors.roastDark,
};

IconData methodIcon(BrewMethod m) => switch (m) {
  BrewMethod.v60 => Icons.filter_alt_outlined,
  BrewMethod.chemex => Icons.hourglass_bottom_rounded,
  BrewMethod.espresso => Icons.coffee_maker_outlined,
  BrewMethod.aeropress => Icons.compress_rounded,
  BrewMethod.frenchPress => Icons.local_cafe_outlined,
  BrewMethod.coldBrew => Icons.ac_unit_rounded,
  BrewMethod.moka => Icons.whatshot_outlined,
  BrewMethod.kalita => Icons.waves_rounded,
};

// --------------------------------------------------------------- bean icon
/// The coffee bean drawn in the design (rotated ellipse + centre crease).
class BeanIcon extends StatelessWidget {
  final double size;
  final Color color;
  final double strokeWidth;
  const BeanIcon({super.key, this.size = 40, this.color = AppColors.brown, this.strokeWidth = 1.8});

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _BeanPainter(color, strokeWidth));
}

class _BeanPainter extends CustomPainter {
  final Color color;
  final double stroke;
  _BeanPainter(this.color, this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.save();
    canvas.translate(12 * s, 12 * s);
    canvas.rotate(35 * math.pi / 180);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 12 * s, height: 18 * s), paint);
    canvas.restore();
    final path = Path()
      ..moveTo(9 * s, 7 * s)
      ..cubicTo(12 * s, 9 * s, 12 * s, 15 * s, 15 * s, 17 * s);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _BeanPainter old) => old.color != color || old.stroke != stroke;
}

class BrandLogo extends StatelessWidget {
  final double size;
  const BrandLogo({super.key, this.size = 72});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: AppColors.brown, borderRadius: BorderRadius.circular(size / 3)),
    alignment: Alignment.center,
    child: BeanIcon(size: size * 0.56, color: AppColors.peach),
  );
}

class CoffeeThumb extends StatelessWidget {
  final Coffee coffee;
  final double width;
  final double height;
  final double radius;
  const CoffeeThumb({super.key, required this.coffee, this.width = 92, this.height = 108, this.radius = 14});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: roastColor(coffee.roast), borderRadius: BorderRadius.circular(radius)),
      child: Stack(
        alignment: Alignment.center,
        children: [
          BeanIcon(size: math.min(width, height) * 0.5),
          PositionedDirectional(
            top: 6,
            start: 6,
            child: Text(
              Catalog.origin(coffee.originId).flag,
              style: TextStyle(fontSize: math.min(width, height) * 0.16),
            ),
          ),
          if (coffee.isNew)
            PositionedDirectional(
              bottom: 6,
              end: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.brown, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  context.tr('new_badge'),
                  style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------------------- ratings
class RatingLine extends StatelessWidget {
  final double value;
  final int? count;
  final bool long;
  final double fontSize;
  const RatingLine({super.key, required this.value, this.count, this.long = true, this.fontSize = 13});

  @override
  Widget build(BuildContext context) {
    final v = context.rating(value);
    final text = long ? context.tr('rating_of_5', {'v': v}) : (count == null ? v : '$v (${context.number(count!)})');
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: fontSize + 4, color: AppColors.star),
        const SizedBox(width: 3),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class StarRow extends StatelessWidget {
  final double value;
  final double size;
  const StarRow({super.key, required this.value, this.size = 16});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(5, (i) {
      final icon = value >= i + 1
          ? Icons.star_rounded
          : value > i
          ? Icons.star_half_rounded
          : Icons.star_outline_rounded;
      return Icon(icon, size: size, color: AppColors.star);
    }),
  );
}

class StarPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;
  const StarPicker({super.key, required this.value, required this.onChanged, this.size = 40});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(5, (i) {
      final n = i + 1;
      return IconButton(
        tooltip: context.tr('n_of_5', {'n': n}),
        onPressed: () => onChanged(n),
        icon: Icon(n <= value ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: AppColors.star),
      );
    }),
  );
}

// ------------------------------------------------------------------- cards
class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final Color color;
  final double radius;
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(12),
    this.color = AppColors.white,
    this.radius = 20,
  });

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: const BorderSide(color: AppColors.border, width: 1.5),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

void openCoffee(BuildContext context, Coffee c) =>
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => CoffeeDetailsScreen(coffee: c)));

void openRecipe(BuildContext context, Recipe r, {Coffee? coffee}) => Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => RecipeGuideScreen(recipeId: r.id, coffee: coffee),
  ),
);

class CoffeeCard extends StatelessWidget {
  final Coffee coffee;
  final bool showOrigin;
  final bool showFavorite;
  const CoffeeCard({super.key, required this.coffee, this.showOrigin = false, this.showFavorite = false});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rating = state.coffeeRating(coffee);
    final roaster = Catalog.roaster(coffee.roasterId);
    final origin = Catalog.origin(coffee.originId);
    final notes = coffee.notes.take(2).map((n) => n.of(context)).join(context.isAr ? '، ' : ', ');
    final details = [if (showOrigin) origin.name.of(context), roastLabel(context, coffee.roast), notes].join(' - ');
    return AppCard(
      onTap: () => openCoffee(context, coffee),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CoffeeThumb(coffee: coffee),
          const SizedBox(width: 14),
          Expanded(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 108),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          roaster.name.of(context),
                          style: const TextStyle(fontSize: 13, color: AppColors.muted),
                        ),
                      ),
                      if (showFavorite)
                        InkWell(
                          onTap: () => state.toggleFavCoffee(coffee.id),
                          child: Icon(
                            state.isFavCoffee(coffee.id) ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 20,
                            color: AppColors.brown,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    coffee.name.of(context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(details, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 2),
                  RatingLine(value: rating.avg),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        context.price(coffee.price),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr('visit_coffee_page'),
                          textAlign: TextAlign.end,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, size: 18),
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

/// Compact vertical coffee tile for horizontal lists.
class CoffeeTile extends StatelessWidget {
  final Coffee coffee;
  const CoffeeTile({super.key, required this.coffee});

  @override
  Widget build(BuildContext context) {
    final rating = context.watch<AppState>().coffeeRating(coffee);
    return SizedBox(
      width: 156,
      child: AppCard(
        padding: const EdgeInsets.all(10),
        onTap: () => openCoffee(context, coffee),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CoffeeThumb(coffee: coffee, width: double.infinity, height: 96),
            const SizedBox(height: 8),
            Text(
              Catalog.roaster(coffee.roasterId).name.of(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            Text(
              coffee.name.of(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Expanded(child: RatingLine(value: rating.avg, long: false, fontSize: 12)),
                Text(context.price(coffee.price), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;
  final Coffee? coffee;
  const RecipeCard({super.key, required this.recipe, this.coffee});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rating = state.recipeRating(recipe);
    final summary = [
      context.tr('coffee_g', {'n': _fmtG(recipe.coffee)}),
      context.tr('water_ml', {'n': recipe.water}),
      difficultyLabel(context, recipe.difficulty),
    ].join(' - ');
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: () => openRecipe(context, recipe, coffee: coffee),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Pill(text: methodLabel(context, recipe.method), filled: true),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recipe.title.of(context),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ),
              if (rating.count > 0) RatingLine(value: rating.avg, count: rating.count, long: false),
            ],
          ),
          const SizedBox(height: 8),
          Text(summary, style: const TextStyle(fontSize: 14)),
          const SizedBox(height: 10),
          Row(
            children: [
              Avatar(text: recipe.author.isEmpty ? '?' : recipe.author[0].toUpperCase(), size: 26, fontSize: 12),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: Text(
                  context.tr('by_author', {'a': ltr('@${recipe.author}')}),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
              const Icon(Icons.schedule_rounded, size: 16, color: AppColors.muted),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  durationLabel(context, recipe.minutes),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.muted),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  context.tr('open'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 18),
            ],
          ),
        ],
      ),
    );
  }
}

String _fmtG(double g) => g % 1 == 0 ? g.toInt().toString() : g.toStringAsFixed(1);
String fmtGrams(double g) => _fmtG(g);

// ------------------------------------------------------------ small pieces
class Pill extends StatelessWidget {
  final String text;
  final bool filled;
  final IconData? icon;
  const Pill({super.key, required this.text, this.filled = false, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: filled ? AppColors.peach : AppColors.cream,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[Icon(icon, size: 14), const SizedBox(width: 4)],
        Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    ),
  );
}

class ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? trailing;
  const ChoicePill({super.key, required this.label, required this.selected, required this.onTap, this.trailing});

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? AppColors.brown : AppColors.white,
    shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.brown : AppColors.inputBorder, width: 1.5)),
    child: InkWell(
      customBorder: const StadiumBorder(),
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.white : AppColors.brown,
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 4),
              Icon(trailing, size: 18, color: selected ? AppColors.white : AppColors.brown),
            ],
          ],
        ),
      ),
    ),
  );
}

class Avatar extends StatelessWidget {
  final String text;
  final double size;
  final double fontSize;
  const Avatar({super.key, required this.text, this.size = 48, this.fontSize = 20});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: const BoxDecoration(color: AppColors.peach, shape: BoxShape.circle),
    child: Text(
      text,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800),
    ),
  );
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const SectionTitle(this.title, {super.key, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const PageHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
            if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 14, color: AppColors.muted)),
          ],
        ),
      ),
      ?trailing,
    ],
  );
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? action;
  final VoidCallback? onAction;
  const EmptyState({super.key, required this.icon, required this.title, this.message, this.action, this.onAction});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(28)),
          child: Icon(icon, size: 40, color: AppColors.muted),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        if (message != null) ...[
          const SizedBox(height: 6),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: AppColors.muted),
          ),
        ],
        if (action != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: 220,
            child: FilledButton(onPressed: onAction, child: Text(action!)),
          ),
        ],
      ],
    ),
  );
}

class InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const InfoTile({super.key, required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(16)),
    child: Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? color;
  const MenuRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.color,
  });

  @override
  Widget build(BuildContext context) => AppCard(
    onTap: onTap,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    radius: 18,
    child: Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: color ?? AppColors.brown, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
              ),
              if (subtitle != null) Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
            ],
          ),
        ),
        trailing ?? const Icon(Icons.chevron_right_rounded),
      ],
    ),
  );
}

// ----------------------------------------------------------------- helpers
void showSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Shows a sign-in prompt for guests. Returns true when the user is logged in.
Future<bool> requireLogin(BuildContext context) async {
  final state = context.read<AppState>();
  if (state.isLoggedIn) return true;
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: const Icon(Icons.lock_outline_rounded, size: 36),
      title: Text(ctx.tr('login_required')),
      content: Text(ctx.tr('login_required_msg'), textAlign: TextAlign.center),
      actionsAlignment: MainAxisAlignment.center,
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(120, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ctx.tr('login')),
        ),
      ],
    ),
  );
  if (go == true && context.mounted) signOut(context);
  return false;
}

/// Ends the session (user or guest) and returns to the login screen.
void signOut(BuildContext context) {
  Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
  context.read<AppState>().logout();
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirm,
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.tr('cancel'))),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(100, 44),
            backgroundColor: danger ? AppColors.danger : AppColors.brown,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return r == true;
}
