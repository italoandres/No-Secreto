
import 'package:flutter/material.dart';

/// Classe para definir as cores do app
class AppColors {
  // Cores principais - Rosa e Azul gradiente
  static const Color primary = Color(0xFFE91E63); // Rosa
  static const Color secondary = Color(0xFF2196F3); // Azul
  static const Color accent = Color(0xFFFF4081); // Rosa accent
  static const Color success = Color(0xFF4CAF50);
  static const Color info = Color(0xFF2196F3);
  static const Color warning = Color(0xFFffc107);
  static const Color error = Color(0xFFdc3545);
  
  // Gradiente principal
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE91E63), Color(0xFF2196F3)], // Rosa para Azul
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const Color background = Colors.white;
  static const Color surface = Colors.white;
  
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6c757d);
  static const Color textLight = Colors.white;
  
  static const Color inactive = Color(0xFF6c757d);
}

class AppTheme {

  static Map<int, Color> color = {
    50: const Color(0x22E91E63),
    100: const Color(0x33E91E63),
    200: const Color(0x44E91E63),
    300: const Color(0x55E91E63),
    400: const Color(0x66E91E63),
    500: const Color(0x77E91E63),
    600: const Color(0x88E91E63),
    700: const Color(0x99E91E63),
    800: const Color(0xaaE91E63),
    900: const Color(0xbbE91E63),
  };
  static MaterialColor materialColor = MaterialColor(0xFFE91E63, color);
  static const Color chatBalaoColor = Color(0xFF273443);
  static const LinearGradient gradient = LinearGradient(
    colors: [
      Color(0xFFE91E63), // Rosa
      Color(0xFF2196F3), // Azul
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static Color scaffoldBackgroundColor = Colors.white;
  static ThemeData theme = ThemeData(
    primarySwatch: materialColor,
    brightness: Brightness.light,
    scaffoldBackgroundColor: scaffoldBackgroundColor,
    useMaterial3: false,
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        elevation: 0
      )
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(50),
        ),
        elevation: 0
      )
    ),
    inputDecorationTheme: InputDecorationTheme(
      enabledBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(width: 1,color: AppTheme.materialColor.shade300),
      ),
      border: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(width: 1, color: AppTheme.materialColor.shade300)
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        borderSide: BorderSide(width: 1, color: AppTheme.materialColor.shade300)
      ),
      filled: true,
      fillColor: Colors.white,
    ),
    appBarTheme: AppBarTheme(
      elevation: 0,
      centerTitle: true,
      backgroundColor: scaffoldBackgroundColor,
      iconTheme: IconThemeData(
        color: materialColor
      ),
    )
  );
}