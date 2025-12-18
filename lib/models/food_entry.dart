import 'dart:convert';

class FoodEntry {
  final int? id;
  final String uid;
  final String name;
  final String? category;
  final double calories;
  final double? proteins;
  final double? carbs;
  final double? fats;
  final double? fiber;
  final double? sugar;
  final double servingSize;
  final String? servingUnit;
  final String? mealType;
  final String? notes;
  final DateTime date;
  final DateTime? createdAt;
  final bool isFavorite;
  final bool notificationEnabled;
  final String? notificationId;

  FoodEntry({
    this.id,
    required this.uid,
    required this.name,
    this.category,
    required this.calories,
    this.proteins,
    this.carbs,
    this.fats,
    this.fiber,
    this.sugar,
    this.servingSize = 100.0,
    this.servingUnit = 'g',
    this.mealType,
    this.notes,
    required this.date,
    this.notificationEnabled = false,
    this.notificationId,
    DateTime? createdAt,
    this.isFavorite = false,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'category': category,
      'calories': calories,
      'proteins': proteins,
      'carbs': carbs,
      'fats': fats,
      'fiber': fiber,
      'sugar': sugar,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'mealType': mealType,
      'notes': notes,
      'date': date.toIso8601String(),
      'createdAt': createdAt?.toIso8601String() ?? DateTime.now().toIso8601String(),
      'isFavorite': isFavorite ? 1 : 0,
      'notificationEnabled': notificationEnabled ? 1 : 0,
      'notificationId': notificationId,
    };
  }

  static FoodEntry fromMap(Map<String, dynamic> map) {
    // Gestion des valeurs nulles pour les nombres
    double safeDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        try {
          return double.parse(value);
        } catch (_) {
          return 0.0;
        }
      }
      return 0.0;
    }

    return FoodEntry(
      id: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      uid: map['uid']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      category: map['category']?.toString(),
      calories: safeDouble(map['calories']),
      proteins: map['proteins'] != null ? safeDouble(map['proteins']) : null,
      carbs: map['carbs'] != null ? safeDouble(map['carbs']) : null,
      fats: map['fats'] != null ? safeDouble(map['fats']) : null,
      fiber: map['fiber'] != null ? safeDouble(map['fiber']) : null,
      sugar: map['sugar'] != null ? safeDouble(map['sugar']) : null,
      servingSize: safeDouble(map['servingSize'] ?? 100.0),
      servingUnit: map['servingUnit']?.toString() ?? 'g',
      mealType: map['mealType']?.toString(),
      notes: map['notes']?.toString(),
      date: map['date'] != null 
          ? DateTime.tryParse(map['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      createdAt: map['createdAt'] != null 
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
      isFavorite: (map['isFavorite'] ?? 0) == 1,
      notificationEnabled: (map['notificationEnabled'] ?? 0) == 1,
      notificationId: map['notificationId']?.toString(),
    );
  }

  String toJson() => json.encode(toMap());

  static FoodEntry fromJson(String source) => fromMap(json.decode(source));

  double get caloriesPer100g {
    return servingSize > 0 ? (calories / servingSize) * 100 : 0;
  }

  String get formattedDate {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String get formattedTime {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Map<String, double> get macronutrients {
    return {
      'proteins': proteins ?? 0.0,
      'carbs': carbs ?? 0.0,
      'fats': fats ?? 0.0,
    };
  }

  double get totalMacros {
    return (proteins ?? 0.0) + (carbs ?? 0.0) + (fats ?? 0.0);
  }

  FoodEntry copyWith({
    int? id,
    String? uid,
    String? name,
    String? category,
    double? calories,
    double? proteins,
    double? carbs,
    double? fats,
    double? fiber,
    double? sugar,
    double? servingSize,
    String? servingUnit,
    String? mealType,
    String? notes,
    DateTime? date,
    DateTime? createdAt,
    bool? isFavorite,
    bool? notificationEnabled,
    String? notificationId,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      category: category ?? this.category,
      calories: calories ?? this.calories,
      proteins: proteins ?? this.proteins,
      carbs: carbs ?? this.carbs,
      fats: fats ?? this.fats,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      mealType: mealType ?? this.mealType,
      notes: notes ?? this.notes,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      isFavorite: isFavorite ?? this.isFavorite,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      notificationId: notificationId ?? this.notificationId,
    );
  }

  @override
  String toString() {
    return 'FoodEntry(id: $id, name: $name, calories: $calories, date: $date, notificationEnabled: $notificationEnabled, notificationId: $notificationId)';
  }
}

enum MealType {
  breakfast('Petit-déjeuner'),
  lunch('Déjeuner'),
  dinner('Dîner'),
  snack('Collation');

  final String label;
  const MealType(this.label);
}

enum FoodCategory {
  fruits('Fruits'),
  vegetables('Légumes'),
  grains('Céréales'),
  proteins('Protéines'),
  dairy('Produits laitiers'),
  fats('Lipides'),
  sweets('Sucreries'),
  beverages('Boissons'),
  other('Autre');

  final String label;
  const FoodCategory(this.label);
}

extension FoodEntryExtensions on FoodEntry {
  String get categoryLabel {
    if (category == null) return 'Non catégorisé';
    try {
      return FoodCategory.values
          .firstWhere((c) => c.name == category)
          .label;
    } catch (_) {
      return category!;
    }
  }

  String get mealTypeLabel {
    if (mealType == null) return 'Non spécifié';
    try {
      return MealType.values
          .firstWhere((m) => m.name == mealType)
          .label;
    } catch (_) {
      return mealType!;
    }
  }

  double? get proteinPercentage {
    if (proteins == null || totalMacros == 0) return null;
    return (proteins! / totalMacros) * 100;
  }

  double? get carbPercentage {
    if (carbs == null || totalMacros == 0) return null;
    return (carbs! / totalMacros) * 100;
  }

  double? get fatPercentage {
    if (fats == null || totalMacros == 0) return null;
    return (fats! / totalMacros) * 100;
  }
}