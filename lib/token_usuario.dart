import 'package:shared_preferences/shared_preferences.dart';
import 'package:whatsapp_chat/models/usuario_model.dart';

class TokenUsuario {
  static final TokenUsuario _instancia = TokenUsuario._internal();

  factory TokenUsuario() {
    return _instancia;
  }

  TokenUsuario._internal();

  late SharedPreferences _prefs;

  initTokenUsuario() async {
    _prefs = await SharedPreferences.getInstance();
  }

  bool get isAdmin => _prefs.getBool('isAdmin') ?? false;
  set isAdmin(bool value) => _prefs.setBool('isAdmin', value);

  int get lastId => _prefs.getInt('lastId') ?? 0;
  set lastId(int value) => _prefs.setInt('lastId', value);

  int get lastTimestempFocused => _prefs.getInt('lastTimestempFocused') ?? 0;
  set lastTimestempFocused(int value) =>
      _prefs.setInt('lastTimestempFocused', value);

  UserSexo get sexo => _prefs.getString('sexo') == null
      ? UserSexo.masculino
      : UserSexo.values.byName(_prefs.getString('sexo')!);
  set sexo(UserSexo value) => _prefs.setString('sexo', value.name);

  String get idioma => _prefs.getString('idioma') ?? '';
  set idioma(String value) => _prefs.setString('idioma', value);
}
