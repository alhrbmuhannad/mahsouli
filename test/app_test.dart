import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mahsouli/data/catalog.dart';
import 'package:mahsouli/main.dart';
import 'package:mahsouli/models/models.dart';
import 'package:mahsouli/screens/account_screen.dart';
import 'package:mahsouli/state/app_state.dart';
import 'package:mahsouli/state/nav_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('AppState', () {
    test('register, logout, login and wrong password', () async {
      final s = AppState();
      await s.load();
      expect(s.register('Muhannad', 'm@test.com', 'secret1'), isNull);
      expect(s.isLoggedIn, isTrue);
      expect(s.points, AppState.welcomePoints);
      expect(s.register('X', 'M@test.com', 'secret1'), 'err_email_exists');
      s.logout();
      expect(s.hasSession, isFalse);
      expect(s.login('m@test.com', 'nope'), 'err_wrong_password');
      expect(s.login('other@test.com', 'secret1'), 'err_no_account');
      expect(s.login('m@test.com', 'secret1'), isNull);
      expect(s.user!.name, 'Muhannad');
    });

    test('data persists across app restarts', () async {
      final a = AppState();
      await a.load();
      a.register('Nasser', 'n@test.com', 'secret1');
      a.toggleFavCoffee('c1');
      a.setLocale('en');
      await Future<void>.delayed(Duration.zero);

      final b = AppState();
      await b.load();
      expect(b.isLoggedIn, isTrue);
      expect(b.isFavCoffee('c1'), isTrue);
      expect(b.locale.languageCode, 'en');
    });

    test('reviews update rating and award points once', () async {
      final s = AppState();
      await s.load();
      s.register('Sara', 's@test.com', 'secret1');
      final c = Catalog.coffee('c1')!;
      final before = s.coffeeRating(c);
      expect(s.submitReview(ReviewTarget.coffee, 'c1', 1, 'meh'), AppState.pointsPerReview);
      final after = s.coffeeRating(c);
      expect(after.count, before.count + 1);
      expect(after.avg, lessThan(before.avg));
      // editing does not award again
      expect(s.submitReview(ReviewTarget.coffee, 'c1', 5, 'great'), 0);
      expect(s.points, AppState.welcomePoints + AppState.pointsPerReview);
      expect(s.myReviews.single.rating, 5);
    });

    test('redeeming rewards deducts points and generates a code', () async {
      final s = AppState();
      await s.load();
      s.register('Lama', 'l@test.com', 'secret1');
      final cheap = Catalog.offers.firstWhere((o) => o.id == 'w2'); // 60 pts
      final pricey = Catalog.offers.firstWhere((o) => o.id == 'w3'); // 200 pts
      expect(() => s.redeem(cheap), throwsA('err_not_enough_points'));
      for (final id in ['c1', 'c2']) {
        s.submitReview(ReviewTarget.coffee, id, 5, '');
      }
      final code = s.redeem(cheap);
      expect(code, startsWith('MHS-'));
      expect(s.points, 70 - 60);
      expect(s.isRedeemed('w2'), isTrue);
      expect(() => s.redeem(pricey), throwsA('err_not_enough_points'));
    });

    test('guests cannot redeem or review', () async {
      final s = AppState();
      await s.load();
      s.continueAsGuest();
      expect(s.submitReview(ReviewTarget.coffee, 'c1', 5, ''), 0);
      expect(() => s.redeem(Catalog.offers.first), throwsA('err_login_required'));
    });
  });

  group('Search', () {
    test('Arabic and English queries match', () async {
      final s = AppState();
      await s.load();
      expect(SearchFilter().apply('اثيوبيا', s).length, 3);
      expect(SearchFilter().apply('ethiopia', s).length, SearchFilter().apply('إثيوبيا', s).length);
      expect(SearchFilter().apply('محمصة الشمال', s).every((c) => c.roasterId == 'north'), isTrue);
    });

    test('filters combine', () async {
      final s = AppState();
      await s.load();
      final f = SearchFilter(roasts: {RoastLevel.dark}, methods: {BrewMethod.espresso});
      final r = f.apply('', s);
      expect(r, isNotEmpty);
      expect(r.every((c) => c.roast == RoastLevel.dark && c.methods.contains(BrewMethod.espresso)), isTrue);
      final priced = SearchFilter(price: const RangeValues(0, 40), sort: SortBy.priceLow).apply('', s);
      expect(priced.every((c) => c.price <= 40), isTrue);
    });
  });

  testWidgets('app opens to onboarding then login, guest reaches home', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ChangeNotifierProvider(create: (_) => AppState()..load(), child: const MahsouliApp()));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pumpAndSettle();
    expect(find.text('ابدأ الآن').evaluate().isEmpty, isTrue); // first onboarding page
    await tester.tap(find.text('تخطي'));
    await tester.pumpAndSettle();
    expect(find.text('الدخول كضيف'), findsOneWidget);
    await tester.ensureVisible(find.text('الدخول كضيف'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('الدخول كضيف'));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('تصفح حسب'), findsOneWidget);
    expect(find.text('أشهر أنواع البن'), findsOneWidget);

    // switch to English from the account tab → settings
    await tester.tap(find.text('حسابي').hitTestable().last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('الإعدادات'),
      200,
      scrollable: find.descendant(of: find.byType(AccountScreen), matching: find.byType(Scrollable)).first,
    );
    await tester.tap(find.text('الإعدادات'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsOneWidget);
  });
}
