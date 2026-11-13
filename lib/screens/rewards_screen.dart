import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Offers, point rewards and redeemed coupons (NFR-4 & NFR-5).
class RewardsScreen extends StatefulWidget {
  final String? highlightOfferId;
  const RewardsScreen({super.key, this.highlightOfferId});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    final o = Catalog.offer(widget.highlightOfferId);
    _tabs = TabController(length: 3, vsync: this, initialIndex: o != null && o.isReward ? 1 : 0);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final offers = Catalog.offers.where((o) => !o.isReward).toList();
    final rewards = Catalog.offers.where((o) => o.isReward).toList();
    final mine = Catalog.offers.where((o) => state.isRedeemed(o.id)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('offers_rewards')),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.brown,
          unselectedLabelColor: AppColors.muted,
          indicatorColor: AppColors.brown,
          labelStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w800, fontSize: 15),
          tabs: [
            Tab(text: context.tr('offers')),
            Tab(text: context.tr('rewards')),
            Tab(text: context.tr('my_coupons')),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.brown, borderRadius: BorderRadius.circular(20)),
            child: Row(
              children: [
                const Icon(Icons.stars_rounded, color: AppColors.peach, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('points_n', {'n': state.points}),
                        style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      Text(
                        context.tr('earn_points_hint'),
                        style: const TextStyle(color: AppColors.peach, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                _OfferList(offers: offers, highlight: widget.highlightOfferId),
                _OfferList(offers: rewards, highlight: widget.highlightOfferId),
                mine.isEmpty
                    ? EmptyState(
                        icon: Icons.confirmation_number_outlined,
                        title: context.tr('no_coupons'),
                        message: context.tr('no_coupons_msg'),
                      )
                    : _OfferList(offers: mine),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferList extends StatelessWidget {
  final List<Offer> offers;
  final String? highlight;
  const _OfferList({required this.offers, this.highlight});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
    itemCount: offers.length,
    separatorBuilder: (_, _) => const SizedBox(height: 12),
    itemBuilder: (_, i) => OfferCard(offer: offers[i], highlighted: offers[i].id == highlight),
  );
}

class OfferCard extends StatelessWidget {
  final Offer offer;
  final bool highlighted;
  const OfferCard({super.key, required this.offer, this.highlighted = false});

  Future<void> _redeem(BuildContext context) async {
    if (!await requireLogin(context) || !context.mounted) return;
    final state = context.read<AppState>();
    final ok = await confirmDialog(
      context,
      title: context.tr('redeem_confirm_title'),
      message:
          '${offer.title.of(context)}\n\n${context.tr('terms')}: ${offer.terms.of(context)}'
          '${offer.isReward ? '\n\n${context.tr('cost_points', {'n': offer.pointsCost})}' : ''}',
      confirm: context.tr('redeem'),
    );
    if (!ok || !context.mounted) return;
    try {
      final code = state.redeem(offer);
      if (context.mounted) _showCode(context, code);
    } catch (e) {
      if (context.mounted) showSnack(context, context.tr(e.toString()));
    }
  }

  void _showCode(BuildContext context, String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.confirmation_number_rounded, size: 40),
        title: Text(ctx.tr('your_coupon')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.brown, width: 1.5),
              ),
              child: SelectableText(
                code,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: 2),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              ctx.tr('coupon_hint', {'r': Catalog.roaster(offer.roasterId).name.of(ctx)}),
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.muted),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(ctx);
              showSnack(context, context.tr('code_copied'));
            },
            child: Text(ctx.tr('copy_code')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(100, 44)),
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.tr('done')),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final redeemed = state.isRedeemed(offer.id);
    final code = state.couponCode(offer.id);
    final roaster = Catalog.roaster(offer.roasterId);
    final canAfford = offer.pointsCost <= state.points;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: highlighted ? AppColors.brown : AppColors.border, width: highlighted ? 2 : 1.5),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.peach, borderRadius: BorderRadius.circular(16)),
                child: offer.discount > 0
                    ? Text(
                        context.digits('${offer.discount}%'),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
                      )
                    : const Icon(Icons.card_giftcard_rounded),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roaster.name.of(context), style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                    Text(offer.title.of(context), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(offer.description.of(context), style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${context.tr('terms')}: ${offer.terms.of(context)}',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          Text(
            context.tr('valid_until', {'d': context.date(offer.expires)}),
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (offer.isReward)
                Pill(text: context.tr('points_n', {'n': offer.pointsCost}), icon: Icons.stars_rounded, filled: true)
              else
                Pill(text: context.tr('free'), icon: Icons.local_offer_outlined, filled: true),
              const Spacer(),
              if (redeemed)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: () => _showCode(context, code!),
                  icon: const Icon(Icons.qr_code_rounded, size: 18),
                  label: Text(context.tr('show_code')),
                )
              else
                FilledButton(
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: offer.isExpired || (offer.isReward && state.isLoggedIn && !canAfford)
                      ? null
                      : () => _redeem(context),
                  child: Text(
                    context.tr(
                      offer.isExpired
                          ? 'expired'
                          : offer.isReward && state.isLoggedIn && !canAfford
                          ? 'not_enough_points'
                          : 'redeem',
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
