// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart'; 

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();
  
  String? _selectedGender;
  String? _selectedActivityLevel;
  double? _dailyCalorieGoal;

  final List<String> _genders = ['Homme', 'Femme'];
  final List<Map<String, dynamic>> _activityLevels = [
    {'value': 'sedentary', 'label': 'Sédentaire', 'factor': 1.2},
    {'value': 'light', 'label': 'Légèrement actif', 'factor': 1.375},
    {'value': 'moderate', 'label': 'Modérément actif', 'factor': 1.55},
    {'value': 'active', 'label': 'Très actif', 'factor': 1.725},
    {'value': 'very_active', 'label': 'Extrêmement actif', 'factor': 1.9},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  void _loadProfileData() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final profile = auth.profile;
    
    if (profile != null) {
      _fullNameController.text = profile.fullName ?? '';
      _ageController.text = profile.age?.toString() ?? '';
      _weightController.text = profile.weight?.toString() ?? '';
      _heightController.text = profile.height?.toString() ?? '';
      _selectedGender = profile.gender;
      _selectedActivityLevel = profile.activityLevel;
      _dailyCalorieGoal = profile.dailyCalorieGoal;
    }
  }

  void _calculateCalorieGoal() {
    final weight = double.tryParse(_weightController.text);
    final height = double.tryParse(_heightController.text);
    final age = int.tryParse(_ageController.text);
    
    if (weight == null || height == null || age == null || _selectedGender == null || _selectedActivityLevel == null) {
      return;
    }

    // Formule de Harris-Benedict
    double bmr;
    if (_selectedGender == 'Homme') {
      bmr = 88.362 + (13.397 * weight) + (4.799 * height) - (5.677 * age);
    } else {
      bmr = 447.593 + (9.247 * weight) + (3.098 * height) - (4.330 * age);
    }

    final activityFactor = _activityLevels
        .firstWhere((level) => level['value'] == _selectedActivityLevel)['factor'] as double;
    
    setState(() {
      _dailyCalorieGoal = (bmr * activityFactor).roundToDouble();
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      
      try {
        await auth.updateProfile(
          fullName: _fullNameController.text.trim(),
          age: int.tryParse(_ageController.text),
          weight: double.tryParse(_weightController.text),
          height: double.tryParse(_heightController.text),
          gender: _selectedGender,
          activityLevel: _selectedActivityLevel,
          dailyCalorieGoal: _dailyCalorieGoal,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour avec succès !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    final backgroundColor = themeProvider.isDarkMode ? Colors.grey[900] : Colors.white;
    final textColor = themeProvider.isDarkMode ? Colors.white : Colors.black;
    final subtitleColor = themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey.shade600;
    final cardColor = themeProvider.isDarkMode ? Colors.grey[800] : Colors.white;
    final inputFillColor = themeProvider.isDarkMode ? Colors.grey[700] : Colors.amber.shade50;
    final borderColor = themeProvider.isDarkMode ? Colors.grey[600]! : Colors.amber.shade200;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Mon Profil'),
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.amber[700],
        foregroundColor: themeProvider.isDarkMode ? Colors.white : Colors.black,
        elevation: themeProvider.isDarkMode ? 2 : 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfile,
            tooltip: 'Enregistrer',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informations personnelles
              Card(
                elevation: themeProvider.isDarkMode ? 4 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informations personnelles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode ? Colors.amber[400] : Colors.amber[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Nom complet
                      TextFormField(
                        controller: _fullNameController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Nom complet',
                          labelStyle: TextStyle(color: subtitleColor),
                          prefixIcon: Icon(Icons.person, color: Colors.amber),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: inputFillColor,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.amber),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez entrer votre nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      
                      // Âge
                      TextFormField(
                        controller: _ageController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Âge (années)',
                          labelStyle: TextStyle(color: subtitleColor),
                          prefixIcon: Icon(Icons.cake, color: Colors.amber),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: inputFillColor,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.amber),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre âge';
                          }
                          final age = int.tryParse(value);
                          if (age == null || age < 1 || age > 120) {
                            return 'Âge invalide';
                          }
                          return null;
                        },
                        onChanged: (_) => _calculateCalorieGoal(),
                      ),
                      const SizedBox(height: 12),
                      
                      // Genre
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Genre',
                          labelStyle: TextStyle(color: subtitleColor),
                          prefixIcon: Icon(Icons.transgender, color: Colors.amber),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: inputFillColor,
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.amber),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        dropdownColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
                        items: _genders.map((gender) {
                          return DropdownMenuItem(
                            value: gender,
                            child: Text(
                              gender,
                              style: TextStyle(color: textColor),
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                          _calculateCalorieGoal();
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Veuillez sélectionner votre genre';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Mesures corporelles
              Card(
                elevation: themeProvider.isDarkMode ? 4 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mesures corporelles',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode ? Colors.amber[400] : Colors.amber[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Poids
                      TextFormField(
                        controller: _weightController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Poids (kg)',
                          labelStyle: TextStyle(color: subtitleColor),
                          prefixIcon: Icon(Icons.monitor_weight, color: Colors.amber),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: inputFillColor,
                          suffixText: 'kg',
                          suffixStyle: TextStyle(color: subtitleColor),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.amber),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre poids';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight < 20 || weight > 300) {
                            return 'Poids invalide';
                          }
                          return null;
                        },
                        onChanged: (_) => _calculateCalorieGoal(),
                      ),
                      const SizedBox(height: 12),
                      
                      // Taille
                      TextFormField(
                        controller: _heightController,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          labelText: 'Taille (cm)',
                          labelStyle: TextStyle(color: subtitleColor),
                          prefixIcon: Icon(Icons.height, color: Colors.amber),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: inputFillColor,
                          suffixText: 'cm',
                          suffixStyle: TextStyle(color: subtitleColor),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.amber),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre taille';
                          }
                          final height = double.tryParse(value);
                          if (height == null || height < 50 || height > 250) {
                            return 'Taille invalide';
                          }
                          return null;
                        },
                        onChanged: (_) => _calculateCalorieGoal(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Niveau d'activité
              Card(
                elevation: themeProvider.isDarkMode ? 4 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Niveau d\'activité',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode ? Colors.amber[400] : Colors.amber[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Sélectionnez votre niveau d\'activité quotidien',
                        style: TextStyle(
                          fontSize: 14,
                          color: subtitleColor,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _activityLevels.map((level) {
                          final isSelected = _selectedActivityLevel == level['value'];
                          return ChoiceChip(
                            label: Text(
                              level['label'] as String,
                              style: TextStyle(
                                color: isSelected 
                                  ? (themeProvider.isDarkMode ? Colors.black : Colors.black)
                                  : (themeProvider.isDarkMode ? Colors.white : Colors.grey.shade800),
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedActivityLevel = selected ? level['value'] as String : null;
                              });
                              _calculateCalorieGoal();
                            },
                            backgroundColor: themeProvider.isDarkMode 
                              ? Colors.grey[700]
                              : Colors.amber.shade50,
                            selectedColor: themeProvider.isDarkMode
                              ? Colors.amber[400]
                              : Colors.amber[200],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected 
                                  ? (themeProvider.isDarkMode ? Colors.black : Colors.black)
                                  : (themeProvider.isDarkMode ? Colors.grey[600]! : Colors.amber.shade300),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Objectif calorique
              Card(
                elevation: themeProvider.isDarkMode ? 4 : 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: borderColor, width: 1),
                ),
                color: cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Objectif calorique quotidien',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: themeProvider.isDarkMode ? Colors.amber[400] : Colors.amber[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: themeProvider.isDarkMode ? Colors.grey[700] : Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: themeProvider.isDarkMode ? Colors.grey[600]! : Colors.amber.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            if (_dailyCalorieGoal != null)
                              Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.baseline,
                                    textBaseline: TextBaseline.alphabetic,
                                    children: [
                                      Text(
                                        '${_dailyCalorieGoal!.toStringAsFixed(0)}',
                                        style: TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'kcal/jour',
                                        style: TextStyle(
                                          fontSize: 18,
                                          color: subtitleColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Recommandé pour maintenir votre poids',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subtitleColor,
                                      fontStyle: FontStyle.italic,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              )
                            else
                              Column(
                                children: [
                                  Icon(
                                    Icons.calculate,
                                    size: 48,
                                    color: themeProvider.isDarkMode 
                                      ? Colors.amber[400] 
                                      : Colors.amber.shade400,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Remplissez vos informations\npour calculer votre objectif calorique',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: subtitleColor,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 12),
                      
                      // Bouton calcul
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _calculateCalorieGoal,
                          icon: const Icon(Icons.calculate),
                          label: const Text('Calculer mon objectif'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: themeProvider.isDarkMode 
                              ? Colors.amber[600] 
                              : Colors.amber[700],
                            foregroundColor: themeProvider.isDarkMode 
                              ? Colors.white 
                              : Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Informations utilisateur
              if (auth.firebaseUser != null)
                Card(
                  elevation: themeProvider.isDarkMode ? 4 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: themeProvider.isDarkMode ? Colors.grey[600]! : Colors.grey.shade300,
                      width: 1,
                    ),
                  ),
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Informations de compte',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: themeProvider.isDarkMode ? Colors.white : Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.email, color: Colors.amber),
                          title: Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 12,
                              color: subtitleColor,
                            ),
                          ),
                          subtitle: Text(
                            auth.firebaseUser!.email ?? 'Non défini',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ), 
                      ],
                    ),
                  ),
                ),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}