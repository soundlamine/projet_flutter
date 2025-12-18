import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/auth_provider.dart';
import '../providers/calorie_provider.dart';
import '../providers/theme_provider.dart';
import '../models/food_entry.dart';
import '../services/fcm_service.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({Key? key}) : super(key: key);

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinsController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatsController = TextEditingController();
  final _fiberController = TextEditingController();
  final _sugarController = TextEditingController();
  final _servingSizeController = TextEditingController(text: '100');
  final _notesController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedMealType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _enableNotification = false;
  bool _isSaving = false;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'fruits', 'label': '🍎 Fruits', 'color': Colors.green},
    {'value': 'vegetables', 'label': '🥦 Légumes', 'color': Colors.lightGreen},
    {'value': 'grains', 'label': '🌾 Céréales', 'color': Colors.amber},
    {'value': 'proteins', 'label': '🍗 Protéines', 'color': Colors.red},
    {'value': 'dairy', 'label': '🥛 Produits laitiers', 'color': Colors.blue},
    {'value': 'fats', 'label': '🥑 Lipides', 'color': Colors.orange},
    {'value': 'sweets', 'label': '🍰 Sucreries', 'color': Colors.pink},
    {'value': 'beverages', 'label': '🥤 Boissons', 'color': Colors.cyan},
    {'value': 'other', 'label': '📦 Autre', 'color': Colors.grey},
  ];

  final List<Map<String, dynamic>> _mealTypes = [
    {'value': 'breakfast', 'label': '🌅 Petit-déjeuner', 'icon': Icons.bakery_dining},
    {'value': 'lunch', 'label': '☀️ Déjeuner', 'icon': Icons.lunch_dining},
    {'value': 'dinner', 'label': '🌙 Dîner', 'icon': Icons.dinner_dining},
    {'value': 'snack', 'label': '🍎 Collation', 'icon': Icons.cookie},
  ];

  final FCMService _fcmService = FCMService();

  @override
  void initState() {
    super.initState();
  
    _fcmService.initialize();
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    
    if (!status.isGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autorisez les notifications pour les rappels'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<String?> _scheduleNotification(
    String foodName, 
    DateTime entryDateTime, 
    String mealType
  ) async {
    if (!_enableNotification) return null;

    try {
      await _requestNotificationPermission();

      
      final notificationTime = entryDateTime;
      final now = DateTime.now();
      final timeDifference = notificationTime.difference(now);

      
      if (timeDifference.inSeconds < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('L\'heure sélectionnée est dans le passé'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      
      if (timeDifference.inSeconds < 60) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Choisissez une heure au moins 1 minute dans le futur'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return null;
      }

      
      final entryId = '${DateTime.now().millisecondsSinceEpoch}_$foodName';
      
      
      final mealTypeName = switch (mealType) {
        'breakfast' => 'Petit-déjeuner',
        'lunch' => 'Déjeuner',
        'dinner' => 'Dîner',
        'snack' => 'Collation',
        _ => 'Repas',
      };

      
      final formattedTime = DateFormat('HH:mm').format(notificationTime);

    
      await _fcmService.scheduleLocalNotification(
        title: '⏰ Rappel de $mealTypeName',
        body: 'Il est $formattedTime !\nN\'oubliez pas votre $mealTypeName: $foodName',
        scheduledDate: notificationTime,
        entryId: entryId,
      );

      return entryId;
    } catch (e) {
      print('Erreur lors de la planification de la notification: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la planification de la notification'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
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

  Future<void> _selectTime(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year && 
                    _selectedDate.month == now.month && 
                    _selectedDate.day == now.day;

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.orange,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    if (isToday) {
      final selectedDateTime = DateTime(
        now.year, now.month, now.day,
        picked.hour, picked.minute,
      );
      
      if (selectedDateTime.isBefore(now) && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une heure future'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    
    setState(() => _selectedTime = picked);
  }

  Future<void> _saveEntry() async {
    if (_isSaving) return;
    
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez corriger les erreurs dans le formulaire'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final calorieProvider = Provider.of<CalorieProvider>(context, listen: false);
    
    if (auth.firebaseUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous devez être connecté'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final entryDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final now = DateTime.now();
      final timeDifference = entryDateTime.difference(now);

      
      if (timeDifference.inSeconds < 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La date/heure sélectionnée est dans le passé'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      
      if (timeDifference.inSeconds < 60) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Choisissez une heure au moins 1 minute dans le futur'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      String? notificationId;
      if (_enableNotification && _selectedMealType != null) {
        notificationId = await _scheduleNotification(
          _nameController.text,
          entryDateTime,
          _selectedMealType!,
        );
        
      }

      final entry = FoodEntry(
        uid: auth.firebaseUser!.uid,
        name: _nameController.text,
        category: _selectedCategory,
        calories: double.parse(_caloriesController.text),
        proteins: _proteinsController.text.isNotEmpty ? double.parse(_proteinsController.text) : null,
        carbs: _carbsController.text.isNotEmpty ? double.parse(_carbsController.text) : null,
        fats: _fatsController.text.isNotEmpty ? double.parse(_fatsController.text) : null,
        fiber: _fiberController.text.isNotEmpty ? double.parse(_fiberController.text) : null,
        sugar: _sugarController.text.isNotEmpty ? double.parse(_sugarController.text) : null,
        servingSize: double.parse(_servingSizeController.text),
        servingUnit: 'g',
        mealType: _selectedMealType,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        date: entryDateTime,
        notificationEnabled: _enableNotification,
        notificationId: notificationId,
      );

      await calorieProvider.addEntry(entry);

      if (mounted) {
        final formattedTime = DateFormat('HH:mm').format(entryDateTime);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _enableNotification && notificationId != null
                ? ' Entrée ajoutée avec rappel à $formattedTime'
                : ' Entrée ajoutée avec succès'
            ),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      print('Erreur lors de l\'ajout: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'ajout de l\'entrée'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildSectionTitle(String title, ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: themeProvider.isDarkMode ? Colors.white : Colors.black87,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? suffixText,
    int maxLines = 1,
    required ThemeProvider themeProvider,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          fontSize: 16,
          color: themeProvider.isDarkMode ? Colors.white : Colors.black,
        ),
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(icon, color: Colors.orange),
          suffixText: suffixText,
          suffixStyle: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.bold,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          filled: true,
          fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        ),
        keyboardType: keyboardType,
        validator: validator,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<Map<String, dynamic>> items,
    required String label,
    required IconData icon,
    required Function(String?) onChanged,
    required ThemeProvider themeProvider,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<String>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          prefixIcon: Icon(icon, color: Colors.orange),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.orange, width: 2),
          ),
          filled: true,
          fillColor: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
        ),
        items: items.map((item) {
          return DropdownMenuItem<String>(
            value: item['value'] as String,
            child: Row(
              children: [
                if (item['icon'] != null) Icon(item['icon'] as IconData, size: 20, color: Colors.orange),
                if (item['icon'] != null) const SizedBox(width: 10),
                Text(
                  item['label'] as String,
                  style: TextStyle(
                    color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        onChanged: onChanged,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.orange),
        dropdownColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
        validator: validator,
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String title,
    required String value,
    required IconData icon,
    required Function() onTap,
    required ThemeProvider themeProvider,
    Color? valueColor,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
            border: Border.all(
              color: valueColor != null
                  ? valueColor
                  : themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: valueColor ?? Colors.orange, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: valueColor ?? (themeProvider.isDarkMode ? Colors.white : Colors.black),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationToggle(ThemeProvider themeProvider) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.white,
          border: Border.all(
            color: themeProvider.isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _enableNotification ? Icons.notifications_active : Icons.notifications_off,
              color: _enableNotification ? Colors.orange : Colors.grey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rappel de repas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: themeProvider.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    _enableNotification 
                      ? 'Notification à ${_selectedTime.format(context)}'
                      : 'Activer le rappel',
                    style: TextStyle(
                      fontSize: 12,
                      color: themeProvider.isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _enableNotification,
              onChanged: (value) {
                setState(() => _enableNotification = value);
                if (value) {
                  _requestNotificationPermission();
                }
              },
              activeColor: Colors.orange,
              activeTrackColor: Colors.orange[200],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year && 
                    _selectedDate.month == now.month && 
                    _selectedDate.day == now.day;
    final selectedDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    final isTimeInPast = selectedDateTime.isBefore(now) && isToday;
    
    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Nouvelle Entrée',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Informations de base', themeProvider),
                
                _buildInputField(
                  controller: _nameController,
                  label: "Nom de l'aliment",
                  icon: Icons.fastfood,
                  validator: (value) => value!.isEmpty ? 'Requis' : null,
                  themeProvider: themeProvider,
                ),
                
                _buildDropdown(
                  value: _selectedCategory,
                  items: _categories,
                  label: 'Catégorie',
                  icon: Icons.category,
                  onChanged: (value) => setState(() => _selectedCategory = value),
                  themeProvider: themeProvider,
                ),
                
                _buildSectionTitle('Informations nutritionnelles', themeProvider),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _caloriesController,
                        label: 'Calories',
                        icon: Icons.local_fire_department,
                        keyboardType: TextInputType.number,
                        suffixText: 'kcal',
                        validator: (value) {
                          if (value!.isEmpty) return 'Requis';
                          final calories = double.tryParse(value);
                          if (calories == null || calories <= 0) return 'Nombre positif';
                          return null;
                        },
                        themeProvider: themeProvider,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _servingSizeController,
                        label: 'Portion',
                        icon: Icons.scale,
                        keyboardType: TextInputType.number,
                        suffixText: 'g',
                        validator: (value) {
                          if (value!.isEmpty) return 'Requis';
                          final size = double.tryParse(value);
                          if (size == null || size <= 0) return 'Nombre positif';
                          return null;
                        },
                        themeProvider: themeProvider,
                      ),
                    ),
                  ],
                ),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _proteinsController,
                        label: 'Protéines',
                        icon: Icons.fitness_center,
                        keyboardType: TextInputType.number,
                        suffixText: 'g',
                        themeProvider: themeProvider,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _carbsController,
                        label: 'Glucides',
                        icon: Icons.grain,
                        keyboardType: TextInputType.number,
                        suffixText: 'g',
                        themeProvider: themeProvider,
                      ),
                    ),
                  ],
                ),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _fatsController,
                        label: 'Lipides',
                        icon: Icons.water_drop,
                        keyboardType: TextInputType.number,
                        suffixText: 'g',
                        themeProvider: themeProvider,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInputField(
                        controller: _fiberController,
                        label: 'Fibres',
                        icon: Icons.grass,
                        keyboardType: TextInputType.number,
                        suffixText: 'g',
                        themeProvider: themeProvider,
                      ),
                    ),
                  ],
                ),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _sugarController,
                        label: 'Sucres',
                        icon: Icons.cake,
                        keyboardType: TextInputType.number,
                        suffixText: 'g',
                        themeProvider: themeProvider,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Container()), 
                  ],
                ),
                
                _buildSectionTitle('Date et moment', themeProvider),
                
                Row(
                  children: [
                    _buildDateTimePicker(
                      title: 'Date',
                      value: DateFormat('dd/MM/yyyy').format(_selectedDate),
                      icon: Icons.calendar_today,
                      onTap: () => _selectDate(context),
                      themeProvider: themeProvider,
                    ),
                    const SizedBox(width: 12),
                    _buildDateTimePicker(
                      title: 'Heure',
                      value: _selectedTime.format(context),
                      icon: Icons.access_time,
                      onTap: () => _selectTime(context),
                      themeProvider: themeProvider,
                      valueColor: isTimeInPast ? Colors.red : null,
                    ),
                  ],
                ),
                
                const SizedBox(height: 8),
                
                _buildDropdown(
                  value: _selectedMealType,
                  items: _mealTypes,
                  label: 'Type de repas',
                  icon: Icons.restaurant,
                  onChanged: (value) {
                    setState(() {
                      _selectedMealType = value;
                      if (!_enableNotification && value != null) {
                        _enableNotification = true;
                        _requestNotificationPermission();
                      }
                    });
                  },
                  validator: (value) {
                    if (_enableNotification && value == null) {
                      return 'Requis pour les notifications';
                    }
                    return null;
                  },
                  themeProvider: themeProvider,
                ),
                
                if (_selectedMealType != null) 
                  _buildNotificationToggle(themeProvider),
                
                _buildSectionTitle('Notes (optionnel)', themeProvider),
                
                _buildInputField(
                  controller: _notesController,
                  label: 'Ajoutez vos notes ici...',
                  icon: Icons.note_add,
                  keyboardType: TextInputType.multiline,
                  maxLines: 3,
                  themeProvider: themeProvider,
                ),
                
                const SizedBox(height: 20),
                
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveEntry,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_circle_outline, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'AJOUTER L\'ENTRÉE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinsController.dispose();
    _carbsController.dispose();
    _fatsController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _servingSizeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}