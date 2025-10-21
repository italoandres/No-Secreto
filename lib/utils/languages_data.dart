/// Lista dos 10 idiomas mais falados do mundo
class LanguagesData {
  static const List<Map<String, String>> languages = [
    {'code': 'pt', 'name': 'Português', 'flag': '🇧🇷'},
    {'code': 'en', 'name': 'Inglês', 'flag': '🇬🇧'},
    {'code': 'es', 'name': 'Espanhol', 'flag': '🇪🇸'},
    {'code': 'zh', 'name': 'Chinês (Mandarim)', 'flag': '🇨🇳'},
    {'code': 'hi', 'name': 'Hindi', 'flag': '🇮🇳'},
    {'code': 'bn', 'name': 'Bengali', 'flag': '🇧🇩'},
    {'code': 'ru', 'name': 'Russo', 'flag': '🇷🇺'},
    {'code': 'ja', 'name': 'Japonês', 'flag': '🇯🇵'},
    {'code': 'de', 'name': 'Alemão', 'flag': '🇩🇪'},
    {'code': 'fr', 'name': 'Francês', 'flag': '🇫🇷'},
  ];
  
  /// Retorna a lista de nomes dos idiomas
  static List<String> getLanguageNames() {
    return languages.map((lang) => lang['name']!).toList();
  }
  
  /// Retorna o nome do idioma pelo código
  static String getLanguageName(String code) {
    final lang = languages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'name': code},
    );
    return lang['name']!;
  }
  
  /// Retorna a bandeira do idioma pelo código
  static String getLanguageFlag(String code) {
    final lang = languages.firstWhere(
      (l) => l['code'] == code,
      orElse: () => {'flag': '🌐'},
    );
    return lang['flag']!;
  }
}
