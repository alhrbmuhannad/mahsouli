import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'login_screen.dart';

/// Two-step password reset: verify the account email, then choose a new password.
class ResetPasswordScreen extends StatefulWidget {
  final String email;
  const ResetPasswordScreen({super.key, this.email = ''});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _verified = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _next() {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final state = context.read<AppState>();
    if (!_verified) {
      if (!state.accountExists(_email.text)) {
        setState(() => _error = context.tr('err_no_account'));
        return;
      }
      setState(() => _verified = true);
      return;
    }
    state.resetPassword(_email.text, _pass.text);
    showSnack(context, context.tr('password_reset_done'));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('reset_password'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(color: AppColors.peach, shape: BoxShape.circle),
                  child: Icon(_verified ? Icons.lock_reset_rounded : Icons.mark_email_read_outlined, size: 48),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.tr(_verified ? 'reset_step2' : 'reset_step1'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: AppColors.muted),
              ),
              const SizedBox(height: 20),
              FieldLabel(context.tr('email')),
              TextFormField(
                controller: _email,
                enabled: !_verified,
                textDirection: TextDirection.ltr,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(hintText: context.tr('email_hint')),
                validator: (v) => AppState.validEmail(v ?? '') ? null : context.tr('err_email'),
              ),
              if (_verified) ...[
                const SizedBox(height: 14),
                FieldLabel(context.tr('new_password')),
                TextFormField(
                  controller: _pass,
                  obscureText: true,
                  decoration: InputDecoration(hintText: context.tr('password_new_hint')),
                  validator: (v) => (v ?? '').length < 6 ? context.tr('err_password_short') : null,
                ),
                const SizedBox(height: 14),
                FieldLabel(context.tr('confirm_password')),
                TextFormField(
                  controller: _confirm,
                  obscureText: true,
                  decoration: InputDecoration(hintText: context.tr('confirm_password_hint')),
                  validator: (v) => v != _pass.text ? context.tr('err_password_match') : null,
                ),
              ],
              const SizedBox(height: 16),
              if (_error != null) ErrorBanner(_error!),
              FilledButton(onPressed: _next, child: Text(context.tr(_verified ? 'save_password' : 'continue'))),
            ],
          ),
        ),
      ),
    );
  }
}
