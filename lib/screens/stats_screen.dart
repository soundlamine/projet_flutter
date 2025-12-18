// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/calorie_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart'; 
import '../models/food_entry.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({Key? key}) : super(key: key);

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String _selectedPeriod = 'semaine'; // 'jour', 'semaine', 'mois'
  String _selectedStat = 'calories'; // 'calories', 'proteines', 'glucides', 'lipides'

  @override
  Widget build(BuildContext context) {
    final cp = Provider.of<CalorieProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final uid = auth.firebaseUser?.uid ?? '';
    final now = DateTime.now();

    // Couleurs dynamiques selon le mode
    final backgroundColor = themeProvider.isDarkMode ? Colors.grey[900] : Colors.white;
    final cardColor = themeProvider.isDarkMode ? Colors.grey[800] : Colors.amber.shade50;
    final borderColor = themeProvider.isDarkMode ? Colors.grey[600]! : Colors.amber.shade200;
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey.shade700;

    // Données selon la période sélectionnée
    List<DateTime> dates = [];
    List<double> values = [];
    double total = 0;
    double average = 0;
    double maxValue = 0;

    if (_selectedPeriod == 'jour') {
      // Dernières 24 heures par tranches de 4h
      for (int i = 0; i < 6; i++) {
        final hour = i * 4;
        final start = DateTime(now.year, now.month, now.day, hour);
        final end = start.add(const Duration(hours: 4));
        // Calculer les calories pour cette tranche horaire
        double periodValue = 0;
        for (final entry in cp.entries) {
          if (entry.uid == uid && 
              entry.date.isAfter(start) && 
              entry.date.isBefore(end)) {
            periodValue += _getStatValue(entry);
          }
        }
        dates.add(start);
        values.add(periodValue);
        total += periodValue;
        if (periodValue > maxValue) maxValue = periodValue;
      }
      average = total / values.length;
    } else if (_selectedPeriod == 'semaine') {
      // 7 derniers jours
      for (int i = 6; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final value = cp.entries
            .where((e) => e.uid == uid && 
                e.date.year == day.year &&
                e.date.month == day.month &&
                e.date.day == day.day)
            .fold(0.0, (sum, entry) => sum + _getStatValue(entry));
        dates.add(day);
        values.add(value);
        total += value;
        if (value > maxValue) maxValue = value;
      }
      average = total / values.length;
    } else if (_selectedPeriod == 'mois') {
      // 30 derniers jours
      for (int i = 29; i >= 0; i--) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: i));
        final value = cp.entries
            .where((e) => e.uid == uid && 
                e.date.year == day.year &&
                e.date.month == day.month &&
                e.date.day == day.day)
            .fold(0.0, (sum, entry) => sum + _getStatValue(entry));
        dates.add(day);
        values.add(value);
        total += value;
        if (value > maxValue) maxValue = value;
      }
      average = total / values.length;
    }

    // Couleurs et labels selon la statistique sélectionnée
    Color chartColor;
    String unit;
    String statLabel;
    
    switch (_selectedStat) {
      case 'proteines':
        chartColor = Colors.blue;
        unit = 'g';
        statLabel = 'Protéines';
        break;
      case 'glucides':
        chartColor = Colors.orange;
        unit = 'g';
        statLabel = 'Glucides';
        break;
      case 'lipides':
        chartColor = Colors.red;
        unit = 'g';
        statLabel = 'Lipides';
        break;
      default: // calories
        chartColor = themeProvider.isDarkMode ? Colors.amber[400]! : Colors.amber[700]!;
        unit = 'kcal';
        statLabel = 'Calories';
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Statistiques'),
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.amber[700],
        foregroundColor: themeProvider.isDarkMode ? Colors.white : Colors.black,
        elevation: themeProvider.isDarkMode ? 2 : 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sélecteurs
            Row(
              children: [
                Expanded(
                  child: Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedPeriod,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down, 
                            color: themeProvider.isDarkMode ? Colors.amber[400] : Colors.amber[700]
                          ),
                          style: TextStyle(color: textColor),
                          dropdownColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                          items: const [
                            DropdownMenuItem(value: 'jour', child: Text('24 Heures')),
                            DropdownMenuItem(value: 'semaine', child: Text('7 Jours')),
                            DropdownMenuItem(value: 'mois', child: Text('30 Jours')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedPeriod = value!);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    color: cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: borderColor),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedStat,
                          isExpanded: true,
                          icon: Icon(
                            Icons.arrow_drop_down, 
                            color: themeProvider.isDarkMode ? Colors.amber[400] : Colors.amber[700]
                          ),
                          style: TextStyle(color: textColor),
                          dropdownColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                          items: const [
                            DropdownMenuItem(value: 'calories', child: Text('Calories')),
                            DropdownMenuItem(value: 'proteines', child: Text('Protéines')),
                            DropdownMenuItem(value: 'glucides', child: Text('Glucides')),
                            DropdownMenuItem(value: 'lipides', child: Text('Lipides')),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedStat = value!);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Cartes de statistiques
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Total',
                    value: total.toStringAsFixed(_selectedStat == 'calories' ? 0 : 1),
                    unit: unit,
                    color: chartColor,
                    icon: Icons.summarize,
                    themeProvider: themeProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Moyenne',
                    value: average.toStringAsFixed(_selectedStat == 'calories' ? 0 : 1),
                    unit: '${unit}/jour',
                    color: themeProvider.isDarkMode ? Colors.grey[500]! : Colors.grey.shade700,
                    icon: Icons.trending_up,
                    themeProvider: themeProvider,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    title: 'Maximum',
                    value: maxValue.toStringAsFixed(_selectedStat == 'calories' ? 0 : 1),
                    unit: unit,
                    color: Colors.red,
                    icon: Icons.arrow_upward,
                    themeProvider: themeProvider,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    title: 'Jours actifs',
                    value: values.where((v) => v > 0).length.toString(),
                    unit: 'jours',
                    color: Colors.green,
                    icon: Icons.calendar_today,
                    themeProvider: themeProvider,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Graphique
            Card(
              color: cardColor,
              elevation: themeProvider.isDarkMode ? 4 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getStatIcon(_selectedStat),
                          color: chartColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Évolution des $statLabel',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          minY: 0,
                          maxY: maxValue * 1.2, // 20% de marge
                          gridData: FlGridData(
                            show: true,
                            drawHorizontalLine: true,
                            drawVerticalLine: false,
                            horizontalInterval: maxValue > 0 ? maxValue / 4 : 100,
                            getDrawingHorizontalLine: (value) {
                              return FlLine(
                                color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey.shade200,
                                strokeWidth: 1,
                                dashArray: [4, 4],
                              );
                            },
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final idx = value.toInt();
                                  if (idx < 0 || idx >= dates.length) {
                                    return const Text('');
                                  }
                                  
                                  if (_selectedPeriod == 'jour') {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        '${dates[idx].hour}h',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    );
                                  } else if (_selectedPeriod == 'semaine') {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        DateFormat('E', 'fr_FR').format(dates[idx]).substring(0, 2),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    );
                                  } else {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: Text(
                                        DateFormat('d', 'fr_FR').format(dates[idx]),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    value.toInt().toString(),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: subtitleColor,
                                    ),
                                  );
                                },
                                interval: maxValue > 0 ? maxValue / 4 : 100,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: List.generate(
                                values.length,
                                (i) => FlSpot(i.toDouble(), values[i]),
                              ),
                              isCurved: true,
                              color: chartColor,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    chartColor.withOpacity(themeProvider.isDarkMode ? 0.4 : 0.3),
                                    chartColor.withOpacity(themeProvider.isDarkMode ? 0.15 : 0.1),
                                  ],
                                ),
                              ),
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) {
                                  return FlDotCirclePainter(
                                    radius: 4,
                                    color: themeProvider.isDarkMode ? Colors.grey[800]! : Colors.white,
                                    strokeWidth: 2,
                                    strokeColor: chartColor,
                                  );
                                },
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchTooltipData: LineTouchTooltipData(
                              tooltipBgColor: themeProvider.isDarkMode 
                                ? Colors.black.withOpacity(0.9)
                                : Colors.black.withOpacity(0.8),
                              getTooltipItems: (touchedSpots) {
                                return touchedSpots.map((spot) {
                                  final idx = spot.x.toInt();
                                  if (idx < 0 || idx >= dates.length) return null;
                                  
                                  String dateLabel;
                                  if (_selectedPeriod == 'jour') {
                                    dateLabel = '${dates[idx].hour}h-${dates[idx].hour + 4}h';
                                  } else if (_selectedPeriod == 'semaine') {
                                    dateLabel = DateFormat('EEEE d', 'fr_FR').format(dates[idx]);
                                  } else {
                                    dateLabel = DateFormat('d MMM', 'fr_FR').format(dates[idx]);
                                  }
                                  
                                  return LineTooltipItem(
                                    '$dateLabel\n${spot.y.toStringAsFixed(1)} $unit',
                                    TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  );
                                }).toList();
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Distribution par catégorie
            Card(
              color: cardColor,
              elevation: themeProvider.isDarkMode ? 4 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: borderColor),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Distribution par catégorie',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCategoryDistribution(cp, uid, themeProvider),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String unit,
    required Color color,
    required IconData icon,
    required ThemeProvider themeProvider,
  }) {
    final cardColor = themeProvider.isDarkMode ? Colors.grey[800] : Colors.amber.shade50;
    final borderColor = themeProvider.isDarkMode ? Colors.grey[600]! : Colors.amber.shade200;
    final subtitleColor = themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey.shade700;
    
    return Card(
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode 
                      ? color.withOpacity(0.3)
                      : color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtitleColor,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryDistribution(CalorieProvider cp, String uid, ThemeProvider themeProvider) {
    final categories = {
      'fruits': {'label': '🍎 Fruits', 'color': Colors.green},
      'vegetables': {'label': '🥦 Légumes', 'color': Colors.lightGreen},
      'grains': {'label': '🌾 Céréales', 'color': Colors.amber},
      'proteins': {'label': '🍗 Protéines', 'color': Colors.red},
      'dairy': {'label': '🥛 Laitier', 'color': Colors.blue},
      'fats': {'label': '🥑 Lipides', 'color': Colors.orange},
      'sweets': {'label': '🍰 Sucreries', 'color': Colors.pink},
      'beverages': {'label': '🥤 Boissons', 'color': Colors.cyan},
      'other': {'label': '📦 Autre', 'color': Colors.grey},
    };

    // Calculer les totaux par catégorie
    Map<String, double> categoryTotals = {};
    double overallTotal = 0;

    for (final entry in cp.entries) {
      if (entry.uid == uid) {
        final category = entry.category ?? 'other';
        final value = _getStatValue(entry);
        
        categoryTotals.update(category, (v) => v + value, ifAbsent: () => value);
        overallTotal += value;
      }
    }

    if (overallTotal == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Aucune donnée disponible',
            style: TextStyle(
              color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey,
            ),
          ),
        ),
      );
    }

    // Trier par valeur décroissante
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey.shade700;
    final progressBgColor = themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey.shade200;
    
    return Column(
      children: sortedCategories.take(5).map((entry) {
        final category = entry.key;
        final value = entry.value;
        final percentage = (value / overallTotal * 100);
        final categoryInfo = categories[category] ?? categories['other']!;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: categoryInfo['color'] as Color,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  categoryInfo['label'].toString().substring(0, 2),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          categoryInfo['label'].toString().substring(2),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                        Text(
                          '${value.toStringAsFixed(1)} ${_selectedStat == 'calories' ? 'kcal' : 'g'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: progressBgColor,
                      color: categoryInfo['color'] as Color,
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  double _getStatValue(FoodEntry entry) {
    switch (_selectedStat) {
      case 'proteines':
        return entry.proteins ?? 0;
      case 'glucides':
        return entry.carbs ?? 0;
      case 'lipides':
        return entry.fats ?? 0;
      default: // calories
        return entry.calories;
    }
  }

  IconData _getStatIcon(String stat) {
    switch (stat) {
      case 'proteines':
        return Icons.fitness_center;
      case 'glucides':
        return Icons.grain;
      case 'lipides':
        return Icons.water_drop;
      default: // calories
        return Icons.local_fire_department;
    }
  }
}