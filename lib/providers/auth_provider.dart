import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseService _service;

  User? firebaseUser;
  AppUser? profile;
  bool isLoading = false;

  AuthProvider(this._service) {
    _init();
  }

  // ================= INIT =================
  void _init() {
    _service.authStateChanges().listen((user) async {
      firebaseUser = user;

      if (user == null) {
        profile = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      isLoading = true;
      notifyListeners();

      await _loadUserProfile(user.uid);
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    try {
      profile = await _service.getUserProfile(uid);
    } catch (_) {
      profile = null;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool get isAuthenticated => firebaseUser != null;

  // ================= CALORIE =================
  double _calculateDailyCalorieGoal(AppUser user) {
    if (user.weight == null ||
        user.height == null ||
        user.age == null ||
        user.gender == null ||
        user.activityLevel == null) {
      return 2000.0;
    }

    final bmr = user.gender == 'Homme'
        ? 88.362 +
            (13.397 * user.weight!) +
            (4.799 * user.height!) -
            (5.677 * user.age!)
        : 447.593 +
            (9.247 * user.weight!) +
            (3.098 * user.height!) -
            (4.330 * user.age!);

    const activityFactors = {
      'sedentary': 1.2,
      'light': 1.375,
      'moderate': 1.55,
      'active': 1.725,
      'very_active': 1.9,
    };

    return (bmr * (activityFactors[user.activityLevel] ?? 1.2))
        .roundToDouble();
  }

  // ================= REGISTER =================
  Future<String?> register({
    required String email,
    required String password,
    required String fullName,
    required DateTime birthDate,
    required double weight,
    required double height,
    required String gender,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      final cred = await _service.signUpWithEmail(email, password);
      final uid = cred.user!.uid;

      final now = DateTime.now();
      int age = now.year - birthDate.year;
      if (now.month < birthDate.month ||
          (now.month == birthDate.month && now.day < birthDate.day)) {
        age--;
      }

      final appUser = AppUser(
        uid: uid,
        fullName: fullName,
        birthDate: birthDate,
        weight: weight,
        height: height,
        gender: gender,
        activityLevel: 'sedentary',
        age: age,
      );

      appUser.dailyCalorieGoal = _calculateDailyCalorieGoal(appUser);

      await _service.saveUserProfile(appUser);
      profile = appUser;

      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'Cette adresse email est déjà utilisée.';
        case 'invalid-email':
          return 'Format d\'email invalide.';
        case 'weak-password':
          return 'Le mot de passe est trop faible.';
        default:
          return 'Erreur lors de l\'inscription.';
      }
    } catch (_) {
      return 'Erreur inattendue.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= LOGIN  =================
  Future<String?> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _service.signInWithEmail(email, password);

     
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
          return 'Email ou mot de passe incorrect.';
        case 'user-disabled':
          return 'Ce compte a été désactivé.';
        case 'too-many-requests':
          return 'Trop de tentatives. Réessayez plus tard.';
        case 'network-request-failed':
          return 'Erreur réseau.';
        case 'invalid-email':
          return 'Email invalide.';
        default:
          return 'Erreur de connexion.';
      }
    } catch (_) {
      return 'Erreur inattendue.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ================= LOGOUT =================
  Future<void> logout() async {
    await _service.signOut();
    firebaseUser = null;
    profile = null;
    notifyListeners();
  }

  // ================= RESET PASSWORD =================
  Future<String?> resetPassword(String email) async {
    try {
      await _service.resetPassword(email);
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          return 'Email invalide.';
        case 'user-not-found':
          return 'Aucun compte associé.';
        case 'too-many-requests':
          return 'Trop de demandes.';
        default:
          return 'Impossible d\'envoyer l\'email.';
      }
    } catch (_) {
      return 'Erreur réseau.';
    }
  }

  // ================= UPDATE PROFILE =================
  Future<void> updateProfile({
    String? fullName,
    int? age,
    double? weight,
    double? height,
    String? gender,
    String? activityLevel,
    double? dailyCalorieGoal,
  }) async {
    if (profile == null || firebaseUser == null) return;

    if (fullName != null) profile!.fullName = fullName;
    if (age != null) profile!.age = age;
    if (weight != null) profile!.weight = weight;
    if (height != null) profile!.height = height;
    if (gender != null) profile!.gender = gender;
    if (activityLevel != null) profile!.activityLevel = activityLevel;

    profile!.dailyCalorieGoal =
        dailyCalorieGoal ?? _calculateDailyCalorieGoal(profile!);

    await _service.saveUserProfile(profile!);
    notifyListeners();
  }
}
