import 'package:firebase_auth/firebase_auth.dart';
import '../utils/auto_fix_on_startup.dart';

/// Serviço que inicia a correção automática
/// ESTE SERVIÇO RODA SOZINHO - VOCÊ NÃO PRECISA FAZER NADA!
class AutoFixService {
  static bool _isInitialized = false;

  /// Inicializa o serviço de correção automática
  static void initialize() {
    if (_isInitialized) return;
    _isInitialized = true;

    print('🔧 AutoFixService: Inicializando...');

    // Escutar mudanças de autenticação
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        print('👤 AutoFixService: Usuário logado, iniciando correção...');
        // Executar correção automática
        AutoFixOnStartup.runAutoFix();
      } else {
        print('👤 AutoFixService: Usuário não logado');
      }
    });

    print('✅ AutoFixService: Inicializado com sucesso!');
  }

  /// Para testes - força nova execução
  static void forceRun() {
    AutoFixOnStartup.reset();
    AutoFixOnStartup.runAutoFix();
  }
}