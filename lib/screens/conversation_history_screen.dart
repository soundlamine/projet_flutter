import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/conversation_provider.dart';
import '../providers/theme_provider.dart';
import 'chatbot_screen.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';

class ConversationHistoryScreen extends StatefulWidget {
  const ConversationHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ConversationHistoryScreen> createState() => _ConversationHistoryScreenState();
}

class _ConversationHistoryScreenState extends State<ConversationHistoryScreen> {
  final TextEditingController _renameController = TextEditingController();
  String? _conversationToRename;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadConversations();
    });
  }

  void _loadConversations() {
    final provider = Provider.of<ConversationProvider>(context, listen: false);
    provider.loadConversations();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'Aujourd\'hui, ${DateFormat('HH:mm').format(date)}';
    } else if (date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day) {
      return 'Hier, ${DateFormat('HH:mm').format(date)}';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    }
  }

  String _getPreviewMessage(List<ChatMessage> messages) {
    if (messages.isEmpty) return 'Aucun message';
    
    final lastMessage = messages.last;
    final text = lastMessage.text;
    
    if (text.length > 40) {
      return '${text.substring(0, 40)}...';
    }
    return text;
  }

  void _showDeleteDialog(String conversationId, String title) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        title: Text(
          'Supprimer la conversation',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "$title" ?',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.orange : Colors.orange[800],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteConversation(conversationId);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation(String conversationId) async {
    try {
      final provider = Provider.of<ConversationProvider>(context, listen: false);
      await provider.deleteConversation(conversationId);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Conversation supprimée'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRenameDialog(String conversationId, String currentTitle) {
    _renameController.text = currentTitle;
    _conversationToRename = conversationId;
    
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        title: Text(
          'Renommer la conversation',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: TextField(
          controller: _renameController,
          decoration: InputDecoration(
            hintText: 'Nouveau nom',
            hintStyle: TextStyle(
              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.orange),
            ),
          ),
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
          maxLength: 50,
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _renameController.clear();
              _conversationToRename = null;
            },
            child: Text(
              'Annuler',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.orange : Colors.orange[800],
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (_renameController.text.trim().isNotEmpty && _conversationToRename != null) {
                await _renameConversation(_conversationToRename!, _renameController.text.trim());
              }
              Navigator.pop(context);
              _renameController.clear();
              _conversationToRename = null;
            },
            child: const Text(
              'Renommer',
              style: TextStyle(color: Colors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _renameConversation(String conversationId, String newTitle) async {
    try {
      final provider = Provider.of<ConversationProvider>(context, listen: false);
      await provider.renameConversation(conversationId, newTitle);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Conversation renommée'),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final conversationProvider = Provider.of<ConversationProvider>(context);
    
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text(
          'Historique',
          style: TextStyle(fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        foregroundColor: Colors.orange,
        actions: [
          if (conversationProvider.currentConversation != null)
            IconButton(
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Continuer la conversation',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChatbotScreen(),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: conversationProvider.isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.orange,
              ),
            )
          : conversationProvider.conversations.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 80,
                        color: themeProvider.isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune conversation',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Commencez une nouvelle conversation',
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await conversationProvider.createNewConversation();
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ChatbotScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Nouvelle conversation'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    await conversationProvider.loadConversations();
                  },
                  color: Colors.orange,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: conversationProvider.conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversationProvider.conversations[index];
                      final messageCount = conversation.messages.length;
                      
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                        child: Card(
                          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: themeProvider.isDarkMode 
                                        ? Colors.orange[800] 
                                        : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Icon(
                                    messageCount > 1 ? Icons.chat : Icons.chat_bubble_outline,
                                    color: themeProvider.isDarkMode ? Colors.white : Colors.orange[800],
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              conversation.title ?? 'Conversation',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          _buildMenuButton(conversation, themeProvider),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _getPreviewMessage(conversation.messages),
                                        style: TextStyle(
                                          color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.message,
                                            size: 12,
                                            color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            '$messageCount message${messageCount > 1 ? 's' : ''}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[500],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Icon(
                                            Icons.access_time,
                                            size: 12,
                                            color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[500],
                                          ),
                                          const SizedBox(width: 4),
                                          Flexible(
                                            child: Text(
                                              _formatDate(conversation.updatedAt),
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: themeProvider.isDarkMode ? Colors.grey[500] : Colors.grey[500],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 16),
        child: FloatingActionButton(
          onPressed: () async {
            final provider = Provider.of<ConversationProvider>(context, listen: false);
            await provider.createNewConversation();
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ChatbotScreen(),
              ),
            );
          },
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add_comment),
        ),
      ),
    );
  }

  Widget _buildMenuButton(Conversation conversation, ThemeProvider themeProvider) {
    return SizedBox(
      width: 36,
      child: PopupMenuButton<String>(
        icon: Icon(
          Icons.more_vert,
          color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          size: 20,
        ),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        onSelected: (value) {
          if (value == 'open') {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatbotScreen(
                  conversationId: conversation.id,
                ),
              ),
            );
          } else if (value == 'rename') {
            _showRenameDialog(
              conversation.id,
              conversation.title ?? 'Conversation',
            );
          } else if (value == 'delete') {
            _showDeleteDialog(
              conversation.id,
              conversation.title ?? 'Conversation',
            );
          }
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'open',
            child: Row(
              children: [
                Icon(Icons.open_in_new, size: 18, color: Colors.orange),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'Ouvrir',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'rename',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18, color: Colors.blue),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'Renommer',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 18, color: Colors.red),
                const SizedBox(width: 10),
                const Flexible(
                  child: Text(
                    'Supprimer',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }
}