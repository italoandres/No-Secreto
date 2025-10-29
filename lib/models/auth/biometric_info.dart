import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

/// Informações sobre biometria disponível no dispositivo
class BiometricInfo {
  final bool isAvailable;
  final List<BiometricType> types;

  BiometricInfo({
    required this.isAvailable,
    required this.types,
  });

  String get displayName {
    if (!isAvailable) return 'Biometria não disponível';
    if (types.contains(BiometricType.face)) return 'Reconhecimento Facial';
    if (types.contains(BiometricType.fingerprint)) return 'Impressão Digital';
    if (types.contains(BiometricType.iris)) return 'Reconhecimento de Íris';
    if (types.contains(BiometricType.strong)) return 'Biometria Forte';
    if (types.contains(BiometricType.weak)) return 'Biometria';
    return 'Biometria';
  }

  String get description {
    if (!isAvailable) {
      return 'Configure a biometria nas configurações do dispositivo';
    }

    final List<String> typeNames = [];
    if (types.contains(BiometricType.face)) typeNames.add('reconhecimento facial');
    if (types.contains(BiometricType.fingerprint)) typeNames.add('impressão digital');
    if (types.contains(BiometricType.iris)) typeNames.add('reconhecimento de íris');

    if (typeNames.isEmpty) return 'Biometria disponível';

    return 'Disponível: ${typeNames.join(', ')}';
  }

  IconData get iconData {
    if (types.contains(BiometricType.face)) return Icons.face;
    if (types.contains(BiometricType.fingerprint)) return Icons.fingerprint;
    if (types.contains(BiometricType.iris)) return Icons.remove_red_eye;
    return Icons.security;
  }

  String get emoji {
    if (types.contains(BiometricType.face)) return '👤';
    if (types.contains(BiometricType.fingerprint)) return '👆';
    if (types.contains(BiometricType.iris)) return '👁️';
    return '🔐';
  }
}
