// lib/screens/entry_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart'; 
import '../models/food_entry.dart';
import '../providers/theme_provider.dart'; 

class EntryDetailScreen extends StatelessWidget {
  final FoodEntry entry;

  const EntryDetailScreen({Key? key, required this.entry}) : super(key: key);

  String _getCategoryLabel(String? category) {
    final categories = {
      'fruits': '🍎 Fruits',
      'vegetables': '🥦 Légumes',
      'grains': '🌾 Céréales',
      'proteins': '🍗 Protéines',
      'dairy': '🥛 Produits laitiers',
      'fats': '🥑 Lipides',
      'sweets': '🍰 Sucreries',
      'beverages': '🥤 Boissons',
      'other': '📦 Autre',
    };
    return categories[category] ?? 'Non spécifié';
  }

  String _getMealTypeLabel(String? mealType) {
    final mealTypes = {
      'breakfast': '🌅 Petit-déjeuner',
      'lunch': '☀️ Déjeuner',
      'dinner': '🌙 Dîner',
      'snack': '🍎 Collation',
    };
    return mealTypes[mealType] ?? 'Non spécifié';
  }

  Color _getCategoryColor(String? category) {
    final colors = {
      'fruits': Colors.green,
      'vegetables': Colors.lightGreen,
      'grains': Colors.amber,
      'proteins': Colors.red,
      'dairy': Colors.blue,
      'fats': Colors.orange,
      'sweets': Colors.pink,
      'beverages': Colors.cyan,
      'other': Colors.grey,
    };
    return colors[category] ?? Colors.grey;
  }

  Widget _buildDetailRow(String label, String value, {IconData? icon, required ThemeProvider themeProvider}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 12, top: 2),
              child: Icon(icon, size: 20, color: Colors.teal),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionCard(String title, double value, String unit, Color color, ThemeProvider themeProvider) {
    return Expanded(
      child: Card(
        color: themeProvider.isDarkMode 
          ? color.withOpacity(0.2)
          : color.withOpacity(0.1),
        elevation: themeProvider.isDarkMode ? 4 : 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${value.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey;
    final cardColor = themeProvider.isDarkMode ? Colors.grey[800] : Colors.white;
    
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
      appBar: AppBar(
        title: const Text('Détails de l\'entrée'),
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : null,
        foregroundColor: themeProvider.isDarkMode ? Colors.white : null,
        elevation: themeProvider.isDarkMode ? 2 : 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête avec nom et catégorie
            Card(
              color: themeProvider.isDarkMode
                ? _getCategoryColor(entry.category).withOpacity(0.3)
                : _getCategoryColor(entry.category).withOpacity(0.1),
              elevation: themeProvider.isDarkMode ? 4 : 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(entry.category),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getCategoryLabel(entry.category),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${entry.calories} kcal',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.teal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      entry.name,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (entry.mealType != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.restaurant, size: 16, color: subtitleColor),
                          const SizedBox(width: 6),
                          Text(
                            _getMealTypeLabel(entry.mealType),
                            style: TextStyle(color: subtitleColor),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Informations de base
            Text(
              'INFORMATIONS',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              color: cardColor,
              elevation: themeProvider.isDarkMode ? 4 : 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Date et heure',
                      DateFormat('dd/MM/yyyy à HH:mm').format(entry.date),
                      icon: Icons.calendar_today,
                      themeProvider: themeProvider,
                    ),
                    _buildDetailRow(
                      'Portion',
                      '${entry.servingSize} ${entry.servingUnit}',
                      icon: Icons.scale,
                      themeProvider: themeProvider,
                    ),
                    if (entry.mealType != null)
                      _buildDetailRow(
                        'Type de repas',
                        _getMealTypeLabel(entry.mealType),
                        icon: Icons.restaurant,
                        themeProvider: themeProvider,
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Informations nutritionnelles
            Text(
              'VALEURS NUTRITIONNELLES',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 12),

            Card(
              color: cardColor,
              elevation: themeProvider.isDarkMode ? 4 : 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Pour 100g
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Valeurs pour ${entry.servingSize}${entry.servingUnit}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Macro-nutriments
                    Row(
                      children: [
                        _buildNutritionCard(
                          'Protéines',
                          entry.proteins ?? 0,
                          'g',
                          Colors.blue,
                          themeProvider,
                        ),
                        const SizedBox(width: 8),
                        _buildNutritionCard(
                          'Glucides',
                          entry.carbs ?? 0,
                          'g',
                          Colors.orange,
                          themeProvider,
                        ),
                        const SizedBox(width: 8),
                        _buildNutritionCard(
                          'Lipides',
                          entry.fats ?? 0,
                          'g',
                          Colors.red,
                          themeProvider,
                        ),
                      ],
                    ),

                    // Calories par gramme
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Center(
                        child: Text(
                          '${(entry.calories / entry.servingSize).toStringAsFixed(2)} kcal/g',
                          style: TextStyle(
                            fontSize: 14,
                            color: subtitleColor,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Notes (si disponibles)
            if (entry.notes != null && entry.notes!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'NOTES',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: subtitleColor,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                color: cardColor,
                elevation: themeProvider.isDarkMode ? 4 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(right: 12, top: 2),
                        child: Icon(Icons.note, size: 20, color: Colors.teal),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Notes personnelles',
                              style: TextStyle(
                                fontSize: 12,
                                color: subtitleColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              entry.notes!,
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}