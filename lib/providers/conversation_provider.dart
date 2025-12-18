import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation.dart';
import '../models/chat_message.dart';

class ConversationProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  List<Conversation> _conversations = [];
  Conversation? _currentConversation;
  
  List<Conversation> get conversations => List.unmodifiable(_conversations);
  Conversation? get currentConversation => _currentConversation;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  Future<void> initialize() async {
    await loadConversations();
  }
  
  Future<void> loadConversations() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;
      
      final snapshot = await _firestore
          .collection('conversations')
          .where('userId', isEqualTo: userId)
          .orderBy('updatedAt', descending: true)
          .get();
      
      _conversations = snapshot.docs
          .map((doc) => Conversation.fromMap({...doc.data(), 'id': doc.id}))
          .toList();
      
      print(' ${_conversations.length} conversations chargées');
      
    } catch (e) {
      print(' Erreur chargement conversations: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> createNewConversation() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;
    
    final welcomeMessage = ChatMessage(
      text: ' Bienvenu ! Je suis votre assistant nutritionnel.\n\nJe peux vous aider à trouver des idées de repas adaptées à vos objectifs !',
      isUser: false,
      timestamp: DateTime.now(),
    );
    
    final newConversation = Conversation(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      userId: userId,
      title: 'Nouvelle conversation',
      messages: [welcomeMessage],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _currentConversation = newConversation;
    await _saveConversation(newConversation);
    await loadConversations();
    notifyListeners();
    
    print(' Nouvelle conversation créée: ${newConversation.id}');
  }
  
  Future<void> loadConversation(String conversationId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final doc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();
      
      if (doc.exists) {
        _currentConversation = Conversation.fromMap({...doc.data()!, 'id': doc.id});
        print(' Conversation chargée: $conversationId');
      } else {
        print(' Conversation non trouvée: $conversationId');
        await createNewConversation();
      }
      
    } catch (e) {
      print(' Erreur chargement conversation: $e');
      await createNewConversation();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> addMessageToCurrentConversation(ChatMessage message) async {
    if (_currentConversation == null) {
      await createNewConversation();
    }
    
    final updatedMessages = List<ChatMessage>.from(_currentConversation!.messages)
      ..add(message);
    
    final updatedConversation = _currentConversation!.copyWith(
      messages: updatedMessages,
      updatedAt: DateTime.now(),
    );
    
    
    if (updatedMessages.length == 2 && message.isUser) {
      final firstQuestion = message.text;
      final title = firstQuestion.length > 30 
          ? '${firstQuestion.substring(0, 30)}...'
          : firstQuestion;
      updatedConversation.title = title;
    }
    
    _currentConversation = updatedConversation;
    
    await _saveConversation(updatedConversation);
    await loadConversations();
    notifyListeners();
    
    print(' Message ajouté à la conversation');
  }
  
  Future<void> _saveConversation(Conversation conversation) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversation.id)
          .set(conversation.toMap(), SetOptions(merge: true));
      
      // Mettre à jour la liste locale
      final index = _conversations.indexWhere((c) => c.id == conversation.id);
      if (index != -1) {
        _conversations[index] = conversation;
        _conversations.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      } else {
        _conversations.insert(0, conversation);
      }
      
    } catch (e) {
      print(' Erreur sauvegarde conversation: $e');
      throw Exception('Erreur de sauvegarde: $e');
    }
  }
  
  Future<void> deleteConversation(String conversationId) async {
    try {
      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .delete();
      
      _conversations.removeWhere((c) => c.id == conversationId);
      
      if (_currentConversation?.id == conversationId) {
        _currentConversation = null;
      }
      
      notifyListeners();
      print(' Conversation supprimée: $conversationId');
      
    } catch (e) {
      print(' Erreur suppression conversation: $e');
      throw Exception('Erreur de suppression: $e');
    }
  }
  
  Future<void> clearCurrentConversation() async {
    _currentConversation = null;
    notifyListeners();
    print(' Conversation courante effacée');
  }
  
  Future<void> renameConversation(String conversationId, String newTitle) async {
    try {
      if (newTitle.trim().isEmpty) return;
      
      final conversation = _conversations.firstWhere(
        (c) => c.id == conversationId,
        orElse: () => throw Exception('Conversation non trouvée'),
      );
      
      final updatedConversation = conversation.copyWith(
        title: newTitle,
        updatedAt: DateTime.now(),
      );
      
      await _saveConversation(updatedConversation);
      notifyListeners();
      
      print(' Conversation renommée: $newTitle');
      
    } catch (e) {
      print(' Erreur renommage conversation: $e');
      throw Exception('Erreur de renommage: $e');
    }
  }
  
  void clearAll() {
    _conversations.clear();
    _currentConversation = null;
    notifyListeners();
    print('✅ Toutes les conversations effacées localement');
  }
}