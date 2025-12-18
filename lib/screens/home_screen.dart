// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../providers/auth_provider.dart';
import '../providers/calorie_provider.dart';
import '../providers/theme_provider.dart'; 
import '../models/food_entry.dart';
import 'add_entry_screen.dart';
import 'stats_screen.dart';
import 'entry_detail_screen.dart';
import 'edit_entry_screen.dart';
import 'profile_screen.dart';
import 'chatbot_screen.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedFilter;

  final List<Map<String, dynamic>> _filters = [
    {'value': null, 'label': 'Tous', 'icon': Icons.all_inclusive},
    {'value': 'breakfast', 'label': 'Petit-déj.', 'icon': Icons.bakery_dining},
    {'value': 'lunch', 'label': 'Déjeuner', 'icon': Icons.lunch_dining},
    {'value': 'dinner', 'label': 'Dîner', 'icon': Icons.dinner_dining},
    {'value': 'snack', 'label': 'Collation', 'icon': Icons.cookie},
  ];

  @override
  void initState() {
    super.initState();
    // Charger les préférences de thème au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      themeProvider.loadThemePreference();
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: const Color.fromARGB(255, 167, 79, 32),
              onPrimary: themeProvider.isDarkMode ? Colors.black : Colors.white,
              surface: themeProvider.isDarkMode ? Colors.grey[900]! : Colors.white,
              onSurface: themeProvider.isDarkMode ? const Color.fromARGB(255, 255, 255, 255) : Colors.black,
            ),
            dialogBackgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
    }
  }

  void _showDateRangeDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Choisir une période',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.today, color: const Color.fromARGB(255, 242, 116, 5)),
              title: Text(
                'Aujourd\'hui',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? const Color.fromARGB(255, 255, 255, 255) : Colors.black,
                ),
              ),
              onTap: () {
                setState(() => _selectedDate = DateTime.now());
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_view_day, color: Colors.amber),
              title: Text(
                'Hier',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                setState(() => _selectedDate = DateTime.now().subtract(const Duration(days: 1)));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_view_week, color: Colors.amber),
              title: Text(
                'Cette semaine',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return FutureBuilder(
      future: initializeDateFormatting('fr_FR', null),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
            body: Center(
              child: CircularProgressIndicator(color: Colors.amber),
            ),
          );
        }

        final auth = Provider.of<AuthProvider>(context);
        final cp = Provider.of<CalorieProvider>(context, listen: false);
        
        if (auth.firebaseUser != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            cp.loadEntries(auth.firebaseUser!.uid);
          });
        }

        return Scaffold(
          backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
          appBar: AppBar(
            title: Text(
              'Bienvenu, ${_truncateName(auth.profile?.fullName ?? 'Utilisateur')}',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.amber[700],
            foregroundColor: themeProvider.isDarkMode ? Colors.white : Colors.black,
            elevation: 2,
            actions: [
              // Bouton pour changer le thème
              IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  size: 20,
                ),
                tooltip: themeProvider.isDarkMode ? 'Mode clair' : 'Mode sombre',
                onPressed: () {
                  themeProvider.toggleTheme();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart),
                tooltip: 'Statistiques',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const StatsScreen()),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  if (value == 'profile') {
                    _navigateToProfile(context);
                  } else if (value == 'logout') {
                    auth.logout();
                  } else if (value == 'sync') {
                    _syncWithFirebase(context, auth, cp);
                  }
                },
                itemBuilder: (context) => [
                  // Option Profil
                  PopupMenuItem(
                    value: 'profile',
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 18, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Mon profil',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? const Color.fromARGB(255, 220, 107, 32) : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Option Synchronisation
                  PopupMenuItem(
                    value: 'sync',
                    child: Row(
                      children: [
                        Icon(Icons.sync, size: 18, color: Colors.amber[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Synchroniser',
                          style: TextStyle(
                            color: themeProvider.isDarkMode ? const  Color.fromARGB(255, 220, 107, 32) : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  PopupMenuDivider(
                    height: 1,
                    color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
                  ),
                  
                  // Option Déconnexion
                  PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Déconnexion',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          // MODIFICATION ICI : Ajout du bouton chatbot
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Bouton Chatbot
              Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 16),
                child: FloatingActionButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatbotScreen()),
                  ),
                  backgroundColor: Colors.blue[600],
                  foregroundColor: Colors.white,
                  elevation: 4,
                  child: const Icon(Icons.assistant),
                  heroTag: 'chatbot',
                ),
              ),
              // Bouton Ajouter
              FloatingActionButton.extended(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddEntryScreen()),
                ),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                backgroundColor: Colors.amber[700],
                foregroundColor: themeProvider.isDarkMode ? Colors.white : Colors.black,
                elevation: 4,
                heroTag: 'add',
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isVerySmallScreen = constraints.maxWidth < 320;
              final isSmallScreen = constraints.maxWidth < 380;
              
              return Column(
                children: [
                  // En-tête avec stats et date
                  Consumer<CalorieProvider>(
                    builder: (context, provider, _) {
                      final dailyStats = provider.getDailyStats(_selectedDate, auth.firebaseUser?.uid ?? '');
                      return _buildHeader(
                        dailyStats, 
                        isVerySmallScreen, 
                        isSmallScreen,
                        themeProvider,
                      );
                    },
                  ),

                  // Filtres
                  _buildFilterBar(isVerySmallScreen, isSmallScreen, themeProvider),

                  // Liste des entrées
                  Expanded(
                    child: Consumer<CalorieProvider>(
                      builder: (context, provider, _) {
                        List<FoodEntry> filteredEntries = provider.entries.where((entry) {
                          // Filtrer par date
                          final isSameDate = entry.date.year == _selectedDate.year &&
                              entry.date.month == _selectedDate.month &&
                              entry.date.day == _selectedDate.day;
                          
                          // Filtrer par type de repas si sélectionné
                          if (_selectedFilter != null) {
                            return isSameDate && entry.mealType == _selectedFilter;
                          }
                          
                          return isSameDate;
                        }).toList();

                        if (filteredEntries.isEmpty) {
                          return _buildEmptyState(themeProvider);
                        }

                        return ListView.builder(
                          itemCount: filteredEntries.length,
                          itemBuilder: (context, index) {
                            final entry = filteredEntries[index];
                            return _buildEntryCard(
                              entry, 
                              provider, 
                              isVerySmallScreen, 
                              isSmallScreen,
                              themeProvider,
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _navigateToProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  String _truncateName(String name, [int maxLength = 15]) {
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength - 3)}...';
  }

  Widget _buildHeader(
    Map<String, double> dailyStats, 
    bool isVerySmallScreen, 
    bool isSmallScreen,
    ThemeProvider themeProvider,
  ) {
    final double padding = isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 16);
    final backgroundColor = themeProvider.isDarkMode ? Colors.grey[800]! : Colors.amber[700]!;
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode 
              ? Colors.black.withOpacity(0.5)
              : Colors.amber.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Date selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.chevron_left, color: textColor),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  });
                },
                iconSize: isVerySmallScreen ? 18 : (isSmallScreen ? 20 : 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36),
              ),
              GestureDetector(
                onTap: () => _selectDate(context),
                onLongPress: _showDateRangeDialog,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 16),
                    vertical: isVerySmallScreen ? 4 : (isSmallScreen ? 5 : 8),
                  ),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode 
                      ? Colors.white.withOpacity(0.15)
                      : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: themeProvider.isDarkMode 
                        ? Colors.amber.withOpacity(0.3)
                        : Colors.black.withOpacity(0.2),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 16),
                        color: textColor,
                      ),
                      SizedBox(width: isVerySmallScreen ? 3 : (isSmallScreen ? 4 : 8)),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.4,
                        ),
                        child: Text(
                          _getFormattedDate(_selectedDate, isVerySmallScreen),
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.w600,
                            fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 14),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.chevron_right, color: textColor),
                onPressed: () {
                  final tomorrow = _selectedDate.add(const Duration(days: 1));
                  if (tomorrow.isBefore(DateTime.now().add(const Duration(days: 1)))) {
                    setState(() => _selectedDate = tomorrow);
                  }
                },
                iconSize: isVerySmallScreen ? 18 : (isSmallScreen ? 20 : 24),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36),
              ),
            ],
          ),

          SizedBox(height: isVerySmallScreen ? 8 : (isSmallScreen ? 10 : 16)),

          // Stats cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  value: '${dailyStats['calories']?.toStringAsFixed(0) ?? '0'}',
                  unit: 'kcal',
                  label: 'Calories',
                  icon: Icons.local_fire_department,
                  color: Colors.orange[800]!,
                  isVerySmallScreen: isVerySmallScreen,
                  isSmallScreen: isSmallScreen,
                  themeProvider: themeProvider,
                ),
              ),
              SizedBox(width: isVerySmallScreen ? 4 : (isSmallScreen ? 5 : 8)),
              Expanded(
                child: _buildStatCard(
                  value: '${dailyStats['proteins']?.toStringAsFixed(1) ?? '0'}',
                  unit: 'g',
                  label: 'Protéines',
                  icon: Icons.fitness_center,
                  color: Colors.amber[900]!,
                  isVerySmallScreen: isVerySmallScreen,
                  isSmallScreen: isSmallScreen,
                  themeProvider: themeProvider,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getFormattedDate(DateTime date, bool isVerySmallScreen) {
    if (isVerySmallScreen) {
      return DateFormat('d MMM', 'fr_FR').format(date);
    }
    return DateFormat('EEEE d MMMM y', 'fr_FR').format(date);
  }

  Widget _buildStatCard({
    required String value,
    required String unit,
    required String label,
    required IconData icon,
    required Color color,
    required bool isVerySmallScreen,
    required bool isSmallScreen,
    required ThemeProvider themeProvider,
  }) {
    final double padding = isVerySmallScreen ? 6 : (isSmallScreen ? 7 : 10);
    final double iconSize = isVerySmallScreen ? 14 : (isSmallScreen ? 15 : 18);
    final double fontSizeValue = isVerySmallScreen ? 14 : (isSmallScreen ? 15 : 18);
    final double fontSizeUnit = isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10);
    final double fontSizeLabel = isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 10);
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode 
          ? Colors.white.withOpacity(0.12)
          : Colors.black.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: themeProvider.isDarkMode 
            ? Colors.amber.withOpacity(0.3)
            : Colors.black.withOpacity(0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isVerySmallScreen ? 3 : (isSmallScreen ? 4 : 6)),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: Colors.white,
            ),
          ),
          SizedBox(width: isVerySmallScreen ? 4 : (isSmallScreen ? 5 : 8)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: fontSizeValue,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(width: isVerySmallScreen ? 1 : 2),
                    Text(
                      unit,
                      style: TextStyle(
                        fontSize: fontSizeUnit,
                        color: textColor.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSizeLabel,
                    color: textColor.withOpacity(0.8),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isVerySmallScreen, bool isSmallScreen, ThemeProvider themeProvider) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: isVerySmallScreen ? 45 : (isSmallScreen ? 50 : 60),
      ),
      padding: EdgeInsets.symmetric(
        vertical: isVerySmallScreen ? 4 : (isSmallScreen ? 5 : 8),
        horizontal: isVerySmallScreen ? 6 : (isSmallScreen ? 8 : 12),
      ),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.amber.shade200,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _filters.map((filter) {
            final isSelected = _selectedFilter == filter['value'];
            final String label = isVerySmallScreen && filter['label'] == 'Petit-déj.' 
              ? 'Petit-déj.' 
              : filter['label'] as String;
            
            return Padding(
              padding: EdgeInsets.only(right: isVerySmallScreen ? 3 : (isSmallScreen ? 4 : 6)),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isVerySmallScreen ? 80 : (isSmallScreen ? 90 : 100),
                ),
                child: FilterChip(
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedFilter = selected ? filter['value'] as String? : null;
                    });
                  },
                  label: Text(
                    label,
                    style: TextStyle(
                      fontSize: isVerySmallScreen ? 10 : (isSmallScreen ? 11 : 12),
                      color: isSelected 
                        ? (themeProvider.isDarkMode ? Colors.black : Colors.black)
                        : (themeProvider.isDarkMode ? Colors.white : Colors.grey.shade800),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  avatar: Icon(
                    filter['icon'] as IconData,
                    size: isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 16),
                    color: isSelected 
                      ? (themeProvider.isDarkMode ? Colors.black : Colors.black)
                      : (themeProvider.isDarkMode ? Colors.white70 : Colors.grey.shade700),
                  ),
                  backgroundColor: themeProvider.isDarkMode 
                    ? Colors.grey[800]
                    : Colors.amber.shade50,
                  selectedColor: themeProvider.isDarkMode 
                    ? Colors.amber[400]
                    : Colors.amber[200],
                  checkmarkColor: themeProvider.isDarkMode ? Colors.black : Colors.black,
                  labelStyle: TextStyle(
                    color: isSelected 
                      ? (themeProvider.isDarkMode ? Colors.black : Colors.black)
                      : (themeProvider.isDarkMode ? Colors.white : Colors.grey.shade800),
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected 
                        ? (themeProvider.isDarkMode ? Colors.black : Colors.black)
                        : (themeProvider.isDarkMode ? Colors.grey[600]! : Colors.amber.shade300),
                      width: isSelected ? 1.2 : 0.8,
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: isVerySmallScreen ? 4 : (isSmallScreen ? 5 : 8),
                    vertical: isVerySmallScreen ? 1 : (isSmallScreen ? 2 : 4),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildEntryCard(
    FoodEntry entry, 
    CalorieProvider provider, 
    bool isVerySmallScreen, 
    bool isSmallScreen,
    ThemeProvider themeProvider,
  ) {
    String getMealIcon(String? mealType) {
      switch (mealType) {
        case 'breakfast': return '🌅';
        case 'lunch': return '☀️';
        case 'dinner': return '🌙';
        case 'snack': return '🍎';
        default: return '🍽️';
      }
    }

    String getCategoryIcon(String? category) {
      switch (category) {
        case 'fruits': return '🍎';
        case 'vegetables': return '🥦';
        case 'grains': return '🌾';
        case 'proteins': return '🍗';
        case 'dairy': return '🥛';
        case 'fats': return '🥑';
        case 'sweets': return '🍰';
        case 'beverages': return '🥤';
        default: return '📦';
      }
    }

    Color getCategoryColor(String? category, ThemeProvider themeProvider) {
      if (themeProvider.isDarkMode) {
        switch (category) {
          case 'fruits': return Colors.green.shade900.withOpacity(0.5);
          case 'vegetables': return Colors.lightGreen.shade900.withOpacity(0.5);
          case 'grains': return Colors.amber.shade900.withOpacity(0.5);
          case 'proteins': return Colors.red.shade900.withOpacity(0.5);
          case 'dairy': return Colors.blue.shade900.withOpacity(0.5);
          case 'fats': return Colors.orange.shade900.withOpacity(0.5);
          case 'sweets': return Colors.pink.shade900.withOpacity(0.5);
          case 'beverages': return Colors.cyan.shade900.withOpacity(0.5);
          default: return Colors.grey[800]!.withOpacity(0.5);
        }
      } else {
        switch (category) {
          case 'fruits': return Colors.green.shade100;
          case 'vegetables': return Colors.lightGreen.shade100;
          case 'grains': return Colors.amber.shade100;
          case 'proteins': return Colors.red.shade100;
          case 'dairy': return Colors.blue.shade100;
          case 'fats': return Colors.orange.shade100;
          case 'sweets': return Colors.pink.shade100;
          case 'beverages': return Colors.cyan.shade100;
          default: return Colors.amber.shade50;
        }
      }
    }

    final double cardMargin = isVerySmallScreen ? 6 : (isSmallScreen ? 7 : 12);
    final double cardPadding = isVerySmallScreen ? 8 : (isSmallScreen ? 9 : 12);
    final double iconSize = isVerySmallScreen ? 28 : (isSmallScreen ? 30 : 36);
    final double fontSizeName = isVerySmallScreen ? 12 : (isSmallScreen ? 13 : 15);
    final double fontSizeDetails = isVerySmallScreen ? 9 : (isSmallScreen ? 10 : 11);
    final double spacing = isVerySmallScreen ? 4 : (isSmallScreen ? 5 : 8);
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = themeProvider.isDarkMode ? Colors.white70 : Colors.grey.shade700;

    return Card(
      margin: EdgeInsets.symmetric(
        horizontal: cardMargin,
        vertical: 3,
      ),
      elevation: themeProvider.isDarkMode ? 2 : 1,
      color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(
          color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.amber.shade200,
          width: 0.8,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EntryDetailScreen(entry: entry),
            ),
          );
        },
        onLongPress: () => _showEntryOptions(context, entry, provider, themeProvider),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icône de catégorie
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  color: getCategoryColor(entry.category, themeProvider),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: themeProvider.isDarkMode 
                      ? Colors.amber.withOpacity(0.5)
                      : Colors.amber.shade300,
                    width: 0.8,
                  ),
                ),
                child: Center(
                  child: Text(
                    getCategoryIcon(entry.category),
                    style: TextStyle(fontSize: isVerySmallScreen ? 14 : 16),
                  ),
                ),
              ),
              SizedBox(width: spacing),

              // Informations principales
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Première ligne : Nom et favori
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _truncateFoodName(entry.name, isVerySmallScreen ? 15 : 20),
                            style: TextStyle(
                              fontSize: fontSizeName,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (entry.isFavorite)
                          Padding(
                            padding: EdgeInsets.only(left: isVerySmallScreen ? 1 : 2),
                            child: Icon(
                              Icons.favorite,
                              size: isVerySmallScreen ? 8 : 10,
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: isVerySmallScreen ? 2 : 3),
                    
                    // Informations compactes sur une seule ligne
                    Row(
                      children: [
                        // Icône du repas
                        Text(
                          getMealIcon(entry.mealType),
                          style: TextStyle(fontSize: fontSizeDetails),
                        ),
                        SizedBox(width: isVerySmallScreen ? 2 : 3),
                        
                        // Calories
                        Text(
                          '${entry.calories.toStringAsFixed(0)} kcal',
                          style: TextStyle(
                            fontSize: fontSizeDetails,
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        // Protéines (si disponibles)
                        if (entry.proteins != null && entry.proteins! > 0) ...[
                          SizedBox(width: isVerySmallScreen ? 2 : 3),
                          Text(
                            '• ${entry.proteins!.toStringAsFixed(1)}g',
                            style: TextStyle(
                              fontSize: fontSizeDetails,
                              color: Colors.blue.shade800,
                            ),
                          ),
                        ],
                        
                        // Portion (si différente de 100g)
                        if (entry.servingSize != 100) ...[
                          SizedBox(width: isVerySmallScreen ? 2 : 3),
                          Text(
                            '• ${entry.servingSize}g',
                            style: TextStyle(
                              fontSize: fontSizeDetails,
                              color: subtitleColor,
                            ),
                          ),
                        ],
                        
                        // Espace flexible
                        Expanded(child: Container()),
                        
                        // Heure
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.access_time,
                              size: isVerySmallScreen ? 8 : 9,
                              color: Colors.amber.shade700,
                            ),
                            SizedBox(width: isVerySmallScreen ? 1 : 2),
                            Text(
                              DateFormat.Hm('fr_FR').format(entry.date),
                              style: TextStyle(
                                fontSize: fontSizeDetails,
                                color: Colors.amber.shade700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Bouton d'action - visible seulement sur tap long
              SizedBox(
                width: isVerySmallScreen ? 18 : 24,
                child: IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    size: isVerySmallScreen ? 14 : 16,
                    color: Colors.amber[700],
                  ),
                  onPressed: () => _showEntryOptions(context, entry, provider, themeProvider),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _truncateFoodName(String name, [int maxLength = 20]) {
    if (name.length <= maxLength) return name;
    return '${name.substring(0, maxLength - 3)}...';
  }

  Widget _buildEmptyState(ThemeProvider themeProvider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.fastfood,
              size: 60,
              color: themeProvider.isDarkMode 
                ? Colors.amber.shade400 
                : Colors.amber.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedFilter != null
                  ? 'Aucune entrée pour ce repas'
                  : 'Aucune entrée aujourd\'hui',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: themeProvider.isDarkMode 
                  ? Colors.amber.shade300
                  : Colors.amber.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Appuyez sur le bouton + pour\najouter votre première entrée',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: themeProvider.isDarkMode 
                  ? Colors.white70
                  : Colors.amber.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEntryOptions(BuildContext context, FoodEntry entry, CalorieProvider provider, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.remove_red_eye, size: 22, color: Colors.amber),
              title: Text(
                'Voir les détails',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EntryDetailScreen(entry: entry),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit, size: 22, color: Colors.blue),
              title: Text(
                'Modifier',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditEntryScreen(entry: entry),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                entry.isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 22,
                color: Colors.red,
              ),
              title: Text(
                entry.isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
                style: TextStyle(
                  color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  await provider.toggleFavorite(entry.id!, !entry.isFavorite);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        entry.isFavorite 
                          ? 'Retiré des favoris' 
                          : 'Ajouté aux favoris',
                      ),
                      backgroundColor: Colors.red,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
            Divider(
              height: 1,
              color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.grey[300],
            ),
            ListTile(
              leading: Icon(Icons.delete, size: 22, color: Colors.red),
              title: Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, entry, provider, themeProvider);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, FoodEntry entry, CalorieProvider provider, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        content: Text(
          'Supprimer "${_truncateFoodName(entry.name, 30)}" ?',
          style: TextStyle(
            color: themeProvider.isDarkMode ? Colors.white70 : Colors.black87,
          ),
        ),
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'NON',
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              try {
                await provider.deleteEntry(entry.id!);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"${_truncateFoodName(entry.name, 20)}" supprimé'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('OUI', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _syncWithFirebase(BuildContext context, AuthProvider auth, CalorieProvider cp) async {
    try {
      final uid = auth.firebaseUser?.uid;
      if (uid == null) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Synchronisation...'),
          backgroundColor: Colors.amber,
          duration: Duration(seconds: 1),
        ),
      );

      await cp.syncWithFirebase(uid);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Synchronisé !'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString().substring(0, 30)}...'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}