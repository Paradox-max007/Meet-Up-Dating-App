import 'package:flutter/material.dart';

enum AppThemeMode {
  basic,
  premiumPurple,
  premiumGold,
  premiumMidnight,
}

class ThemeService extends ChangeNotifier {
  AppThemeMode _currentMode = AppThemeMode.basic;
  bool _isPremium = false;

  AppThemeMode get currentMode => _currentMode;
  bool get isPremium => _isPremium;

  void setPremium(bool value) {
    _isPremium = value;
    if (!_isPremium) {
      _currentMode = AppThemeMode.basic;
    }
    notifyListeners();
  }

  void setThemeMode(AppThemeMode mode) {
    if (!_isPremium && mode != AppThemeMode.basic) {
      // Logic for non-premium trying to use premium themes can go here
      return;
    }
    _currentMode = mode;
    notifyListeners();
  }

  ThemeData get themeData {
    switch (_currentMode) {
      case AppThemeMode.premiumPurple:
        return _buildTheme(Colors.deepPurple, Colors.purpleAccent);
      case AppThemeMode.premiumGold:
        return _buildTheme(Colors.amber, Colors.orangeAccent);
      case AppThemeMode.premiumMidnight:
        return _buildTheme(Colors.blueGrey, Colors.indigoAccent);
      case AppThemeMode.basic:
      default:
        return _buildTheme(const Color(0xFF1B5E20), const Color(0xFF00ACC1)); // Green/Blue
    }
  }

  ThemeData _buildTheme(Color primary, Color accent) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.dark,
        primary: primary,
        secondary: accent,
        surface: const Color(0xFF121212),
      ),
      scaffoldBackgroundColor: const Color(0xFF0A0A0A),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }

  LinearGradient get mainGradient {
    switch (_currentMode) {
      case AppThemeMode.premiumPurple:
        return const LinearGradient(
          colors: [Colors.deepPurple, Colors.purpleAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppThemeMode.premiumGold:
        return const LinearGradient(
          colors: [Colors.amber, Colors.orangeAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppThemeMode.premiumMidnight:
        return const LinearGradient(
          colors: [Colors.blueGrey, Colors.indigoAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case AppThemeMode.basic:
      default:
        return const LinearGradient(
          colors: [Color(0xFF1B5E20), Color(0xFF00ACC1)], // Green/Blue
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}
