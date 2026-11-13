import '../l10n/l10n.dart';

enum RoastLevel { light, medium, dark }

enum ProcessType { washed, natural, honey, anaerobic }

enum BrewMethod { v60, chemex, espresso, aeropress, frenchPress, coldBrew, moka, kalita }

enum Difficulty { easy, medium, hard }

enum NotificationType { newProduct, offer, reward, system }

enum ReviewTarget { coffee, recipe }

class Roaster {
  final String id;
  final LText name;
  final LText city;
  final LText about;
  final int since;
  const Roaster({required this.id, required this.name, required this.city, required this.about, required this.since});
}

class Origin {
  final String id;
  final LText name;
  final String flag;
  final LText about;
  const Origin({required this.id, required this.name, required this.flag, required this.about});
}

class Coffee {
  final String id;
  final String roasterId;
  final String originId;
  final LText name;
  final LText region;
  final LText description;
  final List<LText> notes;
  final ProcessType process;
  final RoastLevel roast;
  final double price;
  final int weight;
  final String altitude;
  final LText variety;
  final List<BrewMethod> methods;
  final double baseRating;
  final int baseCount;
  final bool isNew;
  final String? recipeId;
  final bool inStock;

  const Coffee({
    required this.id,
    required this.roasterId,
    required this.originId,
    required this.name,
    required this.region,
    required this.description,
    required this.notes,
    required this.process,
    required this.roast,
    required this.price,
    required this.weight,
    required this.altitude,
    required this.variety,
    required this.methods,
    required this.baseRating,
    required this.baseCount,
    this.isNew = false,
    this.recipeId,
    this.inStock = true,
  });
}

class BrewStep {
  final LText text;
  final int seconds;

  /// Total water poured by the end of this step (scaled by the calculator).
  final int? pourTo;
  const BrewStep(this.text, this.seconds, {this.pourTo});

  Map<String, dynamic> toJson() => {'text': text.toJson(), 'seconds': seconds, 'pourTo': pourTo};
  factory BrewStep.fromJson(Map<String, dynamic> j) => BrewStep(
    LText.fromJson(Map<String, dynamic>.from(j['text'] as Map)),
    j['seconds'] as int,
    pourTo: j['pourTo'] as int?,
  );
}

class Recipe {
  final String id;
  final BrewMethod method;
  final LText title;
  final LText subtitle;
  final double coffee; // grams
  final int water; // ml
  final int ice; // grams of ice (iced recipes)
  final LText grind;
  final String temp; // °C range e.g. "92-94"
  final int minutes;
  final Difficulty difficulty;
  final String author;
  final String? authorEmail; // set for user created recipes
  final List<BrewStep> steps;
  final double baseRating;
  final int baseCount;
  final String? coffeeId;
  final DateTime? createdAt;

  const Recipe({
    required this.id,
    required this.method,
    required this.title,
    required this.subtitle,
    required this.coffee,
    required this.water,
    this.ice = 0,
    required this.grind,
    required this.temp,
    required this.minutes,
    required this.difficulty,
    required this.author,
    this.authorEmail,
    required this.steps,
    this.baseRating = 0,
    this.baseCount = 0,
    this.coffeeId,
    this.createdAt,
  });

  bool get isCustom => authorEmail != null;

  /// Brew ratio as "1:16".
  double get ratio => (water + ice) / coffee;

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method.name,
    'title': title.toJson(),
    'subtitle': subtitle.toJson(),
    'coffee': coffee,
    'water': water,
    'ice': ice,
    'grind': grind.toJson(),
    'temp': temp,
    'minutes': minutes,
    'difficulty': difficulty.name,
    'author': author,
    'authorEmail': authorEmail,
    'steps': steps.map((s) => s.toJson()).toList(),
    'coffeeId': coffeeId,
    'createdAt': createdAt?.toIso8601String(),
  };

  factory Recipe.fromJson(Map<String, dynamic> j) => Recipe(
    id: j['id'] as String,
    method: BrewMethod.values.byName(j['method'] as String),
    title: LText.fromJson(Map<String, dynamic>.from(j['title'] as Map)),
    subtitle: LText.fromJson(Map<String, dynamic>.from(j['subtitle'] as Map)),
    coffee: (j['coffee'] as num).toDouble(),
    water: j['water'] as int,
    ice: (j['ice'] as int?) ?? 0,
    grind: LText.fromJson(Map<String, dynamic>.from(j['grind'] as Map)),
    temp: j['temp'] as String,
    minutes: j['minutes'] as int,
    difficulty: Difficulty.values.byName(j['difficulty'] as String),
    author: j['author'] as String,
    authorEmail: j['authorEmail'] as String?,
    steps: (j['steps'] as List).map((s) => BrewStep.fromJson(Map<String, dynamic>.from(s as Map))).toList(),
    coffeeId: j['coffeeId'] as String?,
    createdAt: j['createdAt'] == null ? null : DateTime.parse(j['createdAt'] as String),
  );
}

class Review {
  final String id;
  final ReviewTarget target;
  final String targetId;
  final String authorName;
  final String? authorEmail;
  final int rating;
  final String comment;
  final DateTime date;

  const Review({
    required this.id,
    required this.target,
    required this.targetId,
    required this.authorName,
    this.authorEmail,
    required this.rating,
    required this.comment,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'target': target.name,
    'targetId': targetId,
    'authorName': authorName,
    'authorEmail': authorEmail,
    'rating': rating,
    'comment': comment,
    'date': date.toIso8601String(),
  };

  factory Review.fromJson(Map<String, dynamic> j) => Review(
    id: j['id'] as String,
    target: ReviewTarget.values.byName(j['target'] as String),
    targetId: j['targetId'] as String,
    authorName: j['authorName'] as String,
    authorEmail: j['authorEmail'] as String?,
    rating: j['rating'] as int,
    comment: (j['comment'] as String?) ?? '',
    date: DateTime.parse(j['date'] as String),
  );
}

class Offer {
  final String id;
  final String roasterId;
  final LText title;
  final LText description;
  final LText terms;
  final int discount; // percent
  final int pointsCost; // 0 = free offer, >0 = reward redeemed with points
  final DateTime expires;

  const Offer({
    required this.id,
    required this.roasterId,
    required this.title,
    required this.description,
    required this.terms,
    required this.discount,
    required this.pointsCost,
    required this.expires,
  });

  bool get isReward => pointsCost > 0;
  bool get isExpired => DateTime.now().isAfter(expires);
}

class AppNotification {
  final String id;
  final NotificationType type;
  final LText title;
  final LText body;
  final DateTime date;
  final String? targetId;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.date,
    this.targetId,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'title': title.toJson(),
    'body': body.toJson(),
    'date': date.toIso8601String(),
    'targetId': targetId,
  };

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
    id: j['id'] as String,
    type: NotificationType.values.byName(j['type'] as String),
    title: LText.fromJson(Map<String, dynamic>.from(j['title'] as Map)),
    body: LText.fromJson(Map<String, dynamic>.from(j['body'] as Map)),
    date: DateTime.parse(j['date'] as String),
    targetId: j['targetId'] as String?,
  );
}

class UserAccount {
  final String email;
  final String name;
  final String passwordHash;
  final String phone;
  final String city;
  final DateTime createdAt;

  const UserAccount({
    required this.email,
    required this.name,
    required this.passwordHash,
    this.phone = '',
    this.city = '',
    required this.createdAt,
  });

  String get initial => name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

  UserAccount copyWith({String? name, String? passwordHash, String? phone, String? city}) => UserAccount(
    email: email,
    name: name ?? this.name,
    passwordHash: passwordHash ?? this.passwordHash,
    phone: phone ?? this.phone,
    city: city ?? this.city,
    createdAt: createdAt,
  );

  Map<String, dynamic> toJson() => {
    'email': email,
    'name': name,
    'passwordHash': passwordHash,
    'phone': phone,
    'city': city,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserAccount.fromJson(Map<String, dynamic> j) => UserAccount(
    email: j['email'] as String,
    name: j['name'] as String,
    passwordHash: j['passwordHash'] as String,
    phone: (j['phone'] as String?) ?? '',
    city: (j['city'] as String?) ?? '',
    createdAt: DateTime.parse(j['createdAt'] as String),
  );
}

/// Everything that belongs to one account (or to the guest) on this device.
class UserData {
  Set<String> favCoffees;
  Set<String> favRecipes;
  int points;
  Map<String, String> redeemed; // offerId -> coupon code
  Set<String> readNotifications;
  List<AppNotification> personalNotifications;
  bool notifyNewProducts;
  bool notifyOffers;
  bool notifyRewards;
  List<String> recentSearches;

  UserData({
    Set<String>? favCoffees,
    Set<String>? favRecipes,
    this.points = 0,
    Map<String, String>? redeemed,
    Set<String>? readNotifications,
    List<AppNotification>? personalNotifications,
    this.notifyNewProducts = true,
    this.notifyOffers = true,
    this.notifyRewards = true,
    List<String>? recentSearches,
  }) : favCoffees = favCoffees ?? <String>{},
       favRecipes = favRecipes ?? <String>{},
       redeemed = redeemed ?? <String, String>{},
       readNotifications = readNotifications ?? <String>{},
       personalNotifications = personalNotifications ?? <AppNotification>[],
       recentSearches = recentSearches ?? <String>[];

  Map<String, dynamic> toJson() => {
    'favCoffees': favCoffees.toList(),
    'favRecipes': favRecipes.toList(),
    'points': points,
    'redeemed': redeemed,
    'readNotifications': readNotifications.toList(),
    'personalNotifications': personalNotifications.map((n) => n.toJson()).toList(),
    'notifyNewProducts': notifyNewProducts,
    'notifyOffers': notifyOffers,
    'notifyRewards': notifyRewards,
    'recentSearches': recentSearches,
  };

  factory UserData.fromJson(Map<String, dynamic> j) => UserData(
    favCoffees: Set<String>.from(j['favCoffees'] as List? ?? const []),
    favRecipes: Set<String>.from(j['favRecipes'] as List? ?? const []),
    points: (j['points'] as int?) ?? 0,
    redeemed: Map<String, String>.from(j['redeemed'] as Map? ?? const {}),
    readNotifications: Set<String>.from(j['readNotifications'] as List? ?? const []),
    personalNotifications: ((j['personalNotifications'] as List?) ?? const [])
        .map((n) => AppNotification.fromJson(Map<String, dynamic>.from(n as Map)))
        .toList(),
    notifyNewProducts: (j['notifyNewProducts'] as bool?) ?? true,
    notifyOffers: (j['notifyOffers'] as bool?) ?? true,
    notifyRewards: (j['notifyRewards'] as bool?) ?? true,
    recentSearches: List<String>.from(j['recentSearches'] as List? ?? const []),
  );
}
