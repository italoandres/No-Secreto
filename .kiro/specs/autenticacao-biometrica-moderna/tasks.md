# Implementation Plan

- [x] 1. Configurar dependências e estrutura base



  - Adicionar dependências no pubspec.yaml (local_auth, flutter_secure_storage, crypto, bcrypt)
  - Configurar permissões no AndroidManifest.xml e Info.plist
  - Criar estrutura de pastas (services/auth, models/auth, views/auth)

  - _Requirements: 1.1, 1.2, 1.3_


- [ ] 2. Implementar SecureStorageService
  - [ ] 2.1 Criar classe SecureStorageService com flutter_secure_storage
    - Implementar métodos para salvar/recuperar configurações de segurança
    - Implementar métodos para hash e verificação de senha

    - Adicionar método para limpar todos os dados
    - _Requirements: 6.1, 6.2, 6.3, 6.4_

  - [x] 2.2 Implementar sistema de hash de senha seguro



    - Usar bcrypt para gerar hash de senha
    - Implementar verificação de senha com hash
    - Garantir que senhas nunca sejam armazenadas em texto plano

    - _Requirements: 6.3, 6.4_

- [ ] 3. Criar modelos de dados
  - [x] 3.1 Criar enum AuthMethod

    - Definir valores: none, biometric, password, biometricWithPasswordFallback
    - _Requirements: 2.3_

  - [ ] 3.2 Criar classe AuthConfig
    - Propriedades: isEnabled, method, timeoutMinutes, lastAuthTime

    - Métodos toJson e fromJson para serialização
    - _Requirements: 2.1, 2.2, 4.4_



  - [ ] 3.3 Criar classe BiometricInfo
    - Propriedades: isAvailable, types, displayName, icon
    - Método description para texto descritivo
    - Método iconData para ícone apropriado
    - _Requirements: 3.1, 3.2, 3.3_

  - [ ] 3.4 Criar classe AuthException
    - Enum AuthErrorType com todos os tipos de erro
    - Propriedades: type, message, canRetry, shouldFallback
    - _Requirements: 5.1, 5.2_

- [ ] 4. Implementar BiometricAuthService
  - [ ] 4.1 Criar estrutura base do serviço (singleton)
    - Implementar padrão singleton
    - Inicializar LocalAuthentication
    - Adicionar propriedades de estado (_isAuthenticated, _lastAuthTime)
    - _Requirements: 1.1_

  - [ ] 4.2 Implementar detecção de biometria
    - Método canCheckBiometrics() para verificar suporte
    - Método getAvailableBiometrics() para listar tipos disponíveis
    - Método isDeviceSupported() para verificar compatibilidade
    - _Requirements: 1.1, 3.1, 3.2_

  - [ ] 4.3 Implementar autenticação biométrica
    - Método authenticate() com parâmetro reason
    - Tratamento de erros específicos (não disponível, não configurado, falha)
    - Contagem de tentativas falhadas
    - _Requirements: 1.3, 5.1, 5.2_

  - [ ] 4.4 Implementar gerenciamento de configurações
    - Método enableAppLock() com opção de usar biometria
    - Método disableAppLock() para desativar proteção
    - Método isAppLockEnabled() para verificar status
    - Método getPreferredAuthMethod() para obter método configurado
    - _Requirements: 2.1, 2.2, 2.4_

  - [ ] 4.5 Implementar gerenciamento de senha
    - Método setPassword() para definir senha
    - Método verifyPassword() para verificar senha
    - Método clearPassword() para limpar senha
    - Integrar com SecureStorageService para armazenamento seguro
    - _Requirements: 2.5, 6.3, 6.4_

  - [ ] 4.6 Implementar gerenciamento de sessão
    - Método isSessionValid() para verificar se sessão está ativa
    - Método updateLastAuthTime() para atualizar timestamp
    - Método getTimeoutMinutes() para obter timeout configurado
    - Método setTimeoutMinutes() para configurar timeout
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

- [ ] 5. Criar AppLockScreen
  - [ ] 5.1 Criar estrutura base da tela
    - StatefulWidget com parâmetros: onAuthenticated, canUseBiometric, authMethod
    - Estado inicial com _showPasswordInput e _failedAttempts
    - _Requirements: 1.3, 1.4_

  - [ ] 5.2 Implementar UI de autenticação biométrica
    - Widget _buildBiometricUI() com ícone e texto apropriados
    - Botão para iniciar autenticação biométrica
    - Animação de loading durante autenticação
    - Botão "Usar Senha" para fallback manual
    - _Requirements: 1.3, 3.3, 3.4_

  - [ ] 5.3 Implementar UI de autenticação por senha
    - Widget _buildPasswordUI() com campo de senha
    - Teclado numérico para entrada de senha
    - Feedback visual de erro
    - Contador de tentativas
    - _Requirements: 1.4, 1.5_

  - [ ] 5.4 Implementar lógica de autenticação
    - Método _authenticateWithBiometric() que chama BiometricAuthService
    - Método _authenticateWithPassword() que verifica senha
    - Método _switchToPasswordFallback() após 3 falhas biométricas
    - Callback onAuthenticated quando sucesso
    - _Requirements: 1.3, 1.4, 5.1, 5.2_

  - [ ] 5.5 Implementar tratamento de erros
    - Exibir mensagens de erro apropriadas
    - Fallback automático após 3 tentativas falhadas
    - Opção de recuperação de senha
    - _Requirements: 5.1, 5.2, 5.3, 5.4_

- [ ] 6. Atualizar SecuritySettingsWidget em UsernameSettingsView
  - [ ] 6.1 Adicionar detecção de biometria disponível
    - Chamar BiometricAuthService.getAvailableBiometrics() no initState
    - Armazenar lista de biometrias disponíveis no estado
    - _Requirements: 2.1, 3.1, 3.2_

  - [ ] 6.2 Criar widget de informações de biometria
    - Método _buildBiometricInfo() que exibe tipo de biometria disponível
    - Ícones apropriados (👆 impressão digital, 👤 face, 👁️ íris)
    - Mensagem quando biometria não está configurada
    - _Requirements: 3.1, 3.2, 3.3, 3.4_

  - [ ] 6.3 Criar seletor de método de autenticação
    - Método _buildAuthMethodSelector() com radio buttons
    - Opções: "Biometria + Senha" e "Apenas Senha"
    - Desabilitar opção de biometria se não disponível
    - _Requirements: 2.2, 2.3_

  - [ ] 6.4 Criar seletor de timeout
    - Método _buildTimeoutSelector() com dropdown
    - Opções: Imediato, 1, 2, 5, 10 minutos
    - Salvar configuração no BiometricAuthService
    - _Requirements: 4.4_

  - [ ] 6.5 Atualizar UI de configuração de senha
    - Remover lógica antiga de senha do Firebase
    - Usar BiometricAuthService.setPassword()
    - Validação de senha (mínimo 4 caracteres)
    - Confirmação de senha
    - _Requirements: 2.5_

  - [ ] 6.6 Atualizar switch de ativação/desativação
    - Ao ativar: mostrar dialog de configuração
    - Ao desativar: mostrar confirmação
    - Atualizar status visual ("Protegido com [método]")
    - _Requirements: 2.1, 2.4, 3.5_

- [ ] 7. Implementar AppLifecycleObserver
  - [ ] 7.1 Criar classe AppLifecycleObserver
    - Estender WidgetsBindingObserver
    - Propriedade _backgroundTime para rastrear quando app foi para background
    - _Requirements: 4.1, 4.2, 4.3_

  - [ ] 7.2 Implementar didChangeAppLifecycleState
    - Detectar quando app vai para paused (background)
    - Detectar quando app volta para resumed (foreground)
    - Registrar timestamp ao ir para background
    - _Requirements: 4.1, 4.2_

  - [ ] 7.3 Implementar verificação de timeout
    - Método _checkIfAuthNeeded() que compara tempo em background com timeout
    - Se excedeu timeout, mostrar AppLockScreen
    - Se não excedeu, permitir acesso direto
    - _Requirements: 4.2, 4.3, 4.4_

  - [ ] 7.4 Integrar observer no app
    - Adicionar observer no main.dart ou app_wrapper.dart
    - Remover observer ao fazer dispose
    - _Requirements: 4.1, 4.2, 4.3_

- [ ] 8. Integrar autenticação no fluxo do app
  - [ ] 8.1 Adicionar verificação no app startup
    - No main.dart ou app_wrapper.dart, verificar se proteção está ativada
    - Se ativada, mostrar AppLockScreen antes de mostrar home
    - Se não ativada, ir direto para home
    - _Requirements: 1.3, 4.1_

  - [ ] 8.2 Implementar navegação após autenticação
    - Callback onAuthenticated que remove AppLockScreen e mostra home
    - Atualizar lastAuthTime no BiometricAuthService
    - _Requirements: 1.3, 4.5_

  - [ ] 8.3 Adicionar limpeza ao fazer logout
    - Chamar BiometricAuthService.clearPassword() ao fazer logout
    - Limpar sessão ativa
    - Manter configurações de proteção (não desativar automaticamente)
    - _Requirements: 6.5_

- [ ] 9. Adicionar tratamento de erros e recuperação
  - [ ] 9.1 Implementar opção de recuperação de senha
    - Botão "Esqueci minha senha" na tela de senha
    - Dialog explicando que precisa reautenticar com Firebase
    - Redirecionar para tela de login do Firebase
    - Após reautenticação, permitir redefinir senha
    - _Requirements: 5.2, 5.4_

  - [ ] 9.2 Implementar logging de tentativas falhadas
    - Registrar tentativas falhadas (sem armazenar senhas)
    - Timestamp e tipo de falha
    - Usar para auditoria de segurança
    - _Requirements: 5.3_

  - [ ] 9.3 Implementar bypass de emergência
    - Em caso de erro crítico, permitir reautenticação com Firebase
    - Limpar configurações de segurança locais
    - Solicitar reconfiguração
    - _Requirements: 5.4_

- [ ]* 10. Testes e validação
  - [ ]* 10.1 Escrever unit tests para BiometricAuthService
    - Testar detecção de biometria
    - Testar autenticação com sucesso e falha
    - Testar gerenciamento de sessão
    - Testar hash e verificação de senha
    - _Requirements: Todos_

  - [ ]* 10.2 Escrever widget tests para AppLockScreen
    - Testar renderização com biometria
    - Testar renderização com senha
    - Testar transição para fallback
    - Testar feedback de erro
    - _Requirements: 1.3, 1.4, 1.5_

  - [ ]* 10.3 Escrever integration tests
    - Testar fluxo completo de configuração
    - Testar fluxo de autenticação
    - Testar lifecycle (background/foreground)
    - _Requirements: Todos_

  - [ ]* 10.4 Testar em dispositivos reais
    - Testar em Android com impressão digital
    - Testar em Android com reconhecimento facial
    - Testar em iOS com Touch ID
    - Testar em iOS com Face ID
    - Testar em dispositivos sem biometria
    - _Requirements: 1.1, 1.2, 1.3, 3.1, 3.2_

- [ ]* 11. Documentação e refinamentos
  - [ ]* 11.1 Adicionar documentação inline no código
    - Documentar todos os métodos públicos
    - Adicionar exemplos de uso
    - Documentar tratamento de erros
    - _Requirements: Todos_

  - [ ]* 11.2 Criar guia de uso para usuários
    - Como ativar proteção
    - Como configurar biometria
    - Como recuperar senha
    - Troubleshooting comum
    - _Requirements: 2.1, 2.2, 2.3, 3.4, 5.2_

  - [ ]* 11.3 Adicionar traduções
    - Traduzir todas as strings para português, inglês e espanhol
    - Adicionar no AppLanguage
    - _Requirements: Todos_
