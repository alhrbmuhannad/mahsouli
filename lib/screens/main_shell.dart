import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../state/nav_controller.dart';
import '../theme/app_theme.dart';
import 'account_screen.dart';
import 'home_screen.dart';
import 'recipes_screen.dart';
import 'saved_screen.dart';
import 'search_screen.dart';

/// Bottom-navigation shell. Each tab keeps its own navigator so the bar stays
/// visible on detail pages, exactly like the design.
class MainShell extends StatelessWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context) =>
      ChangeNotifierProvider(create: (_) => NavController(), child: const _ShellBody());
}

class _ShellBody extends StatefulWidget {
  const _ShellBody();

  @override
  State<_ShellBody> createState() => _ShellBodyState();
}

class _ShellBodyState extends State<_ShellBody> {
  final _keys = List.generate(5, (_) => GlobalKey<NavigatorState>());
  int _lastReselect = 0;
  int _lastIndex = 0;

  static const _roots = <Widget>[HomeScreen(), SearchScreen(), RecipesScreen(), SavedScreen(), AccountScreen()];

  @override
  Widget build(BuildContext context) {
    final nav = context.watch<NavController>();
    // Re-tapping the active tab (or switching tabs from code) pops it to its root.
    if (nav.reselect != _lastReselect) {
      _lastReselect = nav.reselect;
      WidgetsBinding.instance.addPostFrameCallback((_) => _keys[nav.index].currentState?.popUntil((r) => r.isFirst));
    } else if (nav.index != _lastIndex && (nav.index == 1 || nav.index == 2)) {
      // When jumping to search / recipes with a preset, show the list itself.
      final i = nav.index;
      if (nav.pendingFilter != null || nav.pendingQuery != null || nav.focusSearch || nav.pendingRecipeMethod != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _keys[i].currentState?.popUntil((r) => r.isFirst));
      }
    }
    _lastIndex = nav.index;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final current = _keys[nav.index].currentState;
        if (current != null && current.canPop()) {
          current.pop();
        } else if (nav.index != 0) {
          nav.goTo(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: nav.index,
          children: List.generate(
            5,
            (i) => HeroControllerScope.none(
              child: Navigator(
                key: _keys[i],
                onGenerateRoute: (settings) => MaterialPageRoute(settings: settings, builder: (_) => _roots[i]),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _BottomBar(index: nav.index, onTap: nav.goTo),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;
  const _BottomBar({required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.home_outlined, Icons.home_rounded, 'nav_home'),
      (Icons.search_rounded, Icons.search_rounded, 'nav_search'),
      (Icons.menu_book_outlined, Icons.menu_book_rounded, 'nav_recipes'),
      (Icons.bookmark_border_rounded, Icons.bookmark_rounded, 'nav_saved'),
      (Icons.person_outline_rounded, Icons.person_rounded, 'nav_account'),
    ];
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: List.generate(items.length, (i) {
              final sel = i == index;
              final it = items[i];
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  child: Semantics(
                    selected: sel,
                    button: true,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          height: 30,
                          decoration: BoxDecoration(
                            color: sel ? AppColors.peach : Colors.transparent,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Icon(sel ? it.$2 : it.$1, color: sel ? AppColors.brown : AppColors.muted),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          context.tr(it.$3),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                            color: sel ? AppColors.brown : AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
