import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../models/food_entry.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  // ================= AUTHENTIFICATION =================

  Future<UserCredential> signUpWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          throw Exception('Cet email est déjà utilisé. Essayez de vous connecter.');
        case 'invalid-email':
          throw Exception('Veuillez saisir une adresse email valide.');
        case 'weak-password':
          throw Exception('Le mot de passe est trop faible (minimum 6 caractères).');
        case 'operation-not-allowed':
          throw Exception('L’inscription par email est désactivée.');
        default:
          throw Exception('Impossible de créer le compte. Veuillez réessayer.');
      }
    }
  }

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('Adresse email incorrecte.');
        case 'user-disabled':
          throw Exception('Ce compte a été désactivé. Contactez le support.');
        case 'user-not-found':
          throw Exception('Aucun compte trouvé avec cet email.');
        case 'wrong-password':
          throw Exception('Mot de passe incorrect.');
        case 'too-many-requests':
          throw Exception(
            'Trop de tentatives. Veuillez attendre quelques minutes.',
          );
        default:
          throw Exception('Connexion impossible. Vérifiez vos informations.');
      }
    }
  }

  Future<void> signOut() async => await _auth.signOut();

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  // ================= MOT DE PASSE OUBLIÉ =================

  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          throw Exception('Veuillez entrer une adresse email valide.');
        case 'user-not-found':
          throw Exception('Aucun compte associé à cet email.');
        case 'too-many-requests':
          throw Exception(
            'Trop de demandes envoyées. Réessayez plus tard.',
          );
        default:
          throw Exception(
            'Impossible d’envoyer l’email de réinitialisation.',
          );
      }
    } catch (e) {
      throw Exception(
        'Erreur de connexion. Vérifiez votre accès internet.',
      );
    }
  }

  // ================= PROFIL UTILISATEUR =================

  Future<void> saveUserProfile(AppUser user) async {
    try {
      await _fs.collection('users').doc(user.uid).set(user.toMap());
    } catch (e) {
      throw Exception(
        'Erreur lors de l’enregistrement du profil utilisateur.',
      );
    }
  }

  Future<AppUser?> getUserProfile(String uid) async {
    try {
      final doc = await _fs.collection('users').doc(uid).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Erreur récupération profil: $e');
      return null;
    }
  }

  // ================= ENTRÉES ALIMENTAIRES =================

  Future<void> addRemoteEntry(FoodEntry entry) async {
    try {
      if (entry.id == null) {
        throw Exception('Identifiant de l’entrée invalide.');
      }

      await _fs
          .collection('users')
          .doc(entry.uid)
          .collection('food_entries')
          .doc(entry.id.toString())
          .set({
        ...entry.toMap(),
        'firebaseId': entry.id.toString(),
        'syncedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur Firebase addRemoteEntry: $e');
      rethrow;
    }
  }

  Future<void> updateRemoteEntry(FoodEntry entry) async {
    try {
      if (entry.id == null) {
        throw Exception('Identifiant de l’entrée invalide.');
      }

      await _fs
          .collection('users')
          .doc(entry.uid)
          .collection('food_entries')
          .doc(entry.id.toString())
          .update({
        'name': entry.name,
        'category': entry.category,
        'calories': entry.calories,
        'proteins': entry.proteins,
        'carbs': entry.carbs,
        'fats': entry.fats,
        'servingSize': entry.servingSize,
        'servingUnit': entry.servingUnit,
        'mealType': entry.mealType,
        'notes': entry.notes,
        'date': entry.date.toIso8601String(),
        'isFavorite': entry.isFavorite,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Erreur Firebase updateRemoteEntry: $e');
      rethrow;
    }
  }

  Future<void> deleteRemoteEntry(String entryId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _fs
          .collection('users')
          .doc(user.uid)
          .collection('food_entries')
          .doc(entryId)
          .delete();
    } catch (e) {
      print('Erreur Firebase deleteRemoteEntry: $e');
      rethrow;
    }
  }

  Future<List<FoodEntry>> getEntriesForUser(String uid) async {
    try {
      final querySnapshot = await _fs
          .collection('users')
          .doc(uid)
          .collection('food_entries')
          .orderBy('date', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        int? entryId =
            data['firebaseId'] != null ? int.tryParse(data['firebaseId']) : null;

        return FoodEntry.fromMap({
          ...data,
          'id': entryId ?? data['id'],
        });
      }).toList();
    } catch (e) {
      print('Erreur Firebase getEntriesForUser: $e');
      return [];
    }
  }

  // ================= SYNCHRONISATION =================

  Future<Map<String, dynamic>> syncUserData(String uid) async {
    try {
      return {
        'entries': await getEntriesForUser(uid),
        'profile': await getUserProfile(uid),
        'lastSync': DateTime.now(),
      };
    } catch (e) {
      print('Erreur synchronisation: $e');
      rethrow;
    }
  }

  // ================= CONNEXION =================

  Future<bool> checkConnection() async {
    try {
      await _fs.collection('test').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }

  // ================= SUPPRESSION DONNÉES =================

  Future<void> deleteAllUserData(String uid) async {
    try {
      final entriesSnapshot = await _fs
          .collection('users')
          .doc(uid)
          .collection('food_entries')
          .get();

      for (final doc in entriesSnapshot.docs) {
        await doc.reference.delete();
      }

      await _fs.collection('users').doc(uid).delete();
    } catch (e) {
      print('Erreur deleteAllUserData: $e');
      rethrow;
    }
  }
}
