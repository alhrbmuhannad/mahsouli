import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    (icon: Icons.travel_explore_rounded, title: 'onb1_title', body: 'onb1_body'),
    (icon: Icons.menu_book_rounded, title: 'onb2_title', body: 'onb2_body'),
    (icon: Icons.card_giftcard_rounded, title: 'onb3_title', body: 'onb3_body'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            children: [
              Row(
                children: [
                  const BrandLogo(size: 40),
                  const SizedBox(width: 10),
                  Text(context.tr('app_name'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const Spacer(),
                  _LangToggle(current: state.locale.languageCode, onChanged: state.setLocale),
                ],
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _pages.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final p = _pages[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          height: 200,
                          decoration: const BoxDecoration(color: AppColors.peach, shape: BoxShape.circle),
                          child: Icon(p.icon, size: 96),
                        ),
                        const SizedBox(height: 36),
                        Text(
                          context.tr(p.title),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.tr(p.body),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, color: AppColors.muted, height: 1.5),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _page ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _page ? AppColors.brown : AppColors.inputBorder,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () {
                  if (last) {
                    state.completeOnboarding();
                  } else {
                    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  }
                },
                child: Text(context.tr(last ? 'get_started' : 'next')),
              ),
              TextButton(
                onPressed: last ? null : state.completeOnboarding,
                child: Text(last ? '' : context.tr('skip')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangToggle extends StatelessWidget {
  final String current;
  final ValueChanged<String> onChanged;
  const _LangToggle({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    Widget item(String code, String label) {
      final sel = current == code;
      return GestureDetector(
        onTap: () => onChanged(code),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: sel ? AppColors.brown : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            style: TextStyle(fontWeight: FontWeight.w700, color: sel ? AppColors.white : AppColors.brown),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(21)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [item('ar', 'عربي'), item('en', 'EN')]),
    );
  }
}

/// Re-usable language switch (used on login & settings too).
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return _LangToggle(current: state.locale.languageCode, onChanged: state.setLocale);
  }
}
