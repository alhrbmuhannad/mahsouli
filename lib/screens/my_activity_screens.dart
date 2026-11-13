import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'add_recipe_screen.dart';
import 'auth/login_screen.dart';
import 'reviews_screen.dart';

class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reviews = context.watch<AppState>().myReviews;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('my_ratings'))),
      body: reviews.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.star_outline_rounded,
                title: context.tr('no_my_reviews'),
                message: context.tr('no_my_reviews_msg'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: reviews.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (_, i) => ReviewTile(review: reviews[i], showTarget: true),
            ),
    );
  }
}

class MyRecipesScreen extends StatelessWidget {
  const MyRecipesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final mine = state.myRecipes;
    final saved = state.favoriteRecipes;
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('my_recipes'))),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'my_add_recipe',
        backgroundColor: AppColors.brown,
        foregroundColor: AppColors.white,
        icon: const Icon(Icons.add_rounded),
        label: Text(context.tr('add_recipe')),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AddRecipeScreen())),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
        children: [
          SectionTitle(context.tr('created_by_me')),
          if (mine.isEmpty) Text(context.tr('no_created_recipes'), style: const TextStyle(color: AppColors.muted)),
          for (final r in mine) ...[RecipeCard(recipe: r), const SizedBox(height: 10)],
          const SizedBox(height: 16),
          SectionTitle(context.tr('saved_recipes')),
          if (saved.isEmpty) Text(context.tr('no_saved_recipes'), style: const TextStyle(color: AppColors.muted)),
          for (final r in saved) ...[RecipeCard(recipe: r), const SizedBox(height: 10)],
        ],
      ),
    );
  }
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _city;

  @override
  void initState() {
    super.initState();
    final u = context.read<AppState>().user!;
    _name = TextEditingController(text: u.name);
    _phone = TextEditingController(text: u.phone);
    _city = TextEditingController(text: u.city);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _city.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().user;
    if (user == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('edit_profile'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(child: Avatar(text: user.initial, size: 88, fontSize: 36)),
            const SizedBox(height: 20),
            FieldLabel(context.tr('full_name')),
            TextFormField(
              controller: _name,
              validator: (v) => (v ?? '').trim().length < 2 ? context.tr('err_name') : null,
            ),
            const SizedBox(height: 14),
            FieldLabel(context.tr('email')),
            TextFormField(initialValue: user.email, enabled: false, textDirection: TextDirection.ltr),
            const SizedBox(height: 14),
            FieldLabel(context.tr('phone_optional')),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              decoration: const InputDecoration(hintText: '05XXXXXXXX'),
              validator: (v) {
                final t = (v ?? '').trim();
                if (t.isEmpty) return null;
                return RegExp(r'^(\+966|0)?5\d{8}$').hasMatch(t) ? null : context.tr('err_phone');
              },
            ),
            const SizedBox(height: 14),
            FieldLabel(context.tr('city_optional')),
            TextFormField(
              controller: _city,
              decoration: InputDecoration(hintText: context.tr('city_hint')),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                context.read<AppState>().updateProfile(name: _name.text, phone: _phone.text, city: _city.text);
                showSnack(context, context.tr('profile_saved'));
                Navigator.pop(context);
              },
              child: Text(context.tr('save')),
            ),
          ],
        ),
      ),
    );
  }
}
