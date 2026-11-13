import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final lang = state.locale.languageCode;

    Widget toggle(NotificationType t, String key, bool value) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(context.tr(key), style: const TextStyle(fontWeight: FontWeight.w700)),
      value: value,
      onChanged: (v) => state.setNotificationPref(t, v),
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.tr('settings'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        children: [
          SectionTitle(context.tr('language')),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.brown,
              selectedForegroundColor: AppColors.white,
              side: const BorderSide(color: AppColors.inputBorder),
              textStyle: const TextStyle(fontFamily: 'Tajawal', fontWeight: FontWeight.w700, fontSize: 15),
            ),
            segments: const [
              ButtonSegment(value: 'ar', label: Text('العربية')),
              ButtonSegment(value: 'en', label: Text('English')),
            ],
            selected: {lang},
            onSelectionChanged: (s) => state.setLocale(s.first),
          ),
          const SizedBox(height: 24),
          SectionTitle(context.tr('notifications')),
          toggle(NotificationType.newProduct, 'notify_new_products', state.data.notifyNewProducts),
          toggle(NotificationType.offer, 'notify_offers', state.data.notifyOffers),
          toggle(NotificationType.reward, 'notify_rewards', state.data.notifyRewards),
          if (state.isLoggedIn) ...[
            const SizedBox(height: 16),
            SectionTitle(context.tr('account_security')),
            const SizedBox(height: 4),
            MenuRow(
              icon: Icons.lock_outline_rounded,
              title: context.tr('change_password'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ChangePasswordScreen())),
            ),
            const SizedBox(height: 10),
            MenuRow(
              icon: Icons.delete_outline_rounded,
              title: context.tr('delete_account'),
              color: AppColors.danger,
              onTap: () async {
                final ok = await confirmDialog(
                  context,
                  title: context.tr('delete_account'),
                  message: context.tr('delete_account_msg'),
                  confirm: context.tr('delete'),
                  danger: true,
                );
                if (ok && context.mounted) {
                  Navigator.of(context, rootNavigator: true).popUntil((r) => r.isFirst);
                  state.deleteAccount();
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('change_password'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            FieldLabel(context.tr('current_password')),
            TextFormField(
              controller: _current,
              obscureText: true,
              validator: (v) => (v ?? '').isEmpty ? context.tr('err_required') : null,
            ),
            const SizedBox(height: 14),
            FieldLabel(context.tr('new_password')),
            TextFormField(
              controller: _new,
              obscureText: true,
              decoration: InputDecoration(hintText: context.tr('password_new_hint')),
              validator: (v) => (v ?? '').length < 6 ? context.tr('err_password_short') : null,
            ),
            const SizedBox(height: 14),
            FieldLabel(context.tr('confirm_password')),
            TextFormField(
              controller: _confirm,
              obscureText: true,
              validator: (v) => v != _new.text ? context.tr('err_password_match') : null,
            ),
            const SizedBox(height: 16),
            if (_error != null) ErrorBanner(_error!),
            FilledButton(
              onPressed: () {
                setState(() => _error = null);
                if (!_form.currentState!.validate()) return;
                final err = context.read<AppState>().changePassword(_current.text, _new.text);
                if (err != null) {
                  setState(() => _error = context.tr(err));
                  return;
                }
                showSnack(context, context.tr('password_changed'));
                Navigator.pop(context);
              },
              child: Text(context.tr('save_password')),
            ),
          ],
        ),
      ),
    );
  }
}
