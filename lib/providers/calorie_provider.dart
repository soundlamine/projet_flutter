// lib/providers/calorie_provider.dart
import 'package:flutter/material.dart';
import '../services/sqlite_service.dart';
import '../services/firebase_service.dart';
import '../models/food_entry.dart';

class CalorieProvider extends ChangeNotifier {
  final SQLiteService _sqlite;
  final FirebaseService _firebase;
  List<FoodEntry> entries = [];
  bool _isSyncing = false;

  CalorieProvider(this._sqlite, this._firebase);

  bool get isSyncing => _isSyncing;

  Future<void> loadEntries(String uid) async {
    entries = await _sqlite.getEntriesForUser(uid);
    notifyListeners();
  }

  Future<void> addEntry(FoodEntry e) async {
    // Insertion locale
    final localId = await _sqlite.insertEntry(e);
    
    // Créer une copie avec l'ID local pour Firebase
    final entryForFirebase = e.copyWith(id: localId);
    
    // Sync avec Firebase
    try {
      await _firebase.addRemoteEntry(entryForFirebase);
      
    } catch (e) {
      print(' Erreur Firebase add: $e');
    }
    
    await loadEntries(e.uid);
  }

  Future<void> updateEntry(FoodEntry updatedEntry) async {
    // Mise à jour locale
    await _sqlite.updateEntry(updatedEntry);
    
    // Sync avec Firebase
    try {
      if (updatedEntry.id != null) {
        await _firebase.updateRemoteEntry(updatedEntry);
       
      }
    } catch (e) {
      print(' Erreur Firebase update: $e');
    }
    
    await loadEntries(updatedEntry.uid);
  }

  Future<void> deleteEntry(int id) async {
    try {
      final entryToDelete = entries.firstWhere((e) => e.id == id);
      final uid = entryToDelete.uid;
      
      // Supprimer localement
      await _sqlite.deleteEntry(id);
      
      // Supprimer sur Firebase
      try {
        await _firebase.deleteRemoteEntry(id.toString());
        
      } catch (e) {
        print(' Erreur Firebase delete: $e');
      }
      
      await loadEntries(uid);
    } catch (e) {
      print(' Erreur suppression: $e');
      rethrow;
    }
  }

  Future<void> syncWithFirebase(String uid) async {
    if (_isSyncing) return;
    
    _isSyncing = true;
    notifyListeners();
    
    try {
      print(' Début synchronisation Firebase...');
      
      // 1. Récupérer les entrées de Firebase
      final firebaseEntries = await _firebase.getEntriesForUser(uid);
      print('${firebaseEntries.length} entrées récupérées de Firebase');
      
      // 2. Récupérer les entrées locales
      final localEntries = await _sqlite.getEntriesForUser(uid);
      print(' ${localEntries.length} entrées locales');
      
      // 3. Synchronisation Firebase → Local
      for (final firebaseEntry in firebaseEntries) {
        if (firebaseEntry.id != null) {
          final existsLocally = localEntries.any((local) => local.id == firebaseEntry.id);
          
          if (!existsLocally) {
            // Entrée Firebase non présente localement → ajouter
            await _sqlite.insertEntry(firebaseEntry);
            print(' Entrée ajoutée depuis Firebase: ${firebaseEntry.name}');
          } else {
            // Vérifier si besoin de mise à jour (par date de modification)
            final localEntry = localEntries.firstWhere((local) => local.id == firebaseEntry.id);
            if (firebaseEntry.date.isAfter(localEntry.date)) {
              await _sqlite.updateEntry(firebaseEntry);
             
            }
          }
        }
      }
      
      // 4. Synchronisation Local → Firebase (pour les entrées non synchronisées)
      for (final localEntry in localEntries) {
        final existsOnFirebase = firebaseEntries.any((fb) => fb.id == localEntry.id);
        
        if (!existsOnFirebase && localEntry.id != null) {
          try {
            await _firebase.addRemoteEntry(localEntry);
           
          } catch (e) {
            print(' Impossible d\'envoyer à Firebase: ${e.toString()}');
          }
        }
      }
      
      // 5. Recharger les entrées
      await loadEntries(uid);
      
    
      
      _isSyncing = false;
      notifyListeners();
      
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      print(' Erreur synchronisation: $e');
      rethrow;
    }
  }

  Future<void> toggleFavorite(int id, bool isFavorite) async {
    await _sqlite.toggleFavorite(id, isFavorite);
    
    // Mettre à jour sur Firebase
    try {
      final entry = entries.firstWhere((e) => e.id == id);
      await _firebase.updateRemoteEntry(entry.copyWith(isFavorite: isFavorite));
    } catch (e) {
      print(' Erreur Firebase toggleFavorite: $e');
    }
    
    if (entries.isNotEmpty) {
      await loadEntries(entries.first.uid);
    }
  }

  FoodEntry? getEntryById(int id) {
    try {
      return entries.firstWhere((e) => e.id == id);
    } catch (e) {
      return null;
    }
  }

  List<FoodEntry> getEntriesByDate(DateTime date, String uid) {
    return entries.where((e) => 
      e.uid == uid && 
      e.date.year == date.year &&
      e.date.month == date.month &&
      e.date.day == date.day
    ).toList();
  }

  List<FoodEntry> getEntriesByMealType(String mealType, String uid) {
    return entries.where((e) => 
      e.uid == uid && 
      e.mealType == mealType
    ).toList();
  }

  List<FoodEntry> getFavoriteEntries(String uid) {
    return entries.where((e) => 
      e.uid == uid && 
      e.isFavorite
    ).toList();
  }

  // Statistiques
  Map<String, double> getDailyStats(DateTime date, String uid) {
    final dailyEntries = getEntriesByDate(date, uid);
    
    double totalCalories = 0;
    double totalProteins = 0;
    double totalCarbs = 0;
    double totalFats = 0;
    
    for (final entry in dailyEntries) {
      totalCalories += entry.calories;
      totalProteins += entry.proteins ?? 0;
      totalCarbs += entry.carbs ?? 0;
      totalFats += entry.fats ?? 0;
    }
    
    return {
      'calories': totalCalories,
      'proteins': totalProteins,
      'carbs': totalCarbs,
      'fats': totalFats,
    };
  }

  Future<void> clearLocalData(String uid) async {
    await _sqlite.deleteAllEntries(uid);
    entries.clear();
    notifyListeners();
  }
}