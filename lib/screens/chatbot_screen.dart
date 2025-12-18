import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/calorie_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/conversation_provider.dart';
import '../services/gemini_service.dart';
import '../models/chat_message.dart';
import '../screens/conversation_history_screen.dart';
class ChatbotScreen extends StatefulWidget {
  final String? conversationId;
  
  const ChatbotScreen({Key? key, this.conversationId}) : super(key: key);

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String _selectedMealType = 'lunch';
  List<MealSuggestion> _suggestions = [];
  int? _selectedSuggestionIndex;
  bool _isInitialized = false;
  
  final List<Map<String, String>> _mealTypes = [
    {'value': 'breakfast', 'label': '🍳 Petit-déj'},
    {'value': 'lunch', 'label': '🥗 Déjeuner'},
    {'value': 'dinner', 'label': '🍽️ Dîner'},
    {'value': 'snack', 'label': '🍎 Collation'},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  Future<void> _initializeChat() async {
    final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
    
    if (widget.conversationId != null) {
      // Charger une conversation existante
      await conversationProvider.loadConversation(widget.conversationId!);
      
      setState(() {
        _messages.addAll(conversationProvider.currentConversation?.messages ?? []);
        _isInitialized = true;
      });
    } else {
      // Utiliser la conversation courante ou en créer une nouvelle
      if (conversationProvider.currentConversation == null) {
        await conversationProvider.createNewConversation();
      }
      
      setState(() {
        _messages.addAll(conversationProvider.currentConversation!.messages);
        _isInitialized = true;
      });
    }
  }

  Future<void> _sendMessage() async {
    if (!_isInitialized) return;
    
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final userMessage = ChatMessage(
      text: message,
      isUser: true,
      timestamp: DateTime.now(),
    );
    
    _addUserMessage(userMessage);
    _messageController.clear();

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final cp = Provider.of<CalorieProvider>(context, listen: false);
  
    
    final today = DateTime.now();
    final dailyStats = cp.getDailyStats(today, auth.firebaseUser?.uid ?? '');
    
    final todayEntries = cp.entries.where((entry) {
      return entry.date.year == today.year &&
          entry.date.month == today.month &&
          entry.date.day == today.day;
    }).toList();

    final todayEntriesFormatted = todayEntries.map((entry) {
      return {
        'name': entry.name,
        'calories': entry.calories,
        'mealType': entry.mealType,
        'proteins': entry.proteins,
        'category': entry.category,
      };
    }).toList();

    final userProfile = {
      'fullName': auth.profile?.fullName,
      'age': auth.profile?.age,
      'weight': auth.profile?.weight,
      'height': auth.profile?.height,
      'gender': auth.profile?.gender,
      'activityLevel': auth.profile?.activityLevel,
      'dailyCalorieGoal': auth.profile?.dailyCalorieGoal,
    };

    setState(() {
      _isLoading = true;
      _suggestions.clear();
      _selectedSuggestionIndex = null;
    });

    try {
      final response = await _geminiService.generateMealSuggestions(
        userProfile: userProfile,
        dailyStats: dailyStats,
        todayEntries: todayEntriesFormatted,
        mealType: _selectedMealType,
        userQuery: message,
      );

      // Parser les suggestions du bot
      _parseSuggestions(response);
      
      final botMessage = ChatMessage(
        text: response,
        isUser: false,
        timestamp: DateTime.now(),
        metadata: _suggestions.isNotEmpty
            ? {
                'suggestions': _suggestions
                    .map((s) => {
                          'title': s.title,
                          'estimatedCalories': s.estimatedCalories,
                          'description': s.description,
                        })
                    .toList(),
                'mealType': _selectedMealType,
                'selectedIndex': _selectedSuggestionIndex,
              }
            : null,
      );
      
      _addBotMessage(botMessage);
      
    } catch (e) {
      final errorMessage = ChatMessage(
        text: 'Désolé, je rencontre des difficultés techniques. Veuillez réessayer.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _addBotMessage(errorMessage);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _parseSuggestions(String botResponse) {
    final lines = botResponse.split('\n');
    final List<MealSuggestion> parsedSuggestions = [];
    
    MealSuggestion? currentSuggestion;
    StringBuffer? currentDescription;
    
    for (var line in lines) {
      line = line.trim();
      
      // Détecter le début d'une suggestion
      if (line.startsWith('**Option') || line.startsWith('Option')) {
        if (currentSuggestion != null && currentDescription != null) {
          currentSuggestion.description = currentDescription.toString().trim();
          parsedSuggestions.add(currentSuggestion);
        }
        
        // Extraire le titre
        final titleMatch = RegExp(r'[**]*(Option \d+: .*?)[**]*').firstMatch(line);
        final title = titleMatch?.group(1) ?? line;
        
        // Extraire les calories
        final calorieMatch = RegExp(r'\(≈?(\d+)\s*kcal\)').firstMatch(line);
        final calories = calorieMatch != null ? int.tryParse(calorieMatch.group(1)!) : null;
        
        currentSuggestion = MealSuggestion(
          title: title.replaceAll('**', '').trim(),
          estimatedCalories: calories ?? 300,
          description: '',
        );
        currentDescription = StringBuffer();
      } 
      else if (currentSuggestion != null && line.isNotEmpty && 
               !line.startsWith('💡') && !line.startsWith('🍎')) {
        currentDescription!.writeln(line);
      }
    }
    
    // Ajouter la dernière suggestion
    if (currentSuggestion != null && currentDescription != null) {
      currentSuggestion.description = currentDescription.toString().trim();
      parsedSuggestions.add(currentSuggestion);
    }
    
    if (parsedSuggestions.isNotEmpty) {
      setState(() {
        _suggestions = parsedSuggestions;
      });
    }
  }

  void _selectSuggestion(int index) {
    setState(() {
      _selectedSuggestionIndex = index;
    });
  }

  void _addUserMessage(ChatMessage message) {
    if (!_isInitialized) return;
    
    setState(() {
      _messages.add(message);
      _suggestions.clear();
      _selectedSuggestionIndex = null;
    });
    
    // Sauvegarder dans Firestore via le Provider
    final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
    conversationProvider.addMessageToCurrentConversation(message);
  }

  void _addBotMessage(ChatMessage message) {
    if (!_isInitialized) return;
    
    setState(() {
      _messages.add(message);
    });
    
    // Sauvegarder dans Firestore via le Provider
    final conversationProvider = Provider.of<ConversationProvider>(context, listen: false);
    conversationProvider.addMessageToCurrentConversation(message);
  }

  Widget _buildSuggestionCard(MealSuggestion suggestion, int index, ThemeProvider themeProvider) {
    final isSelected = _selectedSuggestionIndex == index;
    
    return GestureDetector(
      onTap: () => _selectSuggestion(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Colors.orange
                : (themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    suggestion.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${suggestion.estimatedCalories} kcal',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (suggestion.description.isNotEmpty)
              Text(
                suggestion.description,
                style: TextStyle(
                  fontSize: 14,
                  color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant,
                        size: 14,
                        color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getMealTypeLabel(_selectedMealType),
                        style: TextStyle(
                          fontSize: 12,
                          color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          size: 14,
                          color: Colors.green,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Sélectionné',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getMealTypeLabel(String value) {
    final labels = {
      'breakfast': 'Petit-déjeuner',
      'lunch': 'Déjeuner',
      'dinner': 'Dîner',
      'snack': 'Collation',
    };
    return labels[value] ?? 'Repas';
  }

  Widget _buildSectionTitle(String title, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: [
          Container(
            height: 24,
            width: 4,
            decoration: BoxDecoration(
              color: Colors.orange[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: Provider.of<ThemeProvider>(context).isDarkMode 
            ? Colors.grey[900] 
            : Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.orange,
          ),
        ),
      );
    }
    
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final conversationProvider = Provider.of<ConversationProvider>(context);
    final dailyStats = Provider.of<CalorieProvider>(context)
        .getDailyStats(DateTime.now(), auth.firebaseUser?.uid ?? '');
    
    final calorieGoal = auth.profile?.dailyCalorieGoal ?? 2000;
    final consumedCalories = dailyStats['calories'] ?? 0;

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: Text(
          conversationProvider.currentConversation?.title ?? 'Assistant Nutrition',
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConversationHistoryScreen(),
                ),
              );
            },
            tooltip: 'Historique des conversations',
          ),
        ],
      ),
      body: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.all(12),
            color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.amber.shade50,
            child: Column(
              children: [
                _buildSectionTitle('TYPE DE REPAS', themeProvider),
                
                // Sélecteur de repas
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _mealTypes.map((meal) {
                      final isSelected = _selectedMealType == meal['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(meal['label']!),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _selectedMealType = meal['value']!;
                            });
                          },
                          backgroundColor: themeProvider.isDarkMode 
                              ? Colors.grey[700] 
                              : Colors.amber.shade100,
                          selectedColor: themeProvider.isDarkMode
                              ? Colors.orange[800]
                              : Colors.amber[400],
                          labelStyle: TextStyle(
                            color: isSelected 
                                ? themeProvider.isDarkMode ? Colors.white : Colors.black
                                : themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey.shade800,
                            fontSize: 12,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Infos calories
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: themeProvider.isDarkMode ? Colors.grey[600]! : Colors.amber.shade300,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CONSOMMATION DU JOUR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Calories',
                            style: TextStyle(
                              fontSize: 14,
                              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                          Text(
                            '${consumedCalories.toStringAsFixed(0)} / $calorieGoal kcal',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: calorieGoal > 0 ? consumedCalories / calorieGoal : 0,
                        backgroundColor: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[200],
                        color: consumedCalories > calorieGoal ? Colors.red : Colors.orange,
                        minHeight: 6,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Suggestions ou Messages
          if (_suggestions.isNotEmpty)
            Expanded(
              child: Container(
                color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle('SUGGESTIONS DISPONIBLES', themeProvider),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _suggestions.length,
                        itemBuilder: (context, index) {
                          return _buildSuggestionCard(
                            _suggestions[index],
                            index,
                            themeProvider,
                          );
                        },
                      ),
                    ),
                    if (_selectedSuggestionIndex != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          
                        ),
                      ),
                  ],
                ),
              ),
            )
          else
            // Messages
            Expanded(
              child: Container(
                color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    return ChatBubble(
                      message: message,
                      isDarkMode: themeProvider.isDarkMode,
                    );
                  },
                ),
              ),
            ),

          // Zone de saisie
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
              border: Border(
                top: BorderSide(
                  color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey.shade300,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[50],
                      border: Border.all(
                        color: themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey[200]!,
                      ),
                    ),
                    child: TextField(
                      controller: _messageController,
                      style: TextStyle(
                        fontSize: 16,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                      ),
                      decoration: InputDecoration(
                        hintText: _suggestions.isEmpty
                            ? 'Ex: "Idées pour un déjeuner léger"'
                            : 'Demandez d\'autres suggestions...',
                        hintStyle: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        suffixIcon: _isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (!themeProvider.isDarkMode)
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundColor: themeProvider.isDarkMode ? Colors.orange[800] : Colors.orange,
                    radius: 24,
                    child: IconButton(
                      icon: Icon(
                        Icons.send,
                        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                      ),
                      onPressed: _isLoading ? null : _sendMessage,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MealSuggestion {
  final String title;
  final int estimatedCalories;
  String description;

  MealSuggestion({
    required this.title,
    required this.estimatedCalories,
    required this.description,
  });
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isDarkMode;

  const ChatBubble({
    Key? key,
    required this.message,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!message.isUser)
            CircleAvatar(
              backgroundColor: isDarkMode ? Colors.grey[700] : Colors.amber.shade100,
              radius: 18,
              child: Icon(
                Icons.restaurant,
                size: 20,
                color: isDarkMode ? Colors.orange : Colors.amber[800],
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isUser
                    ? (isDarkMode ? Colors.orange[900]! : Colors.amber[100]!)
                    : (isDarkMode ? Colors.grey[800]! : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                message.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.white : Colors.grey.shade800,
                ),
              ),
            ),
          ),
          if (message.isUser)
            const SizedBox(width: 8),
          if (message.isUser)
            CircleAvatar(
              backgroundColor: isDarkMode ? Colors.orange[800] : Colors.orange,
              radius: 18,
              child: Icon(
                Icons.person,
                size: 20,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}