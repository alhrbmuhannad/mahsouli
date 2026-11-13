import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/catalog.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import 'auth/login_screen.dart';

/// Lets a signed-in user share their own brewing recipe.
class AddRecipeScreen extends StatefulWidget {
  const AddRecipeScreen({super.key});

  @override
  State<AddRecipeScreen> createState() => _AddRecipeScreenState();
}

class _StepFields {
  final text = TextEditingController();
  final seconds = TextEditingController(text: '30');
  final pourTo = TextEditingController();
  void dispose() {
    text.dispose();
    seconds.dispose();
    pourTo.dispose();
  }
}

class _AddRecipeScreenState extends State<AddRecipeScreen> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _subtitle = TextEditingController();
  final _coffee = TextEditingController(text: '15');
  final _water = TextEditingController(text: '250');
  final _grind = TextEditingController();
  final _temp = TextEditingController(text: '92-94');
  final _minutes = TextEditingController(text: '5');
  BrewMethod _method = BrewMethod.v60;
  Difficulty _difficulty = Difficulty.easy;
  String? _coffeeId;
  final List<_StepFields> _steps = [_StepFields(), _StepFields()];

  @override
  void dispose() {
    for (final c in [_title, _subtitle, _coffee, _water, _grind, _temp, _minutes]) {
      c.dispose();
    }
    for (final s in _steps) {
      s.dispose();
    }
    super.dispose();
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? context.tr('err_required') : null;

  String? _positive(String? v) {
    final n = double.tryParse((v ?? '').trim());
    return n == null || n <= 0 ? context.tr('err_number') : null;
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final state = context.read<AppState>();
    final user = state.user!;
    final handle = user.email.split('@').first;
    final recipe = Recipe(
      id: 'u${DateTime.now().millisecondsSinceEpoch}',
      method: _method,
      title: LText.same(_title.text.trim()),
      subtitle: LText.same(_subtitle.text.trim().isEmpty ? methodLabel(context, _method) : _subtitle.text.trim()),
      coffee: double.parse(_coffee.text.trim()),
      water: double.parse(_water.text.trim()).round(),
      grind: LText.same(_grind.text.trim()),
      temp: _temp.text.trim(),
      minutes: double.parse(_minutes.text.trim()).round(),
      difficulty: _difficulty,
      author: handle,
      authorEmail: user.email,
      coffeeId: _coffeeId,
      createdAt: DateTime.now(),
      steps: _steps
          .where((s) => s.text.text.trim().isNotEmpty)
          .map(
            (s) => BrewStep(
              LText.same(s.text.text.trim()),
              int.tryParse(s.seconds.text.trim()) ?? 30,
              pourTo: int.tryParse(s.pourTo.text.trim()),
            ),
          )
          .toList(),
    );
    if (recipe.steps.isEmpty) {
      showSnack(context, context.tr('err_steps'));
      return;
    }
    state.addRecipe(recipe);
    showSnack(context, context.tr('recipe_published'));
    Navigator.pop(context);
  }

  Widget _numField(TextEditingController c, String label, String suffix) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label),
        TextFormField(
          controller: c,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textDirection: TextDirection.ltr,
          decoration: InputDecoration(suffixText: suffix),
          validator: _positive,
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('add_recipe'))),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          children: [
            FieldLabel(context.tr('brew_method')),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in BrewMethod.values)
                  ChoicePill(
                    label: methodLabel(context, m),
                    selected: _method == m,
                    onTap: () => setState(() => _method = m),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            FieldLabel(context.tr('recipe_title')),
            TextFormField(
              controller: _title,
              decoration: InputDecoration(hintText: context.tr('recipe_title_hint')),
              validator: _required,
            ),
            const SizedBox(height: 14),
            FieldLabel(context.tr('recipe_subtitle')),
            TextFormField(
              controller: _subtitle,
              decoration: InputDecoration(hintText: context.tr('recipe_subtitle_hint')),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _numField(_coffee, context.tr('coffee'), context.tr('unit_g')),
                const SizedBox(width: 12),
                _numField(_water, context.tr('water'), context.tr('unit_ml')),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FieldLabel(context.tr('water_temp')),
                      TextFormField(
                        controller: _temp,
                        textDirection: TextDirection.ltr,
                        decoration: const InputDecoration(suffixText: '°C'),
                        validator: _required,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _numField(_minutes, context.tr('time'), context.tr('unit_min')),
              ],
            ),
            const SizedBox(height: 14),
            FieldLabel(context.tr('grind_size')),
            TextFormField(
              controller: _grind,
              decoration: InputDecoration(hintText: context.tr('grind_hint')),
              validator: _required,
            ),
            const SizedBox(height: 14),
            FieldLabel(context.tr('difficulty')),
            SegmentedButton<Difficulty>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppColors.brown,
                selectedForegroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.inputBorder),
              ),
              segments: [
                for (final d in Difficulty.values) ButtonSegment(value: d, label: Text(difficultyLabel(context, d))),
              ],
              selected: {_difficulty},
              onSelectionChanged: (s) => setState(() => _difficulty = s.first),
            ),
            const SizedBox(height: 14),
            FieldLabel(context.tr('suggested_coffee_optional')),
            DropdownButtonFormField<String?>(
              initialValue: _coffeeId,
              isExpanded: true,
              items: [
                DropdownMenuItem(value: null, child: Text(context.tr('none'))),
                for (final c in Catalog.coffees)
                  DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name.of(context), overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: (v) => setState(() => _coffeeId = v),
            ),
            const SizedBox(height: 20),
            SectionTitle(context.tr('steps')),
            for (var i = 0; i < _steps.length; i++) ...[
              AppCard(
                key: ObjectKey(_steps[i]),
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Avatar(text: context.number(i + 1), size: 30, fontSize: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            context.tr('step_n', {'n': i + 1}),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (_steps.length > 1)
                          IconButton(
                            tooltip: context.tr('delete'),
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              final removed = _steps.removeAt(i);
                              setState(() {});
                              WidgetsBinding.instance.addPostFrameCallback((_) => removed.dispose());
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _steps[i].text,
                      maxLines: 2,
                      decoration: InputDecoration(hintText: context.tr('step_hint')),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _steps[i].seconds,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(labelText: context.tr('seconds'), isDense: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: _steps[i].pourTo,
                            keyboardType: TextInputType.number,
                            textDirection: TextDirection.ltr,
                            decoration: InputDecoration(labelText: context.tr('pour_to_optional'), isDense: true),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
            TextButton.icon(
              onPressed: () => setState(() => _steps.add(_StepFields())),
              icon: const Icon(Icons.add_rounded),
              label: Text(context.tr('add_step')),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: Text(context.tr('publish_recipe'))),
          ],
        ),
      ),
    );
  }
}
