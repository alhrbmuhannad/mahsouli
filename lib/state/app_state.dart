import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/catalog.dart';
import '../l10n/l10n.dart';
import '../models/models.dart';

/// Central app state. Everything is persisted locally with SharedPreferences
/// so the app works fully offline on the device.
class AppState extends ChangeNotifier {
  static const _kLocale = 'locale';
  static const _kOnboarded = 'onboarded';
  static const _kUsers = 'users';
  static const _kSession = 'session';
  static const _kReviews = 'reviews';
  static const _kRecipes = 'custom_recipes';
  static const _kUserData = 'userdata_';
  static const guestKey = 'guest';

  static const pointsPerReview = 10;
  static const welcomePoints = 50;

  SharedPreferences? _prefs;
  bool loaded = false;

  Locale locale = const Locale('ar');
  bool onboarded = false;
  final Map<String, UserAccount> _users = {};
  String? _session; // email, guestKey or null
  UserData data = UserData();
  final List<Review> _userReviews = [];
  final List<Recipe> _customRecipes = [];

  // ------------------------------------------------------------- lifecycle
  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _prefs = p;
    locale = Locale(p.getString(_kLocale) ?? 'ar');
    onboarded = p.getBool(_kOnboarded) ?? false;

    final usersJson = p.getString(_kUsers);
    if (usersJson != null) {
      final list = jsonDecode(usersJson) as List;
      for (final u in list) {
        final acc = UserAccount.fromJson(Map<String, dynamic>.from(u as Map));
        _users[acc.email] = acc;
      }
    }
    final reviewsJson = p.getString(_kReviews);
    if (reviewsJson != null) {
      _userReviews.addAll(
        (jsonDecode(reviewsJson) as List).map((r) => Review.fromJson(Map<String, dynamic>.from(r as Map))),
      );
    }
    final recipesJson = p.getString(_kRecipes);
    if (recipesJson != null) {
      _customRecipes.addAll(
        (jsonDecode(recipesJson) as List).map((r) => Recipe.fromJson(Map<String, dynamic>.from(r as Map))),
      );
    }
    _session = p.getString(_kSession);
    if (_session != null && _session != guestKey && !_users.containsKey(_session)) {
      _session = null;
    }
    if (_session != null) _loadUserData();
    loaded = true;
    notifyListeners();
  }

  void _loadUserData() {
    final raw = _prefs?.getString('$_kUserData$_session');
    data = raw == null ? UserData() : UserData.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
  }

  Future<void> _saveUserData() async {
    if (_session == null) return;
    await _prefs?.setString('$_kUserData$_session', jsonEncode(data.toJson()));
  }

  Future<void> _saveUsers() async =>
      _prefs?.setString(_kUsers, jsonEncode(_users.values.map((u) => u.toJson()).toList()));

  Future<void> _saveReviews() async =>
      _prefs?.setString(_kReviews, jsonEncode(_userReviews.map((r) => r.toJson()).toList()));

  Future<void> _saveRecipes() async =>
      _prefs?.setString(_kRecipes, jsonEncode(_customRecipes.map((r) => r.toJson()).toList()));

  // ------------------------------------------------------- language/onboard
  void setLocale(String code) {
    locale = Locale(code);
    _prefs?.setString(_kLocale, code);
    notifyListeners();
  }

  void completeOnboarding() {
    onboarded = true;
    _prefs?.setBool(_kOnboarded, true);
    notifyListeners();
  }

  // ------------------------------------------------------------------ auth
  bool get hasSession => _session != null;
  bool get isGuest => _session == guestKey;
  bool get isLoggedIn => _session != null && !isGuest;
  UserAccount? get user => isLoggedIn ? _users[_session] : null;

  static String hashPassword(String email, String password) =>
      sha256.convert(utf8.encode('mahsouli:${email.toLowerCase()}:$password')).toString();

  static bool validEmail(String e) => RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$').hasMatch(e.trim());

  /// Returns an error translation key, or null on success.
  String? register(String name, String email, String password) {
    final e = email.trim().toLowerCase();
    if (_users.containsKey(e)) return 'err_email_exists';
    _users[e] = UserAccount(
      email: e,
      name: name.trim(),
      passwordHash: hashPassword(e, password),
      createdAt: DateTime.now(),
    );
    _saveUsers();
    _startSession(e);
    data.points = welcomePoints;
    _pushNotification(
      NotificationType.reward,
      const LText('أهلاً بك في محصولي ☕', 'Welcome to Mahsouli ☕'),
      const LText('أضفنا ٥٠ نقطة ترحيبية إلى رصيدك.', 'We added 50 welcome points to your balance.'),
    );
    _saveUserData();
    notifyListeners();
    return null;
  }

  String? login(String email, String password) {
    final e = email.trim().toLowerCase();
    final u = _users[e];
    if (u == null) return 'err_no_account';
    if (u.passwordHash != hashPassword(e, password)) return 'err_wrong_password';
    _startSession(e);
    notifyListeners();
    return null;
  }

  void continueAsGuest() {
    _startSession(guestKey);
    notifyListeners();
  }

  void _startSession(String key) {
    _session = key;
    _prefs?.setString(_kSession, key);
    _loadUserData();
  }

  void logout() {
    _session = null;
    _prefs?.remove(_kSession);
    data = UserData();
    notifyListeners();
  }

  bool accountExists(String email) => _users.containsKey(email.trim().toLowerCase());

  String? resetPassword(String email, String newPassword) {
    final e = email.trim().toLowerCase();
    final u = _users[e];
    if (u == null) return 'err_no_account';
    _users[e] = u.copyWith(passwordHash: hashPassword(e, newPassword));
    _saveUsers();
    return null;
  }

  String? changePassword(String current, String newPassword) {
    final u = user;
    if (u == null) return 'err_no_account';
    if (u.passwordHash != hashPassword(u.email, current)) {
      return 'err_wrong_password';
    }
    _users[u.email] = u.copyWith(passwordHash: hashPassword(u.email, newPassword));
    _saveUsers();
    return null;
  }

  void updateProfile({required String name, required String phone, required String city}) {
    final u = user;
    if (u == null) return;
    _users[u.email] = u.copyWith(name: name.trim(), phone: phone.trim(), city: city.trim());
    _saveUsers();
    notifyListeners();
  }

  void deleteAccount() {
    final u = user;
    if (u == null) return;
    _users.remove(u.email);
    _userReviews.removeWhere((r) => r.authorEmail == u.email);
    _customRecipes.removeWhere((r) => r.authorEmail == u.email);
    _prefs?.remove('$_kUserData${u.email}');
    _saveUsers();
    _saveReviews();
    _saveRecipes();
    logout();
  }

  // ------------------------------------------------------------- favorites
  bool isFavCoffee(String id) => data.favCoffees.contains(id);
  bool isFavRecipe(String id) => data.favRecipes.contains(id);

  /// Returns the new favourite state.
  bool toggleFavCoffee(String id) {
    final added = data.favCoffees.add(id);
    if (!added) data.favCoffees.remove(id);
    _saveUserData();
    notifyListeners();
    return added;
  }

  bool toggleFavRecipe(String id) {
    final added = data.favRecipes.add(id);
    if (!added) data.favRecipes.remove(id);
    _saveUserData();
    notifyListeners();
    return added;
  }

  List<Coffee> get favoriteCoffees => Catalog.coffees.where((c) => data.favCoffees.contains(c.id)).toList();
  List<Recipe> get favoriteRecipes => allRecipes.where((r) => data.favRecipes.contains(r.id)).toList();

  // ---------------------------------------------------------------- search
  void addRecentSearch(String q) {
    final t = q.trim();
    if (t.isEmpty) return;
    data.recentSearches.remove(t);
    data.recentSearches.insert(0, t);
    if (data.recentSearches.length > 6) data.recentSearches.removeLast();
    _saveUserData();
    notifyListeners();
  }

  void clearRecentSearches() {
    data.recentSearches.clear();
    _saveUserData();
    notifyListeners();
  }

  // --------------------------------------------------------------- reviews
  List<Review> reviewsFor(ReviewTarget t, String id) {
    final list = [
      ..._userReviews.where((r) => r.target == t && r.targetId == id),
      ...Catalog.seedReviews.where((r) => r.target == t && r.targetId == id),
    ];
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  List<Review> get myReviews {
    final u = user;
    if (u == null) return [];
    final l = _userReviews.where((r) => r.authorEmail == u.email).toList();
    l.sort((a, b) => b.date.compareTo(a.date));
    return l;
  }

  Review? myReviewFor(ReviewTarget t, String id) {
    final u = user;
    if (u == null) return null;
    for (final r in _userReviews) {
      if (r.target == t && r.targetId == id && r.authorEmail == u.email) return r;
    }
    return null;
  }

  ({double avg, int count}) ratingOf(ReviewTarget t, String id, double base, int baseCount) {
    final mine = _userReviews.where((r) => r.target == t && r.targetId == id);
    final n = mine.length;
    if (n == 0 && baseCount == 0) return (avg: 0, count: 0);
    final sum = base * baseCount + mine.fold<int>(0, (s, r) => s + r.rating);
    return (avg: sum / (baseCount + n), count: baseCount + n);
  }

  ({double avg, int count}) coffeeRating(Coffee c) => ratingOf(ReviewTarget.coffee, c.id, c.baseRating, c.baseCount);

  ({double avg, int count}) recipeRating(Recipe r) => ratingOf(ReviewTarget.recipe, r.id, r.baseRating, r.baseCount);

  /// Adds or updates the current user's review. Returns points earned.
  int submitReview(ReviewTarget t, String id, int rating, String comment) {
    final u = user;
    if (u == null) return 0;
    final existing = myReviewFor(t, id);
    if (existing != null) _userReviews.remove(existing);
    _userReviews.add(
      Review(
        id: existing?.id ?? 'u${DateTime.now().microsecondsSinceEpoch}',
        target: t,
        targetId: id,
        authorName: u.name,
        authorEmail: u.email,
        rating: rating,
        comment: comment.trim(),
        date: DateTime.now(),
      ),
    );
    _saveReviews();
    var earned = 0;
    if (existing == null) {
      earned = pointsPerReview;
      data.points += earned;
      _pushNotification(
        NotificationType.reward,
        const LText('حصلت على ١٠ نقاط 🎉', 'You earned 10 points 🎉'),
        const LText(
          'شكرًا لتقييمك! استبدل نقاطك من صفحة العروض والمكافآت.',
          'Thanks for your review! Redeem points in Offers & Rewards.',
        ),
      );
      _saveUserData();
    }
    notifyListeners();
    return earned;
  }

  void deleteReview(Review r) {
    _userReviews.removeWhere((x) => x.id == r.id);
    _saveReviews();
    notifyListeners();
  }

  // --------------------------------------------------------------- recipes
  List<Recipe> get allRecipes => [..._customRecipes.reversed, ...Catalog.recipes];

  List<Recipe> get myRecipes {
    final u = user;
    if (u == null) return [];
    return _customRecipes.where((r) => r.authorEmail == u.email).toList().reversed.toList();
  }

  Recipe? recipe(String? id) {
    if (id == null) return null;
    for (final r in allRecipes) {
      if (r.id == id) return r;
    }
    return null;
  }

  void addRecipe(Recipe r) {
    _customRecipes.add(r);
    _saveRecipes();
    notifyListeners();
  }

  void deleteRecipe(String id) {
    _customRecipes.removeWhere((r) => r.id == id);
    data.favRecipes.remove(id);
    _userReviews.removeWhere((r) => r.target == ReviewTarget.recipe && r.targetId == id);
    _saveRecipes();
    _saveReviews();
    _saveUserData();
    notifyListeners();
  }

  /// Recipes that fit a given coffee (its suggested recipe first).
  List<Recipe> recipesForCoffee(Coffee c) {
    final list = allRecipes.where((r) => c.methods.contains(r.method)).toList();
    list.sort((a, b) {
      if (a.id == c.recipeId) return -1;
      if (b.id == c.recipeId) return 1;
      return recipeRating(b).avg.compareTo(recipeRating(a).avg);
    });
    return list;
  }

  // --------------------------------------------------------------- rewards
  int get points => data.points;
  bool isRedeemed(String offerId) => data.redeemed.containsKey(offerId);
  String? couponCode(String offerId) => data.redeemed[offerId];

  /// Returns the coupon code on success, or throws a translation key.
  String redeem(Offer o) {
    if (!isLoggedIn) throw 'err_login_required';
    if (isRedeemed(o.id)) return data.redeemed[o.id]!;
    if (o.isExpired) throw 'err_offer_expired';
    if (o.pointsCost > data.points) throw 'err_not_enough_points';
    data.points -= o.pointsCost;
    final code = _generateCode();
    data.redeemed[o.id] = code;
    _pushNotification(
      NotificationType.reward,
      LText('تم استبدال: ${o.title.ar}', 'Redeemed: ${o.title.en}'),
      LText('رمز القسيمة: $code', 'Coupon code: $code'),
      targetId: o.id,
    );
    _saveUserData();
    notifyListeners();
    return code;
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final r = Random();
    return 'MHS-${List.generate(6, (_) => chars[r.nextInt(chars.length)]).join()}';
  }

  // --------------------------------------------------------- notifications
  void _pushNotification(NotificationType type, LText title, LText body, {String? targetId}) {
    data.personalNotifications.insert(
      0,
      AppNotification(
        id: 'p${DateTime.now().microsecondsSinceEpoch}',
        type: type,
        title: title,
        body: body,
        date: DateTime.now(),
        targetId: targetId,
      ),
    );
  }

  bool _enabled(NotificationType t) => switch (t) {
    NotificationType.newProduct => data.notifyNewProducts,
    NotificationType.offer => data.notifyOffers,
    NotificationType.reward => data.notifyRewards,
    NotificationType.system => true,
  };

  List<AppNotification> get notifications {
    final all = [...data.personalNotifications, ...Catalog.seedNotifications].where((n) => _enabled(n.type)).toList();
    all.sort((a, b) => b.date.compareTo(a.date));
    return all;
  }

  int get unreadCount => notifications.where((n) => !data.readNotifications.contains(n.id)).length;

  bool isRead(String id) => data.readNotifications.contains(id);

  void markRead(String id) {
    if (data.readNotifications.add(id)) {
      _saveUserData();
      notifyListeners();
    }
  }

  void markAllRead() {
    data.readNotifications.addAll(notifications.map((n) => n.id));
    _saveUserData();
    notifyListeners();
  }

  void setNotificationPref(NotificationType t, bool v) {
    switch (t) {
      case NotificationType.newProduct:
        data.notifyNewProducts = v;
      case NotificationType.offer:
        data.notifyOffers = v;
      case NotificationType.reward:
        data.notifyRewards = v;
      case NotificationType.system:
        break;
    }
    _saveUserData();
    notifyListeners();
  }
}
