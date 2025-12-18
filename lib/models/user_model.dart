// lib/models/user_model.dart
class AppUser {
  final String uid;
  String? fullName;
  DateTime? birthDate;
  double? weight;
  double? height;
  String? gender;
  String? activityLevel;
  double? dailyCalorieGoal; 
  int? age; 

  AppUser({
    required this.uid,
    this.fullName,
    this.birthDate,
    this.weight,
    this.height,
    this.gender,
    this.activityLevel,
    this.dailyCalorieGoal,
    this.age,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'fullName': fullName,
      'birthDate': birthDate?.toIso8601String(),
      'weight': weight,
      'height': height,
      'gender': gender,
      'activityLevel': activityLevel,
      'dailyCalorieGoal': dailyCalorieGoal,
      'age': age,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    DateTime? birthDate;
    try {
      if (map['birthDate'] != null) {
        birthDate = DateTime.parse(map['birthDate']);
      }
    } catch (e) {
      print('Erreur parsing birthDate: $e');
    }

    // Calculer l'âge à partir de la date de naissance
    int? age;
    if (birthDate != null) {
      final now = DateTime.now();
      age = now.year - birthDate.year;
      if (now.month < birthDate.month || 
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }
    }

    return AppUser(
      uid: map['uid'] ?? '',
      fullName: map['fullName'],
      birthDate: birthDate,
      weight: map['weight'] != null ? (map['weight'] as num).toDouble() : null,
      height: map['height'] != null ? (map['height'] as num).toDouble() : null,
      gender: map['gender'],
      activityLevel: map['activityLevel'],
      dailyCalorieGoal: map['dailyCalorieGoal'] != null 
          ? (map['dailyCalorieGoal'] as num).toDouble() 
          : null,
      age: map['age'] ?? age,
    );
  }
}