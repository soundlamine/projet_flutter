import 'package:google_generative_ai/google_generative_ai.dart';
import 'dart:async';
import 'dart:math';

class GeminiService {
  static const List<String> API_KEYS = [
    "AIzaSyCQXXk_Akb-bKaOqcVXXV0tzlgWIwWdiFU",
    "AIzaSyDcurSdj-YUOv2KPYCmY_A2rNqMbk_KKoI",
    "AIzaSyBkN15G_mzV38CaJ9_sW9x_jge20vGtwsU",
  ];

  List<GenerativeModel> _models = [];
  bool _isInitialized = false;

  GeminiService() {
    _initializeSingleModel();
  }

  Future<void> _initializeSingleModel() async {
    try {
      print(' Initialisation GeminiService...');
      if (API_KEYS.isEmpty) throw Exception('No API keys configured');

      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: API_KEYS[0],
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.sexuallyExplicit, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.dangerousContent, HarmBlockThreshold.medium),
        ],
        generationConfig: GenerationConfig(
          temperature: 0.8,
          topK: 32,
          topP: 0.95,
          maxOutputTokens: 1500,
        ),
      );

      _models = [model];
      _isInitialized = true;
      print(' Service Gemini initialisé avec gemini-2.0-flash');
    } catch (e) {
      print(' ERREUR CRITIQUE lors de l\'initialisation: $e');
      _isInitialized = false;
    }
  }

  Future<String> generateMealSuggestions({
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> dailyStats,
    required List<Map<String, dynamic>> todayEntries,
    required String mealType,
    required String userQuery,
  }) async {
    if (!_isInitialized || _models.isEmpty) {
      print(' Service non initialisé, utilisation des suggestions par défaut.');
      return _defaultMealSuggestions(mealType);
    }

    try {
      final prompt = _buildSimplePrompt(
        userProfile: userProfile,
        dailyStats: dailyStats,
        todayEntries: todayEntries,
        mealType: mealType,
        userQuery: userQuery,
      );

      print(' Envoi de la requête à Gemini...');
      final responseFuture = _models[0].generateContent([Content.text(prompt)]);
      final response = await responseFuture.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('⏰ La requête a expiré après 30 secondes'),
      );

      if (response.text == null || response.text!.isEmpty) {
        throw Exception('Réponse vide du serveur');
      }

      print('Réponse reçue (${response.text!.length} caractères)');
      return response.text!;
    } on TimeoutException {
      print(' Timeout: Le service a mis trop de temps à répondre');
      return _defaultMealSuggestions(mealType);
    } catch (e) {
      print(' Erreur lors de l\'appel Gemini: $e');
      return _defaultMealSuggestions(mealType);
    }
  }

  String _buildSimplePrompt({
    required Map<String, dynamic> userProfile,
    required Map<String, dynamic> dailyStats,
    required List<Map<String, dynamic>> todayEntries,
    required String mealType,
    required String userQuery,
  }) {
    final consumedCalories = dailyStats['calories'] ?? 0;
    final calorieGoal = userProfile['dailyCalorieGoal'] ?? 2000;
    final remainingCalories = max(0, calorieGoal - consumedCalories);
    final mealTypeFrench = _getMealTypeFrench(mealType);

    return '''
Vous êtes un nutritionniste professionnel français.

Contexte:
- Objectif quotidien: $calorieGoal kcal
- Déjà consommé: ${consumedCalories.toInt()} kcal
- Restant pour aujourd'hui: ${remainingCalories.toInt()} kcal
- Repas demandé: $mealTypeFrench

Question de l'utilisateur: "$userQuery"

Veuillez suggérer 3 options de repas adaptées au contexte calorique.
Pour chaque option, indiquez:
🍽️ Nom du repas
🔥 Calories estimées
⏱️ Temps de préparation
🥗 Ingrédients principaux (3-5 max)
💪 Avantage nutritionnel principal

Formulez votre réponse de manière claire et pratique.
''';
  }

  String _getMealTypeFrench(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Petit-déjeuner';
      case 'lunch':
        return 'Déjeuner';
      case 'dinner':
        return 'Dîner';
      case 'snack':
        return 'Collation';
      default:
        return 'Repas';
    }
  }

  String _defaultMealSuggestions(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return '''
🥞 Petit-déjeuner :
1️⃣ Flocons d'avoine avec 🍓 fruits et 🥛 yaourt nature - 🔥 350 kcal 💪 Énergie durable
2️⃣ Toast complet avec 🥑 avocat et 🥚 œuf poché - 🔥 300 kcal 💪 Protéines
3️⃣ Smoothie 🍌 banane + 🌿 épinards + 🥛 protéine - 🔥 250 kcal 💪 Vitamines et fibres
''';
      case 'lunch':
        return '''
🥗 Déjeuner :
1️⃣ Poulet grillé 🍗 avec 🍚 riz complet et 🥦 légumes - 🔥 500 kcal 💪 Protéines et fibres
2️⃣ Salade quinoa 🍲, pois chiches 🌱, tomates 🍅, feta 🧀 - 🔥 450 kcal 💪 Riche en protéines végétales
3️⃣ Sandwich complet 🥪 au thon 🐟 avec crudités 🥒 - 🔥 400 kcal 💪 Protéines et oméga-3
''';
      case 'dinner':
        return '''
🍽️ Dîner :
1️⃣ Saumon au four 🐟 avec 🥦 brocoli et 🍠 patate douce - 🔥 500 kcal 💪 Oméga-3 et fibres
2️⃣ Omelette aux légumes 🥚 + 🥬 et pain complet 🍞 - 🔥 400 kcal 💪 Protéines et vitamines
3️⃣ Tofu sauté 🍲 aux légumes 🥕 et 🍚 riz - 🔥 450 kcal 💪 Protéines végétales
''';
      case 'snack':
        return '''
🍏 Collations :
1️⃣ Pomme 🍎 avec 2 c. à soupe de beurre d'amande 🥜 - 🔥 150 kcal 💪 Fibres
2️⃣ Yaourt nature 🥛 avec fruits rouges 🍓 - 🔥 120 kcal 💪 Protéines et vitamines
3️⃣ Poignée de noix et graines 🌰 - 🔥 200 kcal 💪 Énergie rapide
''';
      default:
        return '💧 Repas par défaut: eau et fruits 🍏.';
    }
  }

  Future<bool> testApiConnection() async {
    try {
      if (!_isInitialized || _models.isEmpty) return false;
      final testResponse = await _models[0]
          .generateContent([Content.text('Test')])
          .timeout(const Duration(seconds: 10));
      return testResponse.text != null;
    } catch (e) {
      print(' Test de connexion échoué: $e');
      return false;
    }
  }
}
