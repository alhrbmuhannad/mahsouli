import 'package:flutter/widgets.dart';

import 'strings.dart';

/// A piece of content that exists in both Arabic and English.
class LText {
  final String ar;
  final String en;
  const LText(this.ar, this.en);

  /// Same text for both languages (used for user generated content).
  const LText.same(String text) : ar = text, en = text;

  String of(BuildContext context) => context.isAr ? ar : en;

  bool matches(String normalizedQuery) =>
      normalizeSearch(ar).contains(normalizedQuery) || normalizeSearch(en).contains(normalizedQuery);

  Map<String, dynamic> toJson() => {'ar': ar, 'en': en};
  factory LText.fromJson(Map<String, dynamic> j) => LText(j['ar'] as String, j['en'] as String);
}

extension L10nX on BuildContext {
  bool get isAr => Localizations.localeOf(this).languageCode == 'ar';

  /// Translate a key, replacing `{name}` placeholders from [args].
  String tr(String key, [Map<String, Object>? args]) {
    final lang = isAr ? 'ar' : 'en';
    var s = appStrings[key]?[lang] ?? key;
    if (args != null) {
      args.forEach((k, v) {
        final value = v is num || RegExp(r'^[0-9.:-]+$').hasMatch(v.toString()) ? digits(v.toString()) : v.toString();
        s = s.replaceAll('{$k}', value);
      });
    }
    return s;
  }

  /// Arabic-Indic digits in Arabic, Latin digits in English.
  String digits(String input) {
    if (!isAr) return input;
    const western = '0123456789';
    const eastern = '٠١٢٣٤٥٦٧٨٩';
    final b = StringBuffer();
    for (final ch in input.split('')) {
      final i = western.indexOf(ch);
      if (i >= 0) {
        b.write(eastern[i]);
      } else if (ch == '.') {
        b.write('٫');
      } else {
        b.write(ch);
      }
    }
    return b.toString();
  }

  String price(num value) {
    final v = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(1);
    return tr('price_fmt', {'v': digits(v)});
  }

  String rating(double value) => digits(value.toStringAsFixed(1));

  String number(num value) => digits(value.toString());

  String timeAgo(DateTime date) {
    final d = DateTime.now().difference(date);
    if (d.inMinutes < 1) return tr('just_now');
    if (d.inMinutes < 60) return tr('minutes_ago', {'n': d.inMinutes});
    if (d.inHours < 24) return tr('hours_ago', {'n': d.inHours});
    if (d.inDays < 30) return tr('days_ago', {'n': d.inDays});
    return digits('${date.year}/${date.month}/${date.day}');
  }

  String date(DateTime date) =>
      digits('${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}');
}

/// Wraps Latin text (handles, e-mails, names) so it keeps its order inside RTL text.
String ltr(String s) => '${String.fromCharCode(0x2066)}$s${String.fromCharCode(0x2069)}';

/// Normalises Arabic & English text so search is forgiving
/// (أ/إ/آ → ا, ة → ه, ى → ي, removes diacritics, lower-cases).
String normalizeSearch(String input) {
  var s = input.toLowerCase().trim();
  s = s.replaceAll(RegExp('[ً-ْـ]'), '');
  s = s
      .replaceAll(RegExp('[أإآ]'), 'ا')
      .replaceAll('ة', 'ه')
      .replaceAll('ى', 'ي')
      .replaceAll('ؤ', 'و')
      .replaceAll('ئ', 'ي');
  return s;
}
