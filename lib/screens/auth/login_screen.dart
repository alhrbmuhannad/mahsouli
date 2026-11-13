import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../onboarding_screen.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  void _submit() {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    final err = context.read<AppState>().login(_email.text, _pass.text);
    if (err != null) setState(() => _error = context.tr(err));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const AuthHeader(subtitleKey: 'welcome_coffee'),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(context.tr('login'), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),
                    FieldLabel(context.tr('email')),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      textDirection: TextDirection.ltr,
                      decoration: InputDecoration(hintText: context.tr('email_hint')),
                      validator: (v) => AppState.validEmail(v ?? '') ? null : context.tr('err_email'),
                    ),
                    const SizedBox(height: 14),
                    FieldLabel(context.tr('password')),
                    TextFormField(
                      controller: _pass,
                      obscureText: _obscure,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: InputDecoration(
                        hintText: context.tr('password_hint'),
                        suffixIcon: ExcludeFocus(
                          child: IconButton(
                            tooltip: context.tr(_obscure ? 'show_password' : 'hide_password'),
                            icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                        ),
                      ),
                      validator: (v) => (v ?? '').isEmpty ? context.tr('err_required') : null,
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        onPressed: () =>
                            Navigator.of(context)
                                .push(MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: _email.text))),
                        child: Text(
                          context.tr('forgot_password'),
                          style: const TextStyle(decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                    if (_error != null) ErrorBanner(_error!),
                    const SizedBox(height: 6),
                    FilledButton(onPressed: _submit, child: Text(context.tr('login'))),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppColors.inputBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(context.tr('or'), style: const TextStyle(color: AppColors.muted)),
                        ),
                        const Expanded(child: Divider(color: AppColors.inputBorder)),
                      ],
                    ),
                    const SizedBox(height: 14),
                    OutlinedButton(
                      onPressed: () =>
                          Navigator.of(context).push(MaterialPageRoute(builder: (_) => const RegisterScreen())),
                      child: Text(context.tr('create_account')),
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: context.read<AppState>().continueAsGuest,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.tr('continue_guest'),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                const Icon(Icons.chevron_right_rounded),
                              ],
                            ),
                            Text(
                              context.tr('guest_hint'),
                              style: const TextStyle(fontSize: 13, color: AppColors.muted),
                            ),
                          ],
                        ),
                      ),
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

class AuthHeader extends StatelessWidget {
  final String subtitleKey;
  final bool showBack;
  const AuthHeader({super.key, required this.subtitleKey, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.peach,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
      ),
      padding: EdgeInsets.fromLTRB(16, top + 8, 16, 32),
      child: Column(
        children: [
          Row(
            children: [
              if (showBack) const BackButton() else const SizedBox(width: 48),
              const Spacer(),
              const LanguageToggle(),
            ],
          ),
          const BrandLogo(),
          const SizedBox(height: 10),
          Text(context.tr('app_name'), style: const TextStyle(fontSize: 38, fontWeight: FontWeight.w800)),
          Text(context.tr(subtitleKey), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class FieldLabel extends StatelessWidget {
  final String text;
  const FieldLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
  );
}

class ErrorBanner extends StatelessWidget {
  final String text;
  const ErrorBanner(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AppColors.danger.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
    child: Row(
      children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.danger),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
