import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/l10n.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const supportEmail = 'support@mahsouli.app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('help_support'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          SectionTitle(context.tr('faq')),
          for (var i = 1; i <= 6; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1.5),
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    shape: const RoundedRectangleBorder(),
                    title: Text(context.tr('faq_q$i'), style: const TextStyle(fontWeight: FontWeight.w700)),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: [Text(context.tr('faq_a$i'), style: const TextStyle(height: 1.5))],
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          SectionTitle(context.tr('contact_us')),
          const SizedBox(height: 4),
          MenuRow(
            icon: Icons.mail_outline_rounded,
            title: context.tr('email_support'),
            subtitle: supportEmail,
            trailing: const Icon(Icons.copy_rounded, size: 20),
            onTap: () {
              Clipboard.setData(const ClipboardData(text: supportEmail));
              showSnack(context, context.tr('email_copied'));
            },
          ),
        ],
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('about_app'))),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Center(child: BrandLogo(size: 88)),
          const SizedBox(height: 12),
          Center(
            child: Text(context.tr('app_name'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800)),
          ),
          Center(
            child: Text(context.tr('app_tagline'), style: const TextStyle(color: AppColors.muted)),
          ),
          Center(
            child: Text(
              context.tr('version_x', {'v': '1.0.0'}),
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 20),
          Text(context.tr('about_body'), style: const TextStyle(fontSize: 15, height: 1.7)),
          const SizedBox(height: 20),
          SectionTitle(context.tr('features')),
          for (final k in ['feat_1', 'feat_2', 'feat_3', 'feat_4', 'feat_5', 'feat_6'])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.check_circle_rounded, size: 20),
                  const SizedBox(width: 8),
                  Expanded(child: Text(context.tr(k), style: const TextStyle(height: 1.4))),
                ],
              ),
            ),
          const SizedBox(height: 20),
          SectionTitle(context.tr('team')),
          Wrap(
            spacing: 10,
            children: [
              Chip(
                avatar: const Avatar(text: 'M', size: 24, fontSize: 12),
                label: Text(context.tr('member_1')),
              ),
              Chip(
                avatar: const Avatar(text: 'N', size: 24, fontSize: 12),
                label: Text(context.tr('member_2')),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(context.tr('demo_note'), style: const TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5)),
        ],
      ),
    );
  }
}
