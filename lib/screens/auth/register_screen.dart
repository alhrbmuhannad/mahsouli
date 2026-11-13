import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _confirm = TextEditingController();
  bool _obscure = true;
  bool _agree = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _pass.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    if (!_agree) {
      setState(() => _error = context.tr('err_accept_terms'));
      return;
    }
    final err = context.read<AppState>().register(_name.text, _email.text, _pass.text);
    if (err != null) {
      setState(() => _error = context.tr(err));
      return;
    }
    Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHeader(subtitleKey: 'register_subtitle', showBack: true),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.tr('create_account'),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 14),
                    FieldLabel(context.tr('full_name')),
                    TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(hintText: context.tr('full_name_hint')),
                      validator: (v) => (v ?? '').trim().length < 2 ? context.tr('err_name') : null,
                    ),
                    const SizedBox(height: 14),
                    FieldLabel(context.tr('email')),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textDirection: TextDirection.ltr,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(hintText: context.tr('email_hint')),
                      validator: (v) => AppState.validEmail(v ?? '') ? null : context.tr('err_email'),
                    ),
                    const SizedBox(height: 14),
                    FieldLabel(context.tr('password')),
                    TextFormField(
                      controller: _pass,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        hintText: context.tr('password_new_hint'),
                        suffixIcon: ExcludeFocus(
                          child: IconButton(
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      validator: (v) => (v ?? '').length < 6 ? context.tr('err_password_short') : null,
                    ),
                    const SizedBox(height: 14),
                    FieldLabel(context.tr('confirm_password')),
                    TextFormField(
                      controller: _confirm,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(hintText: context.tr('confirm_password_hint')),
                      validator: (v) => v != _pass.text ? context.tr('err_password_match') : null,
                    ),
                    const SizedBox(height: 8),
                    CheckboxListTile(
                      value: _agree,
                      onChanged: (v) => setState(() => _agree = v ?? false),
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: AppColors.brown,
                      title: Text(context.tr('accept_terms'), style: const TextStyle(fontSize: 14)),
                    ),
                    if (_error != null) ErrorBanner(_error!),
                    const SizedBox(height: 6),
                    FilledButton(onPressed: _submit, child: Text(context.tr('create_account'))),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(context.tr('have_account'), style: const TextStyle(color: AppColors.muted)),
                        TextButton(onPressed: () => Navigator.pop(context), child: Text(context.tr('login'))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
