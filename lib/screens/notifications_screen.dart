import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  IconData _icon(NotificationType t) => switch (t) {
    NotificationType.newProduct => Icons.new_releases_outlined,
    NotificationType.offer => Icons.local_offer_outlined,
    NotificationType.reward => Icons.stars_rounded,
    NotificationType.system => Icons.info_outline_rounded,
  };

  void _open(BuildContext context, AppNotification n) {
    context.read<AppState>().markRead(n.id);
    final coffee = Catalog.coffee(n.targetId);
    if (coffee != null) {
      openCoffee(context, coffee);
      return;
    }
    if (n.type == NotificationType.offer || n.type == NotificationType.reward) {
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => RewardsScreen(highlightOfferId: n.targetId)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final list = state.notifications;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('notifications')),
        actions: [
          IconButton(
            tooltip: context.tr('notification_settings'),
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: list.isEmpty
          ? Center(
              child: EmptyState(icon: Icons.notifications_off_outlined, title: context.tr('no_notifications')),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                if (state.unreadCount > 0)
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: state.markAllRead,
                      icon: const Icon(Icons.done_all_rounded),
                      label: Text(context.tr('mark_all_read')),
                    ),
                  ),
                for (final n in list) ...[
                  AppCard(
                    color: state.isRead(n.id) ? AppColors.white : AppColors.cream,
                    onTap: () => _open(context, n),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(14)),
                          child: Icon(_icon(n.type)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                n.title.of(context),
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 2),
                              Text(n.body.of(context), style: const TextStyle(fontSize: 14, height: 1.4)),
                              const SizedBox(height: 4),
                              Text(
                                context.timeAgo(n.date),
                                style: const TextStyle(fontSize: 12, color: AppColors.muted),
                              ),
                            ],
                          ),
                        ),
                        if (!state.isRead(n.id))
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
    );
  }
}
