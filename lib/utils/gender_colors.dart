import 'package:flutter/material.dart';

/// Utilitário para cores baseadas no gênero
class GenderColors {
  /// Retorna a cor primária baseada no gênero
  static Color getPrimaryColor(String? gender) {
    if (gender == 'Masculino') {
      return const Color(0xFF39b9ff); // Azul
    } else {
      return const Color(0xFFfc6aeb); // Rosa
    }
  }
  
  /// Retorna a cor primária com opacidade baseada no gênero
  static Color getPrimaryColorWithOpacity(String? gender, double opacity) {
    return getPrimaryColor(gender).withOpacity(opacity);
  }
  
  /// Retorna a cor de fundo baseada no gênero
  static Color getBackgroundColor(String? gender) {
    return getPrimaryColor(gender).withOpacity(0.1);
  }
  
  /// Retorna a cor de borda baseada no gênero
  static Color getBorderColor(String? gender) {
    return getPrimaryColor(gender).withOpacity(0.3);
  }
}
