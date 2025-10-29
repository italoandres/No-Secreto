import 'auth_method.dart';

/// Configuração de autenticação do aplicativo
class AuthConfig {
  final bool isEnabled;
  final AuthMethod method;
  final int timeoutMinutes;
  final DateTime? lastAuthTime;

  AuthConfig({
    required this.isEnabled,
    required this.method,
    this.timeoutMinutes = 2,
    this.lastAuthTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'method': method.name,
      'timeoutMinutes': timeoutMinutes,
      'lastAuthTime': lastAuthTime?.millisecondsSinceEpoch,
    };
  }

  factory AuthConfig.fromJson(Map<String, dynamic> json) {
    return AuthConfig(
      isEnabled: json['isEnabled'] as bool? ?? false,
      method: AuthMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => AuthMethod.none,
      ),
      timeoutMinutes: json['timeoutMinutes'] as int? ?? 2,
      lastAuthTime: json['lastAuthTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['lastAuthTime'] as int)
          : null,
    );
  }

  AuthConfig copyWith({
    bool? isEnabled,
    AuthMethod? method,
    int? timeoutMinutes,
    DateTime? lastAuthTime,
  }) {
    return AuthConfig(
      isEnabled: isEnabled ?? this.isEnabled,
      method: method ?? this.method,
      timeoutMinutes: timeoutMinutes ?? this.timeoutMinutes,
      lastAuthTime: lastAuthTime ?? this.lastAuthTime,
    );
  }
}
