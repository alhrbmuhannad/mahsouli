import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Generic list of coffees with a title (used by roaster / origin / type pages).
class CoffeeListScreen extends StatelessWidget {
  final String title;
  final List<Coffee> coffees;
  final Widget? header;
  const CoffeeListScreen({super.key, required this.title, required this.coffees, this.header});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        if (header != null) ...[header!, const SizedBox(height: 16)],
        Text(
          context.tr('n_results', {'n': coffees.length}),
          style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.muted),
        ),
        const SizedBox(height: 8),
        if (coffees.isEmpty) EmptyState(icon: Icons.search_off_rounded, title: context.tr('no_results')),
        for (final c in coffees) ...[CoffeeCard(coffee: c, showOrigin: true), const SizedBox(height: 12)],
      ],
    ),
  );
}

class RoastersScreen extends StatelessWidget {
  const RoastersScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('roasters'))),
    body: ListView.separated(
      padding: const EdgeInsets.all(24),
      itemCount: Catalog.roasters.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final r = Catalog.roasters[i];
        final count = Catalog.coffees.where((c) => c.roasterId == r.id).length;
        return AppCard(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => RoasterDetailScreen(roaster: r))),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.storefront_rounded, size: 30),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name.of(context), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(r.city.of(context), style: const TextStyle(color: AppColors.muted)),
                    Text(context.tr('n_products', {'n': count}), style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        );
      },
    ),
  );
}

class RoasterDetailScreen extends StatelessWidget {
  final Roaster roaster;
  const RoasterDetailScreen({super.key, required this.roaster});

  @override
  Widget build(BuildContext context) {
    final coffees = Catalog.coffees.where((c) => c.roasterId == roaster.id).toList();
    final offers = Catalog.offers.where((o) => o.roasterId == roaster.id && !o.isExpired).toList();
    return CoffeeListScreen(
      title: roaster.name.of(context),
      coffees: coffees,
      header: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),
                const SizedBox(width: 4),
                Text(roaster.city.of(context), style: const TextStyle(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(context.tr('since_x', {'y': roaster.since}), style: const TextStyle(color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 8),
            Text(roaster.about.of(context), style: const TextStyle(height: 1.5)),
            if (offers.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final o in offers)
                    Pill(text: o.title.of(context), icon: Icons.local_offer_outlined, filled: true),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class OriginsScreen extends StatelessWidget {
  const OriginsScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(context.tr('origins'))),
    body: GridView.builder(
      padding: const EdgeInsets.all(24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.05,
      ),
      itemCount: Catalog.origins.length,
      itemBuilder: (context, i) {
        final o = Catalog.origins[i];
        final coffees = Catalog.coffees.where((c) => c.originId == o.id).toList();
        return AppCard(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CoffeeListScreen(
                title: o.name.of(context),
                coffees: coffees,
                header: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Text(o.flag, style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(o.about.of(context), style: const TextStyle(height: 1.5))),
                    ],
                  ),
                ),
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(o.flag, style: const TextStyle(fontSize: 34)),
              const Spacer(),
              Text(o.name.of(context), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
              Text(
                context.tr('n_products', {'n': coffees.length}),
                style: const TextStyle(fontSize: 13, color: AppColors.muted),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Browse by roast level and processing method.
class BeanTypesScreen extends StatelessWidget {
  const BeanTypesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    void open(String title, List<Coffee> list) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CoffeeListScreen(title: title, coffees: list),
      ),
    );

    Widget tile(String title, String desc, Color color, List<Coffee> list) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: () => open(title, list),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
              alignment: Alignment.center,
              child: const BeanIcon(size: 30),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                  Text(desc, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                ],
              ),
            ),
            Text(context.number(list.length), style: const TextStyle(fontWeight: FontWeight.w800)),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('bean_types'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          SectionTitle(context.tr('roast_level')),
          const SizedBox(height: 4),
          for (final r in RoastLevel.values)
            tile(
              roastLabel(context, r),
              context.tr('roast_${r.name}_desc'),
              roastColor(r),
              Catalog.coffees.where((c) => c.roast == r).toList(),
            ),
          const SizedBox(height: 8),
          SectionTitle(context.tr('process')),
          const SizedBox(height: 4),
          for (final p in ProcessType.values)
            tile(
              processLabel(context, p),
              context.tr('process_${p.name}_desc'),
              AppColors.cream,
              Catalog.coffees.where((c) => c.process == p).toList(),
            ),
        ],
      ),
    );
  }
}
