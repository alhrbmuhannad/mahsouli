import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../state/nav_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'help_screen.dart';
import 'my_activity_screens.dart';
import 'notifications_screen.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  void _push(BuildContext context, Widget page) => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final nav = context.read<NavController>();
    final user = state.user;
    final favCount = state.data.favCoffees.length;
    final savedRecipes = state.data.favRecipes.length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            PageHeader(title: context.tr('nav_account'), subtitle: context.tr('account_subtitle')),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(24)),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: AppColors.brown, shape: BoxShape.circle),
                    child: Text(
                      user?.initial ?? context.tr('guest_initial'),
                      style: const TextStyle(color: AppColors.peach, fontSize: 28, fontWeight: FontWeight.w800),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? context.tr('guest'),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          user != null ? context.tr('member') : context.tr('guest_browsing'),
                          style: const TextStyle(fontSize: 13),
                        ),
                        if (user != null)
                          Text(
                            user.email,
                            textDirection: TextDirection.ltr,
                            style: const TextStyle(fontSize: 13, color: AppColors.muted),
                          ),
                      ],
                    ),
                  ),
                  if (user != null)
                    IconButton(
                      tooltip: context.tr('edit_profile'),
                      onPressed: () => _push(context, const EditProfileScreen()),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                ],
              ),
            ),
            if (user == null) ...[
              const SizedBox(height: 12),
              FilledButton(onPressed: () => signOut(context), child: Text(context.tr('login_or_register'))),
            ],
            const SizedBox(height: 12),
            Material(
              color: AppColors.brown,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _push(context, const RewardsScreen()),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: AppColors.peach, size: 36),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(context.tr('my_points'), style: const TextStyle(color: AppColors.peach, fontSize: 13)),
                            Text(
                              context.tr('points_n', {'n': state.points}),
                              style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        context.tr('offers_rewards'),
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: AppColors.white),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SectionTitle(context.tr('my_activity')),
            const SizedBox(height: 4),
            MenuRow(
              icon: Icons.star_outline_rounded,
              title: context.tr('my_ratings'),
              subtitle: context.tr('n_reviews', {'n': state.myReviews.length}),
              onTap: () async {
                if (await requireLogin(context) && context.mounted) _push(context, const MyReviewsScreen());
              },
            ),
            const SizedBox(height: 10),
            MenuRow(
              icon: Icons.menu_book_outlined,
              title: context.tr('my_recipes'),
              subtitle: context.tr('my_recipes_sub', {'a': state.myRecipes.length, 'b': savedRecipes}),
              onTap: () async {
                if (await requireLogin(context) && context.mounted) _push(context, const MyRecipesScreen());
              },
            ),
            const SizedBox(height: 10),
            MenuRow(
              icon: Icons.favorite_border_rounded,
              title: context.tr('my_favorites'),
              subtitle: context.tr('n_saved_coffee', {'n': favCount}),
              onTap: () => nav.goTo(3),
            ),
            const SizedBox(height: 20),
            SectionTitle(context.tr('more')),
            const SizedBox(height: 4),
            MenuRow(
              icon: Icons.notifications_none_rounded,
              title: context.tr('notifications'),
              trailing: state.unreadCount > 0
                  ? Badge(label: Text(context.number(state.unreadCount)), backgroundColor: AppColors.danger)
                  : null,
              onTap: () => _push(context, const NotificationsScreen()),
            ),
            const SizedBox(height: 10),
            MenuRow(
              icon: Icons.settings_outlined,
              title: context.tr('settings'),
              onTap: () => _push(context, const SettingsScreen()),
            ),
            const SizedBox(height: 10),
            MenuRow(
              icon: Icons.help_outline_rounded,
              title: context.tr('help_support'),
              onTap: () => _push(context, const HelpScreen()),
            ),
            const SizedBox(height: 10),
            MenuRow(
              icon: Icons.info_outline_rounded,
              title: context.tr('about_app'),
              onTap: () => _push(context, const AboutScreen()),
            ),
            const SizedBox(height: 10),
            MenuRow(
              icon: Icons.logout_rounded,
              title: context.tr(user == null ? 'exit_guest' : 'logout'),
              color: AppColors.danger,
              trailing: const SizedBox.shrink(),
              onTap: () async {
                if (user == null) {
                  signOut(context);
                  return;
                }
                final ok = await confirmDialog(
                  context,
                  title: context.tr('logout'),
                  message: context.tr('logout_msg'),
                  confirm: context.tr('logout'),
                );
                if (ok && context.mounted) signOut(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
