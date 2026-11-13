import 'package:flutter/material.dart';

import '../data/catalog.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import 'app_state.dart';

enum SortBy { rating, priceLow, priceHigh, newest }

class SearchFilter {
  Set<String> roasters;
  Set<String> origins;
  Set<RoastLevel> roasts;
  Set<BrewMethod> methods;
  Set<ProcessType> processes;
  RangeValues price;
  bool inStockOnly;
  SortBy sort;

  static const maxPrice = 200.0;

  SearchFilter({
    Set<String>? roasters,
    Set<String>? origins,
    Set<RoastLevel>? roasts,
    Set<BrewMethod>? methods,
    Set<ProcessType>? processes,
    this.price = const RangeValues(0, maxPrice),
    this.inStockOnly = false,
    this.sort = SortBy.rating,
  }) : roasters = roasters ?? {},
       origins = origins ?? {},
       roasts = roasts ?? {},
       methods = methods ?? {},
       processes = processes ?? {};

  SearchFilter copy() => SearchFilter(
    roasters: {...roasters},
    origins: {...origins},
    roasts: {...roasts},
    methods: {...methods},
    processes: {...processes},
    price: price,
    inStockOnly: inStockOnly,
    sort: sort,
  );

  bool get priceActive => price.start > 0 || price.end < maxPrice;

  int get activeCount =>
      roasters.length +
      origins.length +
      roasts.length +
      methods.length +
      processes.length +
      (priceActive ? 1 : 0) +
      (inStockOnly ? 1 : 0);

  List<Coffee> apply(String query, AppState state) {
    final q = normalizeSearch(query);
    final out = Catalog.coffees.where((c) {
      if (q.isNotEmpty) {
        final roaster = Catalog.roaster(c.roasterId);
        final origin = Catalog.origin(c.originId);
        final hit =
            c.name.matches(q) ||
            roaster.name.matches(q) ||
            origin.name.matches(q) ||
            c.region.matches(q) ||
            c.notes.any((n) => n.matches(q));
        if (!hit) return false;
      }
      if (roasters.isNotEmpty && !roasters.contains(c.roasterId)) return false;
      if (origins.isNotEmpty && !origins.contains(c.originId)) return false;
      if (roasts.isNotEmpty && !roasts.contains(c.roast)) return false;
      if (processes.isNotEmpty && !processes.contains(c.process)) return false;
      if (methods.isNotEmpty && !c.methods.any(methods.contains)) return false;
      if (c.price < price.start || c.price > price.end) return false;
      if (inStockOnly && !c.inStock) return false;
      return true;
    }).toList();
    switch (sort) {
      case SortBy.rating:
        out.sort((a, b) => state.coffeeRating(b).avg.compareTo(state.coffeeRating(a).avg));
      case SortBy.priceLow:
        out.sort((a, b) => a.price.compareTo(b.price));
      case SortBy.priceHigh:
        out.sort((a, b) => b.price.compareTo(a.price));
      case SortBy.newest:
        out.sort((a, b) => (b.isNew ? 1 : 0).compareTo(a.isNew ? 1 : 0));
    }
    return out;
  }
}

/// Lets any screen switch the bottom-navigation tab (and pre-set a search).
class NavController extends ChangeNotifier {
  int index = 0;
  SearchFilter? pendingFilter;
  String? pendingQuery;
  bool focusSearch = false;
  BrewMethod? pendingRecipeMethod;

  /// Incremented whenever a tab is re-selected, so it can pop to root.
  int reselect = 0;

  void goTo(int i) {
    if (i == index) {
      reselect++;
    }
    index = i;
    notifyListeners();
  }

  void openSearch({SearchFilter? filter, String? query, bool focus = false}) {
    pendingFilter = filter;
    pendingQuery = query;
    focusSearch = focus;
    index = 1;
    notifyListeners();
  }

  void openRecipes({BrewMethod? method}) {
    pendingRecipeMethod = method;
    index = 2;
    notifyListeners();
  }
}
