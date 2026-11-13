import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../state/nav_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _query = TextEditingController();
  final _focus = FocusNode();
  SearchFilter _filter = SearchFilter();
  NavController? _nav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nav = context.read<NavController>();
    if (_nav != nav) {
      _nav?.removeListener(_onNav);
      _nav = nav..addListener(_onNav);
      _onNav();
    }
  }

  void _onNav() {
    final nav = _nav!;
    if (nav.index != 1) return;
    var changed = false;
    if (nav.pendingFilter != null) {
      _filter = nav.pendingFilter!;
      nav.pendingFilter = null;
      changed = true;
    }
    if (nav.pendingQuery != null) {
      _query.text = nav.pendingQuery!;
      nav.pendingQuery = null;
      changed = true;
    }
    if (nav.focusSearch) {
      nav.focusSearch = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focus.requestFocus();
      });
    }
    if (changed && mounted) setState(() {});
  }

  @override
  void dispose() {
    _nav?.removeListener(_onNav);
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<SearchFilter>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      builder: (_) => FilterSheet(initial: _filter.copy(), query: _query.text),
    );
    if (result != null) setState(() => _filter = result);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final results = _filter.apply(_query.text, state);
    final showRecent = _query.text.isEmpty && state.data.recentSearches.isNotEmpty;

    String chipLabel(String key, int count) =>
        count > 0 ? '${context.tr(key)} (${context.number(count)})' : context.tr(key);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              sliver: SliverList.list(
                children: [
                  PageHeader(title: context.tr('search_title'), subtitle: context.tr('search_subtitle')),
                  const SizedBox(height: 16),
                  Container(
                    height: 52,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.cream,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.brown, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _query,
                            focusNode: _focus,
                            textInputAction: TextInputAction.search,
                            onChanged: (_) => setState(() {}),
                            onSubmitted: state.addRecentSearch,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: context.tr('search_subtitle'),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_query.text.isNotEmpty)
                          IconButton(
                            tooltip: context.tr('clear'),
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(_query.clear),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    ChoicePill(
                      label: chipLabel('filters', _filter.activeCount),
                      selected: _filter.activeCount > 0,
                      trailing: Icons.tune_rounded,
                      onTap: _openFilters,
                    ),
                    const SizedBox(width: 8),
                    ChoicePill(
                      label: chipLabel('origin', _filter.origins.length),
                      selected: _filter.origins.isNotEmpty,
                      trailing: Icons.keyboard_arrow_down_rounded,
                      onTap: _openFilters,
                    ),
                    const SizedBox(width: 8),
                    ChoicePill(
                      label: chipLabel('roast', _filter.roasts.length),
                      selected: _filter.roasts.isNotEmpty,
                      trailing: Icons.keyboard_arrow_down_rounded,
                      onTap: _openFilters,
                    ),
                    const SizedBox(width: 8),
                    ChoicePill(
                      label: context.tr('price'),
                      selected: _filter.priceActive,
                      trailing: Icons.keyboard_arrow_down_rounded,
                      onTap: _openFilters,
                    ),
                    const SizedBox(width: 8),
                    ChoicePill(
                      label: chipLabel('brew_method', _filter.methods.length),
                      selected: _filter.methods.isNotEmpty,
                      trailing: Icons.keyboard_arrow_down_rounded,
                      onTap: _openFilters,
                    ),
                    const SizedBox(width: 8),
                    ChoicePill(
                      label: chipLabel('roaster', _filter.roasters.length),
                      selected: _filter.roasters.isNotEmpty,
                      trailing: Icons.keyboard_arrow_down_rounded,
                      onTap: _openFilters,
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              sliver: SliverList.list(
                children: [
                  if (showRecent) ...[
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr('recent_searches'),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        TextButton(onPressed: state.clearRecentSearches, child: Text(context.tr('clear'))),
                      ],
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final r in state.data.recentSearches)
                          ActionChip(
                            avatar: const Icon(Icons.history_rounded, size: 16),
                            label: Text(r),
                            backgroundColor: AppColors.cream,
                            side: const BorderSide(color: AppColors.border),
                            onPressed: () => setState(() => _query.text = r),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          context.tr('n_results', {'n': results.length}),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.muted),
                        ),
                      ),
                      PopupMenuButton<SortBy>(
                        tooltip: context.tr('sort_by'),
                        initialValue: _filter.sort,
                        onSelected: (s) => setState(() => _filter.sort = s),
                        itemBuilder: (_) => [
                          for (final s in SortBy.values)
                            PopupMenuItem(value: s, child: Text(context.tr('sort_${s.name}'))),
                        ],
                        child: Row(
                          children: [
                            const Icon(Icons.sort_rounded, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              context.tr('sort_${_filter.sort.name}'),
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (results.isEmpty)
                    EmptyState(
                      icon: Icons.search_off_rounded,
                      title: context.tr('no_results'),
                      message: context.tr('no_results_msg'),
                      action: _filter.activeCount > 0 ? context.tr('reset_filters') : null,
                      onAction: () => setState(() => _filter = SearchFilter()),
                    ),
                  for (final c in results) ...[CoffeeCard(coffee: c, showOrigin: true), const SizedBox(height: 12)],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FilterSheet extends StatefulWidget {
  final SearchFilter initial;
  final String query;
  const FilterSheet({super.key, required this.initial, required this.query});

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late SearchFilter f = widget.initial;

  Widget _section(String title, List<Widget> chips) => Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    ),
  );

  Widget _chip<T>(String label, Set<T> set, T value) => FilterChip(
    label: Text(label),
    selected: set.contains(value),
    showCheckmark: false,
    selectedColor: AppColors.brown,
    backgroundColor: AppColors.white,
    labelStyle: TextStyle(
      fontFamily: 'Tajawal',
      fontWeight: FontWeight.w700,
      color: set.contains(value) ? AppColors.white : AppColors.brown,
    ),
    side: BorderSide(color: set.contains(value) ? AppColors.brown : AppColors.inputBorder, width: 1.5),
    shape: const StadiumBorder(),
    onSelected: (v) => setState(() => v ? set.add(value) : set.remove(value)),
  );

  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final count = f.apply(widget.query, state).length;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (context, scroll) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(context.tr('filters'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                ),
                TextButton(
                  onPressed: () => setState(() => f = SearchFilter(sort: f.sort)),
                  child: Text(context.tr('reset')),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                _section(context.tr('sort_by'), [
                  for (final s in SortBy.values)
                    ChoiceChip(
                      label: Text(context.tr('sort_${s.name}')),
                      selected: f.sort == s,
                      showCheckmark: false,
                      selectedColor: AppColors.peach,
                      side: const BorderSide(color: AppColors.inputBorder),
                      onSelected: (_) => setState(() => f.sort = s),
                    ),
                ]),
                _section(context.tr('origin'), [
                  for (final o in Catalog.origins) _chip('${o.flag} ${o.name.of(context)}', f.origins, o.id),
                ]),
                _section(context.tr('roast_level'), [
                  for (final r in RoastLevel.values) _chip(roastLabel(context, r), f.roasts, r),
                ]),
                _section(context.tr('roaster'), [
                  for (final r in Catalog.roasters) _chip(r.name.of(context), f.roasters, r.id),
                ]),
                _section(context.tr('brew_method'), [
                  for (final m in BrewMethod.values) _chip(methodLabel(context, m), f.methods, m),
                ]),
                _section(context.tr('process'), [
                  for (final p in ProcessType.values) _chip(processLabel(context, p), f.processes, p),
                ]),
                Text(context.tr('price_range'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                RangeSlider(
                  values: f.price,
                  min: 0,
                  max: SearchFilter.maxPrice,
                  divisions: 40,
                  labels: RangeLabels(context.price(f.price.start.round()), context.price(f.price.end.round())),
                  onChanged: (v) => setState(() => f.price = v),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [Text(context.price(f.price.start.round())), Text(context.price(f.price.end.round()))],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.tr('in_stock_only'), style: const TextStyle(fontWeight: FontWeight.w700)),
                  value: f.inStockOnly,
                  onChanged: (v) => setState(() => f.inStockOnly = v),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: FilledButton(
                onPressed: () => Navigator.pop(context, f),
                child: Text(context.tr('show_n_results', {'n': count})),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
