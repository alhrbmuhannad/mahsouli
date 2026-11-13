import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../state/nav_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'browse_screens.dart';
import 'notifications_screen.dart';
import 'rewards_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nav = context.read<NavController>();
    final hour = DateTime.now().hour;
    final greetingKey = hour < 12 ? 'good_morning' : 'good_evening';
    final user = state.user;

    final popular = [...Catalog.coffees]
      ..sort((a, b) => state.coffeeRating(b).avg.compareTo(state.coffeeRating(a).avg));
    final newArrivals = Catalog.coffees.where((c) => c.isNew).toList();
    final recipes = state.allRecipes.where((r) => !r.isCustom).toList();
    final dayIndex = DateTime.now().difference(DateTime(2026)).inDays;
    final recipeOfDay = recipes[dayIndex % recipes.length];

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user == null
                            ? context.tr(greetingKey)
                            : context.tr('${greetingKey}_name', {'name': ltr(user.name.split(' ').first)}),
                        style: const TextStyle(fontSize: 14, color: AppColors.muted, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        context.tr('home_title'),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, height: 1.3),
                      ),
                    ],
                  ),
                ),
                _NotificationBell(count: state.unreadCount),
                const SizedBox(width: 8),
                InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => nav.goTo(4),
                  child: Semantics(
                    label: context.tr('nav_account'),
                    child: Avatar(text: user?.initial ?? context.tr('guest_initial')),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Material(
              color: AppColors.cream,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border, width: 1.5),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => nav.openSearch(focus: true),
                child: SizedBox(
                  height: 52,
                  child: Row(
                    children: [
                      const SizedBox(width: 16),
                      const Icon(Icons.search_rounded, color: AppColors.muted),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          context.tr('search_hint_home'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.muted, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const _OffersCarousel(),
            const SizedBox(height: 20),
            SectionTitle(context.tr('browse_by')),
            const SizedBox(height: 8),
            Row(
              children: [
                _BrowseItem(
                  icon: Icons.grain_rounded,
                  label: context.tr('bean_types'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const BeanTypesScreen())),
                ),
                _BrowseItem(
                  icon: Icons.storefront_outlined,
                  label: context.tr('roasters'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RoastersScreen())),
                ),
                _BrowseItem(
                  icon: Icons.public_rounded,
                  label: context.tr('origins'),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const OriginsScreen())),
                ),
                _BrowseItem(
                  icon: Icons.menu_book_rounded,
                  label: context.tr('nav_recipes'),
                  onTap: () => nav.openRecipes(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SectionTitle(
              context.tr('popular_coffee'),
              action: context.tr('see_all'),
              onAction: () => nav.openSearch(filter: SearchFilter(sort: SortBy.rating)),
            ),
            for (final c in popular.take(3)) ...[CoffeeCard(coffee: c), const SizedBox(height: 12)],
            const SizedBox(height: 8),
            SectionTitle(
              context.tr('new_arrivals'),
              action: context.tr('see_all'),
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CoffeeListScreen(title: context.tr('new_arrivals'), coffees: newArrivals),
                ),
              ),
            ),
            SizedBox(
              height: 226,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: newArrivals.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (_, i) => CoffeeTile(coffee: newArrivals[i]),
              ),
            ),
            const SizedBox(height: 20),
            SectionTitle(context.tr('recipe_of_day')),
            const SizedBox(height: 4),
            RecipeCard(recipe: recipeOfDay),
            const SizedBox(height: 20),
            _BrewTipCard(index: dayIndex),
          ],
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  final int count;
  const _NotificationBell({required this.count});

  @override
  Widget build(BuildContext context) => Container(
    width: 48,
    height: 48,
    decoration: BoxDecoration(
      color: AppColors.cream,
      shape: BoxShape.circle,
      border: Border.all(color: AppColors.border, width: 1.5),
    ),
    child: IconButton(
      tooltip: context.tr('notifications'),
      onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const NotificationsScreen())),
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(context.number(count)),
        backgroundColor: AppColors.danger,
        child: const Icon(Icons.notifications_none_rounded),
      ),
    ),
  );
}

class _BrowseItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _BrowseItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(18)),
              child: Icon(icon, size: 26),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ),
  );
}

class _OffersCarousel extends StatefulWidget {
  const _OffersCarousel();

  @override
  State<_OffersCarousel> createState() => _OffersCarouselState();
}

class _OffersCarouselState extends State<_OffersCarousel> {
  final _controller = PageController(viewportFraction: 0.92);
  Timer? _timer;
  int _page = 0;

  List<Offer> get _offers => Catalog.offers.where((o) => !o.isExpired).toList();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!_controller.hasClients || _offers.isEmpty) return;
      final next = (_page + 1) % _offers.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 450), curve: Curves.easeOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final offers = _offers;
    return Column(
      children: [
        SizedBox(
          height: 128,
          child: PageView.builder(
            controller: _controller,
            padEnds: false,
            itemCount: offers.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (context, i) {
              final o = offers[i];
              return Padding(
                padding: const EdgeInsetsDirectional.only(end: 10),
                child: Material(
                  color: i.isEven ? AppColors.brown : AppColors.peach,
                  borderRadius: BorderRadius.circular(22),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(22),
                    onTap: () =>
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (_) => RewardsScreen(highlightOfferId: o.id))),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DefaultTextStyle.merge(
                        style: TextStyle(color: i.isEven ? AppColors.white : AppColors.brown),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    o.isReward
                                        ? context.tr('reward_points', {'n': o.pointsCost})
                                        : Catalog.roaster(o.roasterId).name.of(context),
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    o.title.of(context),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                                  ),
                                  Text(
                                    o.description.of(context),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: i.isEven ? AppColors.peach : AppColors.brown,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: o.discount > 0
                                  ? Text(
                                      context.digits('${o.discount}%'),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 17,
                                        color: i.isEven ? AppColors.brown : AppColors.white,
                                      ),
                                    )
                                  : Icon(
                                      Icons.card_giftcard_rounded,
                                      color: i.isEven ? AppColors.brown : AppColors.white,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            offers.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _page ? AppColors.brown : AppColors.inputBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BrewTipCard extends StatelessWidget {
  final int index;
  const _BrewTipCard({required this.index});

  @override
  Widget build(BuildContext context) {
    final tip = context.tr('tip_${index % 5 + 1}');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline_rounded, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('brew_tip'), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(tip, style: const TextStyle(fontSize: 14, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
